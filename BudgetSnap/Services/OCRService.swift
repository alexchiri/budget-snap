//
//  OCRService.swift
//  BudgetSnap
//
//  Service for extracting text from screenshots using Vision framework
//

import UIKit
import Vision
import CryptoKit

class OCRService {
    static let shared = OCRService()

    private init() {}

    // Extract text from a single image
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // Extract text from multiple images
    func extractText(from images: [UIImage]) async throws -> [ImageOCRResult] {
        var results: [ImageOCRResult] = []

        for (index, image) in images.enumerated() {
            do {
                let text = try await extractText(from: image)
                let hash = generateImageHash(from: image)
                results.append(ImageOCRResult(
                    imageIndex: index,
                    text: text,
                    imageHash: hash,
                    success: true,
                    error: nil
                ))
            } catch {
                results.append(ImageOCRResult(
                    imageIndex: index,
                    text: "",
                    imageHash: "",
                    success: false,
                    error: error.localizedDescription
                ))
            }
        }

        return results
    }

    // Generate unique hash for image to detect duplicates
    func generateImageHash(from image: UIImage) -> String {
        guard let imageData = image.pngData() else {
            return UUID().uuidString
        }

        let hash = SHA256.hash(data: imageData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Models

struct ImageOCRResult {
    let imageIndex: Int
    let text: String
    let imageHash: String
    let success: Bool
    let error: String?
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image format is not supported"
        case .noTextFound:
            return "No text was found in the image"
        case .processingFailed:
            return "Failed to process the image"
        }
    }
}
