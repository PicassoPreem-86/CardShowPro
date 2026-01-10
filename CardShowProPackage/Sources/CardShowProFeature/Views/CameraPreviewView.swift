import SwiftUI
import AVFoundation

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> UIView {
        print("🎬 DEBUG [CameraPreviewView]: makeUIView() called")
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        print("🎬 DEBUG [CameraPreviewView]: UIView created with frame: \(view.frame)")

        // Set initial frame IMMEDIATELY before adding sublayer
        previewLayer.frame = view.bounds
        print("🎬 DEBUG [CameraPreviewView]: Preview layer frame set to: \(previewLayer.frame)")

        view.layer.addSublayer(previewLayer)
        print("🎬 DEBUG [CameraPreviewView]: Preview layer added as sublayer")

        previewLayer.videoGravity = .resizeAspectFill
        print("🎬 DEBUG [CameraPreviewView]: Video gravity set to: \(previewLayer.videoGravity)")

        // Check if session is connected
        if let session = previewLayer.session {
            print("🎬 DEBUG [CameraPreviewView]: Session exists, isRunning: \(session.isRunning)")
        } else {
            print("❌ DEBUG [CameraPreviewView]: NO SESSION connected to preview layer!")
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("🎬 DEBUG [CameraPreviewView]: updateUIView() called")
        print("🎬 DEBUG [CameraPreviewView]: UIView bounds: \(uiView.bounds)")
        print("🎬 DEBUG [CameraPreviewView]: Current preview layer frame: \(previewLayer.frame)")

        // Update frame SYNCHRONOUSLY - no async dispatch
        // We're already on MainActor, no need for async
        previewLayer.frame = uiView.bounds
        print("🎬 DEBUG [CameraPreviewView]: Preview layer frame updated to: \(previewLayer.frame)")

        // Check session status
        if let session = previewLayer.session {
            print("🎬 DEBUG [CameraPreviewView]: Session isRunning: \(session.isRunning)")
        } else {
            print("❌ DEBUG [CameraPreviewView]: NO SESSION connected!")
        }
    }
}
