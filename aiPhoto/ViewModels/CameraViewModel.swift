import Foundation
import AVFoundation
import UIKit
import Combine

@MainActor
final class CameraViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case analyzing
        case guiding(plan: GuidancePlan)
        case aligned
        case error(AppError)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var currentOffset: Double = 1.0
    @Published private(set) var hint: String = ""

    var previewLayer: AVCaptureVideoPreviewLayer { camera.previewLayer }

    private let camera: CameraServiceProtocol
    private let vision: VisionServiceProtocol
    private let model: VisionModelAdapter
    private let saver: PhotoSaverProtocol
    private let settings: AppSettingsStore
    private let keychain: KeychainStore
    private var subscriptions: Set<AnyCancellable> = []
    private var lastSeenSubject: DetectedSubject?
    private var noSubjectTimer: Task<Void, Never>?

    init(
        camera: CameraServiceProtocol,
        vision: VisionServiceProtocol,
        model: VisionModelAdapter,
        saver: PhotoSaverProtocol,
        settings: AppSettingsStore,
        keychain: KeychainStore
    ) {
        self.camera = camera
        self.vision = vision
        self.model = model
        self.saver = saver
        self.settings = settings
        self.keychain = keychain

        // 实时帧 → 主体检测 → 偏移更新
        camera.framePublisher
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] buffer in
                self?.processFrame(buffer)
            }
            .store(in: &subscriptions)
    }

    // MARK: - Public

    func onAnalyzeTap() {
        guard case .idle = state else { return }
        state = .analyzing
        Task { [weak self] in
            await self?.performAnalysis()
        }
    }

    func onCancelTap() {
        noSubjectTimer?.cancel()
        state = .idle
        currentOffset = 1.0
        hint = ""
    }

    func onShutterTap() {
        guard case .aligned = state else { return }
        Task { [weak self] in await self?.captureAndSave() }
    }

    /// 由 SwiftUI 在帧回调中调用
    func onAlignCheck(offset: Double?, hasSubject: Bool, subject: DetectedSubject?) {
        guard case .guiding(let plan) = state else { return }

        if !hasSubject {
            currentOffset = 1.0
            startNoSubjectTimer()
            return
        }
        noSubjectTimer?.cancel()
        noSubjectTimer = nil

        guard let offset = offset else { return }
        lastSeenSubject = subject
        currentOffset = offset
        hint = plan.hint

        if offset < settings.settings.alignmentThreshold {
            if settings.settings.autoCapture {
                Task { [weak self] in await self?.captureAndSave() }
            } else {
                state = .aligned
            }
        }
    }

    // MARK: - Private

    private func processFrame(_ buffer: CVPixelBuffer) {
        Task { [weak self] in
            guard let self = self else { return }
            let subjects = await self.vision.detectSubject(in: buffer)
            guard case .guiding(let plan) = self.state else { return }
            let offset = AlignmentCalculator.offset(subjects: subjects, anchor: plan.anchorPoint)
            self.onAlignCheck(offset: offset, hasSubject: !subjects.isEmpty, subject: subjects.first)
        }
    }

    private func performAnalysis() async {
        do {
            let jpeg = try await camera.captureCurrentFrameJPEG(quality: 0.7)
            let plan = try await model.analyze(imageJPEG: jpeg, model: settings.settings.selectedModel)
            state = .guiding(plan: plan)
            hint = plan.hint
        } catch let error as AppError {
            state = .error(error)
        } catch {
            state = .error(.cameraSessionFailed(underlying: error.localizedDescription))
        }
    }

    private func captureAndSave() async {
        do {
            let photo = try await camera.capturePhoto()
            try await saver.save(photo)
            resetToIdle()
        } catch let error as AppError {
            state = .error(error)
        } catch {
            state = .error(.photoSaveFailed(underlying: error.localizedDescription))
        }
    }

    private func resetToIdle() {
        noSubjectTimer?.cancel()
        noSubjectTimer = nil
        currentOffset = 1.0
        hint = ""
        lastSeenSubject = nil
        state = .idle
    }

    private func startNoSubjectTimer() {
        guard noSubjectTimer == nil else { return }
        noSubjectTimer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                self?.state = .error(.noSubjectDetected)
            }
        }
    }
}
