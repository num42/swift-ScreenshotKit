internal import Foundation
public import UIKit

extension UIApplication {
  /// Captures the largest possible screenshot of the current UI.
  ///
  /// If the top view controller contains a `UIScrollView`, this method captures
  /// the full scrollable content using ``UIScrollView/stableScrollViewSnapshot()``.
  /// Otherwise it falls back to a snapshot of the key window.
  ///
  /// - Parameter resize: When `true`, the snapshot is rendered at 1× scale
  ///   (device-independent pixels). When `false`, the device's native screen
  ///   scale is used.
  /// - Returns: A screenshot image, or `nil` if no window or view is available.
  @available(iOS 16.0, *)
  @MainActor
  @discardableResult
  public func largestScreenshot(resize: Bool) async -> UIImage? {
    if let topScrollView = topViewController?.view.subviewOfType(UIScrollView.self),
      let scrollViewImage = await topScrollView.stableScrollViewSnapshot() {
      return scrollViewImage
    } else {
      return firstWindow?.snapshot(resize: resize)
    }
  }
}
