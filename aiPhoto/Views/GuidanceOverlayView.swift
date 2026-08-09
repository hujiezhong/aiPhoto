import SwiftUI

struct GuidanceOverlayView: View {
    let state: CameraViewModel.State
    let offset: Double
    let hint: String

    var body: some View {
        ZStack {
            switch state {
            case .idle:
                EmptyView()
            case .analyzing:
                ProgressView("分析中…")
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .padding(20)
                    .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            case .guiding(let plan), .aligned(let plan):
                GeometryReader { geo in
                    let anchor = CGPoint(
                        x: plan.anchorPoint.x * geo.size.width,
                        y: plan.anchorPoint.y * geo.size.height
                    )
                    ZStack {
                        // 引导点
                        Circle()
                            .stroke(alignmentColor, lineWidth: 3)
                            .frame(width: 60, height: 60)
                            .scaleEffect(isAligned ? 1.2 : 1.0)
                            .opacity(isAligned ? 1.0 : 0.8)
                            .position(anchor)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                       value: state)

                        // 容差圆
                        Circle()
                            .stroke(alignmentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .frame(width: anchorDiameter(plan: plan, in: geo.size),
                                   height: anchorDiameter(plan: plan, in: geo.size))
                            .position(anchor)

                        // 方向提示
                        VStack {
                            Spacer()
                            Text(directionHint(plan: plan))
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                                .padding(.bottom, 100)
                        }
                    }
                }
            case .error(let err):
                VStack(spacing: 12) {
                    Text(err.errorDescription ?? "发生错误")
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.red.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
    }

    private var alignmentColor: Color {
        switch state {
        case .aligned: return .green
        default:
            if offset < 0.1 { return .yellow }
            return .white
        }
    }

    private var isAligned: Bool {
        if case .aligned = state { return true }
        return false
    }

    private func anchorDiameter(plan: GuidancePlan, in size: CGSize) -> CGFloat {
        min(size.width, size.height) * CGFloat(plan.anchorRadius) * 4
    }

    private func directionHint(plan: GuidancePlan) -> String {
        plan.hint
    }
}