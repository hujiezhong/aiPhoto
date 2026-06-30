@testable import aiPhoto

final class FakeVisionModelAdapter: VisionModelAdapter {
    let kind: ModelKind
    var planToReturn: GuidancePlan?
    var errorToThrow: Error?
    var analyzeCallCount = 0
    var lastJPEG: Data?

    init(kind: ModelKind = .openai) { self.kind = kind }

    func analyze(imageJPEG: Data, model: ModelKind) async throws -> GuidancePlan {
        analyzeCallCount += 1
        lastJPEG = imageJPEG
        if let error = errorToThrow { throw error }
        guard let plan = planToReturn else {
            throw AppError.modelResponseInvalid
        }
        return plan
    }
}
