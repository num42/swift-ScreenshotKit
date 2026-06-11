public import UIKit
internal import CryptoKit

extension UIScrollView {
  /// Captures a full-page screenshot of the scroll view's entire content.
  ///
  /// Polls until two consecutive captures match, ensuring async rendering has
  /// settled before compositing the final image. The image is always rendered at 1× scale.
  ///
  /// Stability is compared by MD5 of the raw pixel buffer rather than by
  /// `pngData()`. Encoding a multi-megapixel bitmap to PNG costs seconds
  /// and allocates a transient blob the same order of magnitude as the
  /// source image; hashing the raw buffer is sub-second and allocates
  /// nothing past the 16-byte digest. MD5 is fine here — this is a
  /// "did anything change" equality check, not a security primitive, and
  /// a collision would only return a "stable" frame one iteration early.
  ///
  /// Captured `UIImage`s are also released as soon as their digest is
  /// taken, so the ~150 MB raw bitmap never spans a `Task.sleep`
  /// suspension point — peak memory stays at one frame, not two.
  ///
  /// - Parameters:
  ///   - maxRetries: Maximum number of additional capture attempts after the first
  ///     mismatch. Defaults to `5`.
  ///   - sleepDuration: Milliseconds to wait between capture attempts. Defaults to `100`.
  /// - Returns: A full-page image of the scroll view content, or `nil` on failure.
  public func stableScrollViewSnapshot(
    maxRetries: Int = 5,
    sleepDuration: UInt64 = 100
  ) async -> UIImage? {
    var firstScrollViewScreenshot = await snapshotScrollView()
    let firstDigest = pixelDigest(of: firstScrollViewScreenshot)
    // We only need the digest from here on. Drop the 150 MB bitmap
    // before suspending so it doesn't span the sleep.
    firstScrollViewScreenshot = nil

    try? await Task.sleep(nanoseconds: sleepDuration * 1_000_000)

    var secondScrollViewScreenshot = await snapshotScrollView()
    var secondDigest = pixelDigest(of: secondScrollViewScreenshot)
    var previousDigest = firstDigest

    var retries = 0
    while secondDigest != previousDigest, retries <= maxRetries {
      previousDigest = secondDigest
      // Same trick: drop the previous candidate before suspending.
      // The candidate we eventually return is the one captured *after*
      // the loop stops mutating `secondScrollViewScreenshot`.
      secondScrollViewScreenshot = nil

      try? await Task.sleep(nanoseconds: sleepDuration * 1_000_000)

      secondScrollViewScreenshot = await snapshotScrollView()
      secondDigest = pixelDigest(of: secondScrollViewScreenshot)
      retries += 1
    }

    return secondScrollViewScreenshot
  }

  /// MD5 over the cgImage's raw pixel buffer. `nil` when the image
  /// has no decodable backing buffer (e.g. metal-backed); callers
  /// treat `nil` as a non-match so the polling keeps trying.
  private func pixelDigest(of image: UIImage?) -> Data? {
    guard let cgImage = image?.cgImage,
          let cfData = cgImage.dataProvider?.data
    else { return nil }
    return Data(Insecure.MD5.hash(data: cfData as Data))
  }

  private func snapshotScrollView() async -> UIImage? {
    await MainActor.run {
      let originalInsetsLayoutMarginsFromSafeArea = insetsLayoutMarginsFromSafeArea
      let originalContentInset = contentInset
      let originalContentOffset = contentOffset
      let viewportSize = bounds.size

      defer {
        insetsLayoutMarginsFromSafeArea = originalInsetsLayoutMarginsFromSafeArea
        contentInset = originalContentInset
        contentOffset = originalContentOffset
      }

      insetsLayoutMarginsFromSafeArea = false
      contentInset = .zero
      layoutIfNeeded()

      let captureSize = CGSize(
        width: max(contentSize.width, viewportSize.width),
        height: max(contentSize.height, viewportSize.height)
      )

      guard captureSize.width > 0, captureSize.height > 0 else {
        return nil
      }

      let format = UIGraphicsImageRendererFormat()

      // Always resize ScrollViewSnapshots
      format.scale = 1.0

      return UIGraphicsImageRenderer(
        size: captureSize,
        format: format
      )
      .image { [weak self] context in
        guard let self else { return }
        let visibleHeight = max(viewportSize.height, 1)
        let maxOffsetY = max(contentSize.height - visibleHeight, 0)
        var offsetY: CGFloat = 0

        while true {
          contentOffset = CGPoint(x: 0, y: offsetY)
          layoutIfNeeded()

          context.cgContext.saveGState()
          context.cgContext.translateBy(x: 0, y: offsetY)
          drawHierarchy(in: CGRect(origin: .zero, size: viewportSize), afterScreenUpdates: true)
          context.cgContext.restoreGState()

          if offsetY >= maxOffsetY {
            break
          }

          offsetY = min(offsetY + visibleHeight, maxOffsetY)
        }
      }
    }
  }
}
