import SwiftUI
import AVFoundation

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
/// Displays the camera preview with proper frame management
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        if let layer = previewLayer {
            view.previewLayer = layer
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
        }
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update preview layer if it changed
        if let layer = previewLayer, uiView.previewLayer !== layer {
            uiView.previewLayer?.removeFromSuperlayer()
            uiView.previewLayer = layer
            layer.videoGravity = .resizeAspectFill
            uiView.layer.addSublayer(layer)
        }
        // Frame is updated automatically via layoutSubviews
    }
}

/// Custom UIView that properly manages the preview layer frame
final class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
