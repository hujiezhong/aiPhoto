import AVFoundation
import Combine
import UIKit

protocol CameraServiceProtocol: AnyObject {
    var previewLayer: AVCaptureVideoPreviewLayer { get }
    var framePublisher: AnyPublisher<CVPixelBuffer, Never> { get }
    func startSession() async throws
    func stopSession()
    func capturePhoto() async throws -> UIImage
    func captureCurrentFrameJPEG(quality: CGFloat) async throws -> Data
    func switchCamera(to position: AVCaptureDevice.Position) async throws
}

final class CameraService: NSObject, CameraServiceProtocol {
    let session = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let frameSubject = PassthroughSubject<CVPixelBuffer, Never>()
    private var currentInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position = .back

    var framePublisher: AnyPublisher<CVPixelBuffer, Never> {
        frameSubject.eraseToAnyPublisher()
    }

    override init() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init()
        previewLayer.videoGravity = .resizeAspectFill
    }

    func startSession() async throws {
        let granted = await Self.requestCameraPermission()
        guard granted else { throw AppError.cameraPermissionDenied }

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        if session.inputs.isEmpty {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input)
            else {
                session.commitConfiguration()
                throw AppError.cameraSessionFailed(underlying: "无法添加摄像头输入")
            }
            session.addInput(input)
            currentInput = input
        }

        if !session.outputs.contains(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frames"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
        }

        if !session.outputs.contains(photoOutput) {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }

        session.commitConfiguration()

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async { [session] in
                session.startRunning()
                cont.resume()
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func capturePhoto() async throws -> UIImage {
        let settings = AVCapturePhotoSettings()
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UIImage, Error>) in
            let delegate = PhotoCaptureDelegate { result in
                switch result {
                case .success(let image): cont.resume(returning: image)
                case .failure(let error): cont.resume(throwing: error)
                }
            }
            self.photoDelegates[UUID()] = delegate
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    func captureCurrentFrameJPEG(quality: CGFloat) async throws -> Data {
        let buffer = try await latestFrame()
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw AppError.cameraSessionFailed(underlying: "无法生成预览帧")
        }
        let uiImage = UIImage(cgImage: cgImage)
        guard let data = uiImage.jpegData(compressionQuality: quality) else {
            throw AppError.cameraSessionFailed(underlying: "无法编码 JPEG")
        }
        return data
    }

    func switchCamera(to position: AVCaptureDevice.Position) async throws {
        guard position != currentPosition else { return }
        session.beginConfiguration()
        if let input = currentInput {
            session.removeInput(input)
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            throw AppError.cameraSessionFailed(underlying: "无法切换摄像头")
        }
        session.addInput(input)
        currentInput = input
        currentPosition = position
        session.commitConfiguration()
    }

    // MARK: - Private

    private var photoDelegates: [UUID: PhotoCaptureDelegate] = [:]
    private var lastBuffer: CVPixelBuffer?

    private func latestFrame() async throws -> CVPixelBuffer {
        if let last = lastBuffer { return last }
        for await buffer in framePublisher.values {
            return buffer
        }
        throw AppError.cameraSessionFailed(underlying: "无可用帧")
    }

    private static func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    cont.resume(returning: granted)
                }
            }
        default: return false
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastBuffer = buffer
        frameSubject.send(buffer)
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (Result<UIImage, Error>) -> Void
    init(_ completion: @escaping (Result<UIImage, Error>) -> Void) { self.completion = completion }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(AppError.cameraSessionFailed(underlying: error.localizedDescription)))
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else {
            completion(.failure(AppError.cameraSessionFailed(underlying: "照片数据无效")))
            return
        }
        completion(.success(image))
    }
}