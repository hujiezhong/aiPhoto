import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedModel: ModelKind
    @Published var autoCapture: Bool
    @Published var alignmentThreshold: Double
    @Published var apiKey: String

    private let settings: AppSettingsStore
    private let keychain: KeychainStore
    private let keychainKey = "apiKey"

    init(settings: AppSettingsStore, keychain: KeychainStore) {
        self.settings = settings
        self.keychain = keychain
        let s = settings.settings
        self.selectedModel = s.selectedModel
        self.autoCapture = s.autoCapture
        self.alignmentThreshold = s.alignmentThreshold
        self.apiKey = (try? keychain.get(keychainKey)) ?? ""
    }

    func save() {
        var s = settings.settings
        s.selectedModel = selectedModel
        s.autoCapture = autoCapture
        s.alignmentThreshold = alignmentThreshold
        settings.settings = s

        if !apiKey.isEmpty {
            try? keychain.set(apiKey, for: keychainKey)
        }
    }
}