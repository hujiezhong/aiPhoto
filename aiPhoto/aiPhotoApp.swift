import SwiftUI

@main
struct aiPhotoApp: App {
    @StateObject private var cameraViewModel: CameraViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init() {
        let settings = AppSettingsStore()
        let keychain = KeychainStore()
        let camera = CameraService()
        let vision = VisionService()
        let saver = PhotoSaver()

        let cvm = CameraViewModel(
            camera: camera,
            vision: vision,
            modelProvider: { kind in Self.makeAdapter(kind: kind, settings: settings, keychain: keychain) },
            saver: saver,
            settings: settings,
            keychain: keychain
        )
        let svm = SettingsViewModel(settings: settings, keychain: keychain)

        _cameraViewModel = StateObject(wrappedValue: cvm)
        _settingsViewModel = StateObject(wrappedValue: svm)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView(
                    cameraViewModel: cameraViewModel,
                    settingsViewModel: settingsViewModel
                )
            }
        }
    }

    private static func makeAdapter(
        kind: ModelKind,
        settings: AppSettingsStore,
        keychain: KeychainStore
    ) -> VisionModelAdapter {
        let key = (try? keychain.get("apiKey")) ?? ""
        switch kind {
        case .openai: return OpenAIAdapter(apiKey: key)
        case .claude: return ClaudeAdapter(apiKey: key)
        case .qwenVl: return QwenAdapter(apiKey: key)
        }
    }
}
