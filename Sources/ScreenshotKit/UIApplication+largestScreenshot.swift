internal import Foundation
public import UIKit

extension UIApplication {
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
