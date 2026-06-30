import Foundation

struct ModelMeta: Codable, Equatable {
    let kind: ModelKind
    let timestamp: Date

    init(kind: ModelKind, timestamp: Date = Date()) {
        self.kind = kind
        self.timestamp = timestamp
    }
}