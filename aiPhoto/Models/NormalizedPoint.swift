import Foundation

struct NormalizedPoint: Codable, Equatable, Hashable {
    let x: Double
    let y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    static let origin = NormalizedPoint(x: 0, y: 0)
    static let center = NormalizedPoint(x: 0.5, y: 0.5)
}
