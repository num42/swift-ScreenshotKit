public import UIKit

extension UIApplication {
  /// Captures a stable full-page screenshot of the scroll view in the top view controller.
  ///
  /// Returns `nil` if the top view controller contains no `UIScrollView`, or if its
  /// content height does not exceed its visible frame (i.e. nothing to scroll).
  ///
  /// The capture polls until two consecutive frames match, ensuring async rendering
  /// has settled before returning the final image.
  ///
  /// - Parameters:
  ///   - maxRetries: Maximum number of additional capture attempts after the first
  ///     mismatch. Defaults to `5`.
  ///   - sleepDuration: Milliseconds to wait between capture attempts. Defaults to `100`.
  /// - Returns: A full-page screenshot of the scrollable content, or `nil`.
  public func stableScrollViewSnapshot(
    maxRetries: Int = 5,
    sleepDuration: UInt64 = 100
  ) async -> UIImage? {
    guard
      let topScrollView = UIApplication.shared.topViewController?
        .view.subviewOfType(UIScrollView.self),
      topScrollView.contentSize.height > topScrollView.frame.size.height,
      let stableScrollViewScreenshot = await topScrollView.stableScrollViewSnapshot(
        maxRetries: maxRetries,
        sleepDuration: sleepDuration
      )
    else {
      return nil
    }

    return stableScrollViewScreenshot
  }

  /// Captures a stable snapshot of the key window.
  ///
  /// Temporarily disables `UIView` animations and `CATransaction` actions, then polls
  /// until two consecutive window snapshots match. This ensures all rendering —
  /// including async image loads and layout passes — has settled before the final
  /// screenshot is taken.
  ///
  /// - Parameters:
  ///   - maxRetries: Maximum number of additional capture attempts after the first
  ///     mismatch. Defaults to `5`.
  ///   - sleepDuration: Milliseconds to wait between capture attempts. Defaults to `100`.
  /// - Returns: A snapshot of the key window, or `nil` if no window is available.
  public func stableSnapShot(
    maxRetries: Int = 5,
    sleepDuration: UInt64 = 100
  ) async -> UIImage? {
    let animationsWereEnabled = UIView.areAnimationsEnabled

    UIView.setAnimationsEnabled(false)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    CATransaction.commit()
    CATransaction.flush()

    defer {
      UIView.setAnimationsEnabled(animationsWereEnabled)
    }

    var firstScreenshot = UIApplication.shared.firstWindow?.snapshot(resize: true)

    try? await Task.sleep(nanoseconds: sleepDuration * 1_000_000)

    var secondScreenshot = UIApplication.shared.firstWindow?.snapshot(resize: true)

    for _ in 0 ... maxRetries where firstScreenshot?.pngData() != secondScreenshot?.pngData() {
      firstScreenshot = secondScreenshot

      try? await Task.sleep(nanoseconds: sleepDuration * 1_000_000)

      secondScreenshot = UIApplication.shared.firstWindow?.snapshot(resize: true)
    }

    return secondScreenshot
  }
}
