import AVFoundation
@testable import aiPhoto

final class FakeVisionService: VisionServiceProtocol {
    var subjectsToReturn: [DetectedSubject] = []
    var detectCallCount = 0

    func detectSubject(in pixelBuffer: CVPixelBuffer) async -> [DetectedSubject] {
        detectCallCount += 1
        return subjectsToReturn
    }
}
