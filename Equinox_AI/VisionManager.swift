//
//  VisionManager.swift
//  Equinox_AI
//
//  Created by Shreyas Battula on 1/17/26.
//

import Vision
import UIKit

final class VisionManager {

    func analyzeImage(_ image: UIImage) async -> String {
        let preparedImage = image.resizedForVision(maxDimension: 1024)
        guard let cgImage = preparedImage.cgImage else {
            return "The image could not be processed."
        }
        
        return await withCheckedContinuation { continuation in
            var extractedText = ""
            var classifications: [String] = []

            // Build requests locally to avoid capturing non-Sendable values across concurrent boundaries
            let textRequest = VNRecognizeTextRequest { request, _ in
                if let results = request.results as? [VNRecognizedTextObservation] {
                    extractedText = results
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: " ")
                }
            }
            textRequest.recognitionLevel = .accurate

            let classifyRequest = VNClassifyImageRequest { request, _ in
                if let results = request.results as? [VNClassificationObservation] {
                    classifications = results
                        .prefix(3)
                        .map { $0.identifier }
                }
            }

            // Create handler locally and perform synchronously in this continuation
            let handler = VNImageRequestHandler(cgImage: cgImage)

            do {
                try handler.perform([classifyRequest, textRequest])

                let description = """
                The user provided an image.
                
                Image type:
                \(classifications.isEmpty ? "Unknown" : classifications.joined(separator: ", "))
                
                Text found in the image:
                \(extractedText.isEmpty ? "No readable text detected." : extractedText)
                """

                continuation.resume(returning: description)
            } catch {
                continuation.resume(returning: "Failed to analyze image: \(error.localizedDescription)")
            }
        }
    }
}

extension UIImage {
    func resizedForVision(maxDimension: CGFloat = 1024) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? self
    }
}
