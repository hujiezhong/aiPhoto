import Foundation
import CoreGraphics

struct DetectedSubject: Equatable {
    let boundingBox: CGRect          // Vision坐标系（0~1, 原点在左下）
    let confidence: Float
    let type: SubjectType

    /// 屏幕坐标系下的中心（Vision y 翻转）
    var screenCenter: NormalizedPoint {
        let cx = boundingBox.midX
        let cy = 1.0 - boundingBox.midY   // 翻转
        return NormalizedPoint(x: cx, y: cy)
    }
}

enum AlignmentCalculator {
    /// 返回主体中心与锚点的归一化欧氏距离。
    /// nil 表示画面中无主体。
    static func offset(
        subjects: [DetectedSubject],
        anchor: NormalizedPoint
    ) -> Double? {
        guard !subjects.isEmpty else { return nil }
        let subject = subjects.min(by: { lhs, rhs in
            distance(lhs.screenCenter, anchor) < distance(rhs.screenCenter, anchor)
        })!
        return distance(subject.screenCenter, anchor)
    }

    private static func distance(_ a: NormalizedPoint, _ b: NormalizedPoint) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}