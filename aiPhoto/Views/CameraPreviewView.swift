import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let layer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewContainer {
        let view = PreviewContainer()
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: PreviewContainer, context: Context) {
        layer.frame = uiView.bounds
    }

    final class PreviewContainer: UIView {
        override func layoutSubviews() {
            super.layoutSubviews()
            if let preview = sublayers?.first {
                preview.frame = bounds
            }
        }
    }
}