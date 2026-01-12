import SwiftUI
import AVFoundation

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewView: View {
    let previewLayer: AVCaptureVideoPreviewLayer

    var body: some View {
        GeometryReader { geometry in
            CameraPreviewLayerView(previewLayer: previewLayer, size: geometry.size)
        }
    }
}

/// Internal UIViewRepresentable that receives explicit size
private struct CameraPreviewLayerView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    let size: CGSize

    func makeUIView(context: Context) -> UIView {
        print("🎬 DEBUG [CameraPreviewView]: makeUIView() called")
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.backgroundColor = .black
        print("🎬 DEBUG [CameraPreviewView]: UIView created with size: \(size)")

        // Set frame immediately with the size from GeometryReader
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
        print("🎬 DEBUG [CameraPreviewView]: New size from GeometryReader: \(size)")
        print("🎬 DEBUG [CameraPreviewView]: UIView bounds: \(uiView.bounds)")
        print("🎬 DEBUG [CameraPreviewView]: Current preview layer frame: \(previewLayer.frame)")

        // Update frame to match new size
        let newBounds = CGRect(origin: .zero, size: size)
        uiView.frame = newBounds
        previewLayer.frame = newBounds
        print("🎬 DEBUG [CameraPreviewView]: Preview layer frame updated to: \(previewLayer.frame)")

        // Check session status
        if let session = previewLayer.session {
            print("🎬 DEBUG [CameraPreviewView]: Session isRunning: \(session.isRunning)")
        } else {
            print("❌ DEBUG [CameraPreviewView]: NO SESSION connected!")
        }
    }
}
