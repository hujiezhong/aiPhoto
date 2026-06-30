import Foundation

struct GuidancePlan: Codable, Equatable {
    let subjectType: SubjectType
    let anchorPoint: NormalizedPoint
    let anchorRadius: Double
    let hint: String
    let shotType: ShotType
    let modelMeta: ModelMeta

    init(
        subjectType: SubjectType,
        anchorPoint: NormalizedPoint,
        anchorRadius: Double,
        hint: String,
        shotType: ShotType,
        modelMeta: ModelMeta
    ) {
        self.subjectType = subjectType
        self.anchorPoint = anchorPoint
        self.anchorRadius = anchorRadius
        self.hint = hint
        self.shotType = shotType
        self.modelMeta = modelMeta
    }
}