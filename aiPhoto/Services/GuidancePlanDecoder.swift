import Foundation

enum GuidancePlanDecoder {
    static func decode(_ raw: String, modelMeta: ModelMeta) throws -> GuidancePlan {
        let cleaned = stripCodeFence(raw)
        guard let data = cleaned.data(using: .utf8) else {
            throw AppError.modelResponseInvalid
        }

        let raw: RawGuidancePlan
        do {
            raw = try JSONDecoder().decode(RawGuidancePlan.self, from: data)
        } catch {
            throw AppError.modelResponseInvalid
        }

        guard raw.anchorPoint.x >= 0, raw.anchorPoint.x <= 1,
              raw.anchorPoint.y >= 0, raw.anchorPoint.y <= 1,
              raw.anchorRadius >= 0, raw.anchorRadius <= 1
        else {
            throw AppError.modelResponseInvalid
        }

        return GuidancePlan(
            subjectType: raw.subjectType,
            anchorPoint: NormalizedPoint(x: raw.anchorPoint.x, y: raw.anchorPoint.y),
            anchorRadius: raw.anchorRadius,
            hint: raw.hint,
            shotType: raw.shotType,
            modelMeta: modelMeta
        )
    }

    private static func stripCodeFence(_ s: String) -> String {
        var result = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            if let firstNewline = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: firstNewline)...])
            }
            if result.hasSuffix("```") {
                result = String(result.dropLast(3))
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct RawGuidancePlan: Decodable {
        let subjectType: SubjectType
        let anchorPoint: RawPoint
        let anchorRadius: Double
        let hint: String
        let shotType: ShotType

        struct RawPoint: Decodable {
            let x: Double
            let y: Double
        }
    }
}