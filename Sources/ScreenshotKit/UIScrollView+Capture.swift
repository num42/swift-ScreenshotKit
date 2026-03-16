public import UIKit

extension UIScrollView {
  public func stableScrollViewSnapshot() async -> UIImage? {
    var firstScrollViewScreenshot = await snapshotScrollView()

    try? await Task.sleep(nanoseconds: 100_000_000)

    var secondScrollViewScreenshot = await snapshotScrollView()

    for _ in [0 ... 5]
    where
      firstScrollViewScreenshot?.pngData() != secondScrollViewScreenshot?.pngData() {
      firstScrollViewScreenshot = secondScrollViewScreenshot

      try? await Task.sleep(nanoseconds: 100_000_000)

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
      .image { [unowned self] context in
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
