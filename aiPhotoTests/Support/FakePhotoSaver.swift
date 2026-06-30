import UIKit
@testable import aiPhoto

final class FakePhotoSaver: PhotoSaverProtocol {
    var savedImages: [UIImage] = []
    var errorToThrow: Error?

    func save(_ image: UIImage) async throws {
        if let error = errorToThrow { throw error }
        savedImages.append(image)
    }
}
