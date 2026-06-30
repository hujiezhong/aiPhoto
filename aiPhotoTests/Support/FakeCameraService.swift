import AVFoundation
import Combine
import UIKit
@testable import aiPhoto

final class FakeCameraService: CameraServiceProtocol {
    let frameSubject = PassthroughSubject<CVPixelBuffer, Never>()
    var previewLayer: AVCaptureVideoPreviewLayer { AVCaptureVideoPreviewLayer() }
    var framePublisher: AnyPublisher<CVPixelBuffer, Never> { frameSubject.eraseToAnyPublisher() }

    var startSessionCalled = false
    var stopSessionCalled = false
    var capturePhotoCalled = false
    var captureCurrentFrameJPEGCalled = false
    var switchCameraCalled: AVCaptureDevice.Position?
    var photoToReturn: UIImage = UIImage()
    var jpegToReturn: Data = Data()
    var errorToThrow: Error?

    func startSession() async throws {
        if let error = errorToThrow { throw error }
        startSessionCalled = true
    }

    func stopSession() {
        stopSessionCalled = true
    }

    func capturePhoto() async throws -> UIImage {
        if let error = errorToThrow { throw error }
        capturePhotoCalled = true
        return photoToReturn
    }

    func captureCurrentFrameJPEG(quality: CGFloat) async throws -> Data {
        if let error = errorToThrow { throw error }
        captureCurrentFrameJPEGCalled = true
        return jpegToReturn
    }

    func switchCamera(to position: AVCaptureDevice.Position) async throws {
        if let error = errorToThrow { throw error }
        switchCameraCalled = position
    }
}