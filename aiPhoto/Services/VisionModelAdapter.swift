import Foundation

protocol VisionModelAdapter {
    var kind: ModelKind { get }
    func analyze(imageJPEG: Data, model: ModelKind) async throws -> GuidancePlan
}
