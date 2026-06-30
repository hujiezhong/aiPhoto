import UIKit
import Photos

protocol PhotoSaverProtocol {
    func save(_ image: UIImage) async throws
}

final class PhotoSaver: PhotoSaverProtocol {
    func save(_ image: UIImage) async throws {
        let status = await withCheckedContinuation { (cont: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { cont.resume(returning: $0) }
        }
        guard status == .authorized || status == .limited else {
            throw AppError.photoLibraryPermissionDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw AppError.photoSaveFailed(underlying: error.localizedDescription)
        }
    }
}
