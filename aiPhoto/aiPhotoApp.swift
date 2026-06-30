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
        let model = Self.makeAdapter(settings: settings, keychain: keychain)

        let cvm = CameraViewModel(
            camera: camera,
            vision: vision,
            model: model,
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
        settings: AppSettingsStore,
        keychain: KeychainStore
    ) -> VisionModelAdapter {
        let key = (try? keychain.get("apiKey")) ?? ""
        switch settings.settings.selectedModel {
        case .openai: return OpenAIAdapter(apiKey: key)
        case .claude: return ClaudeAdapter(apiKey: key)
        case .qwenVl: return QwenAdapter(apiKey: key)
        }
    }
}
