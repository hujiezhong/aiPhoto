import Foundation

struct AppSettings: Codable, Equatable {
    var selectedModel: ModelKind
    var autoCapture: Bool
    var alignmentThreshold: Double

    init(
        selectedModel: ModelKind = .openai,
        autoCapture: Bool = true,
        alignmentThreshold: Double = 0.05
    ) {
        self.selectedModel = selectedModel
        self.autoCapture = autoCapture
        self.alignmentThreshold = alignmentThreshold
    }
}

final class AppSettingsStore {
    private let defaults: UserDefaults
    private let key = "appSettings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var settings: AppSettings {
        get {
            guard let data = defaults.data(forKey: key) else {
                return AppSettings()
            }
            return (try? JSONDecoder().decode(AppSettings.self, from: data)) ?? AppSettings()
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: key)
        }
    }
}
