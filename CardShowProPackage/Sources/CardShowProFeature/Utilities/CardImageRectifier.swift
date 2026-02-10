import Foundation
import UIKit
import Vision

/// Detection result for a card quadrilateral in an image
struct CardQuadrilateral: Sendable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
}

/// Detects card quadrilaterals in images using Vision framework
final class CardQuadrilateralDetector: Sendable {
    init() {}

    /// Process an image to detect a card quadrilateral
    func processImage(_ image: UIImage) async -> CardQuadrilateral? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, _ in
                guard let results = request.results as? [VNRectangleObservation],
                      let rect = results.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let quad = CardQuadrilateral(
                    topLeft: rect.topLeft,
                    topRight: rect.topRight,
                    bottomLeft: rect.bottomLeft,
                    bottomRight: rect.bottomRight
                )
                continuation.resume(returning: quad)
            }

            request.minimumAspectRatio = 0.5
            request.maximumAspectRatio = 0.8
            request.minimumConfidence = 0.6

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}

/// Rectifies a detected card to a flat perspective
@MainActor
@Observable
final class CardImageRectifier {
    static let shared = CardImageRectifier()

    private init() {}

    /// Rectify a card image using the detected quadrilateral
    func rectifyCard(from image: UIImage, quadrilateral: CardQuadrilateral) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let filter = CIFilter(name: "CIPerspectiveCorrection")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgPoint: quadrilateral.topLeft), forKey: "inputTopLeft")
        filter?.setValue(CIVector(cgPoint: quadrilateral.topRight), forKey: "inputTopRight")
        filter?.setValue(CIVector(cgPoint: quadrilateral.bottomLeft), forKey: "inputBottomLeft")
        filter?.setValue(CIVector(cgPoint: quadrilateral.bottomRight), forKey: "inputBottomRight")

        guard let output = filter?.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
