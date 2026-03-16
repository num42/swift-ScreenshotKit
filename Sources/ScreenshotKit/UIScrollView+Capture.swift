public import UIKit

extension UIScrollView {
  /// Captures a full-page screenshot of the scroll view's entire content.
  ///
  /// Polls until two consecutive captures match, ensuring async rendering has
  /// settled before compositing the final image. The image is always rendered at 1× scale.
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

    try? await Task.sleep(nanoseconds: sleepDuration * 1_000_000)

    var secondScrollViewScreenshot = await snapshotScrollView()

    for _ in 0 ... maxRetries
    where
      firstScrollViewScreenshot?.pngData() != secondScrollViewScreenshot?.pngData() {
      firstScrollViewScreenshot = secondScrollViewScreenshot

      try? await Task.sleep(nanoseconds: sleepDuration * 1_000_000)

      secondScrollViewScreenshot = await snapshotScrollView()
    }

    return secondScrollViewScreenshot
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
