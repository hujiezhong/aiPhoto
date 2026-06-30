import AVFoundation
import Vision
import CoreImage

protocol VisionServiceProtocol {
    func detectSubject(in pixelBuffer: CVPixelBuffer) async -> [DetectedSubject]
}

final class VisionService: VisionServiceProtocol {
    func detectSubject(in pixelBuffer: CVPixelBuffer) async -> [DetectedSubject] {
        async let faces = runFaceDetection(pixelBuffer)
        async let humans = runHumanDetection(pixelBuffer)
        let (faceResults, humanResults) = await (faces, humans)

        var subjects: [DetectedSubject] = []
        subjects.append(contentsOf: faceResults.map {
            DetectedSubject(boundingBox: $0.boundingBox, confidence: $0.confidence, type: .person)
        })
        if subjects.isEmpty {
            subjects.append(contentsOf: humanResults.map {
                DetectedSubject(boundingBox: $0.boundingBox, confidence: $0.confidence, type: .person)
            })
        }
        return subjects
    }

    private func runFaceDetection(_ buffer: CVPixelBuffer) async -> [VNDetection] {
        await withCheckedContinuation { (cont: CheckedContinuation<[VNDetection], Never>) in
            let request = VNDetectFaceRectanglesRequest { request, _ in
                let observations = (request.results as? [VNFaceObservation]) ?? []
                cont.resume(returning: observations.map {
                    VNDetection(boundingBox: $0.boundingBox, confidence: $0.confidence)
                })
            }
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                cont.resume(returning: [])
            }
        }
    }

    private func runHumanDetection(_ buffer: CVPixelBuffer) async -> [VNDetection] {
        await withCheckedContinuation { (cont: CheckedContinuation<[VNDetection], Never>) in
            let request = VNDetectHumanRectanglesRequest { request, _ in
                let observations = (request.results as? [VNHumanObservation]) ?? []
                cont.resume(returning: observations.map {
                    VNDetection(boundingBox: $0.boundingBox, confidence: $0.confidence)
                })
            }
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                cont.resume(returning: [])
            }
        }
    }

    private struct VNDetection {
        let boundingBox: CGRect
        let confidence: Float
    }
}
