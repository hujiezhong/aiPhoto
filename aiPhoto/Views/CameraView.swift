import SwiftUI

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    let previewLayer: AVCaptureVideoPreviewLayer

    var body: some View {
        ZStack {
            CameraPreviewView(layer: previewLayer)
                .ignoresSafeArea()

            GuidanceOverlayView(
                state: viewModel.state,
                offset: viewModel.currentOffset,
                hint: viewModel.hint
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                HStack(spacing: 24) {
                    // 分析按钮
                    Button {
                        viewModel.onAnalyzeTap()
                    } label: {
                        Label("分析", systemImage: "wand.and.stars")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.blue, in: Capsule())
                    }
                    .disabled(!isAnalyzeEnabled)

                    // 取消按钮
                    if case .guiding = viewModel.state {
                        Button {
                            viewModel.onCancelTap()
                        } label: {
                            Text("取消")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.gray, in: Capsule())
                        }
                    }

                    // 快门
                    Button {
                        if case .aligned = viewModel.state {
                            viewModel.onShutterTap()
                        } else {
                            viewModel.onAnalyzeTap()
                        }
                    } label: {
                        Image(systemName: shutterIcon)
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(Circle().stroke(.white, lineWidth: 4))
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }

    private var isAnalyzeEnabled: Bool {
        if case .idle = viewModel.state { return true }
        return false
    }

    private var shutterIcon: String {
        switch viewModel.state {
        case .aligned: return "camera.fill"
        default: return "wand.and.stars"
        }
    }
}