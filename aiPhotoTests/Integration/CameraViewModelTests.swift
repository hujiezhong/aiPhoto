import XCTest
import AVFoundation
@testable import aiPhoto

@MainActor
final class CameraViewModelTests: XCTestCase {
    var vm: CameraViewModel!
    var camera: FakeCameraService!
    var vision: FakeVisionService!
    var model: FakeVisionModelAdapter!
    var saver: FakePhotoSaver!
    var settings: AppSettingsStore!

    let fixedPlan = GuidancePlan(
        subjectType: .person,
        anchorPoint: .center,
        anchorRadius: 0.1,
        hint: "test",
        shotType: .portrait,
        modelMeta: ModelMeta(kind: .openai)
    )

    override func setUp() {
        super.setUp()
        camera = FakeCameraService()
        vision = FakeVisionService()
        model = FakeVisionModelAdapter(kind: .openai)
        saver = FakePhotoSaver()
        settings = AppSettingsStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    }

    func makeVM() -> CameraViewModel {
        CameraViewModel(
            camera: camera,
            vision: vision,
            model: model,
            saver: saver,
            settings: settings,
            keychain: KeychainStore(service: "test-\(UUID().uuidString)")
        )
    }

    func test_initialState_isIdle() {
        vm = makeVM()
        if case .idle = vm.state { } else { XCTFail("期望 idle，实际 \(vm.state)") }
    }

    func test_onAnalyzeTap_success_transitionsToGuiding() async {
        model.planToReturn = fixedPlan
        camera.jpegToReturn = Data([1, 2, 3])
        vm = makeVM()

        vm.onAnalyzeTap()
        // analyzing 短暂，可直接等待
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .guiding(let plan) = vm.state {
            XCTAssertEqual(plan.hint, "test")
        } else {
            XCTFail("期望 guiding，实际 \(vm.state)")
        }
    }

    func test_onAnalyzeTap_modelError_transitionsToError() async {
        model.errorToThrow = AppError.modelAuthFailed
        camera.jpegToReturn = Data([1, 2, 3])
        vm = makeVM()

        vm.onAnalyzeTap()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .error(let err) = vm.state {
            XCTAssertEqual(err, .modelAuthFailed)
        } else {
            XCTFail("期望 error，实际 \(vm.state)")
        }
    }

    func test_onCancelTap_guidesToIdle() async {
        model.planToReturn = fixedPlan
        camera.jpegToReturn = Data([1])
        vm = makeVM()
        vm.onAnalyzeTap()
        try? await Task.sleep(nanoseconds: 100_000_000)

        vm.onCancelTap()
        if case .idle = vm.state { } else { XCTFail("期望 idle，实际 \(vm.state)") }
    }

    func test_aligned_autoCaptureTrue_savesAndResets() async {
        model.planToReturn = fixedPlan
        camera.jpegToReturn = Data([1])
        camera.photoToReturn = UIImage()
        settings.settings.autoCapture = true
        vm = makeVM()

        // 先进入 guiding 状态
        vm.onAnalyzeTap()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // 驱动对齐检测
        vm.onAlignCheck(
            offset: 0.01,
            hasSubject: true,
            subject: DetectedSubject(
                boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
                confidence: 0.9,
                type: .person
            )
        )
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(saver.savedImages.count, 1)
        if case .idle = vm.state { } else { XCTFail("期望 idle，实际 \(vm.state)") }
    }

    func test_aligned_autoCaptureFalse_waitsForShutter() async {
        model.planToReturn = fixedPlan
        camera.jpegToReturn = Data([1])
        camera.photoToReturn = UIImage()
        settings.settings.autoCapture = false
        vm = makeVM()

        // 先进入 guiding 状态
        vm.onAnalyzeTap()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // 驱动对齐检测 — offset<阈值 + autoCapture=false → 进入 aligned
        vm.onAlignCheck(
            offset: 0.01,
            hasSubject: true,
            subject: nil
        )
        try? await Task.sleep(nanoseconds: 50_000_000)

        if case .aligned = vm.state { } else { XCTFail("期望 aligned，实际 \(vm.state)") }

        vm.onShutterTap()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(saver.savedImages.count, 1)
    }
}
