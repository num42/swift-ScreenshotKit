public import UIKit

extension UIApplication {
  public func stableScrollViewSnapshot() async -> UIImage? {
    guard
      let topScrollView = UIApplication.shared.topViewController?
        .view.subviewOfType(UIScrollView.self),
      topScrollView.contentSize.height > topScrollView.frame.size.height,
      let stableScrollViewScreenshot = await topScrollView.stableScrollViewSnapshot()
    else {
      return nil
    }

    return stableScrollViewScreenshot
  }

  public func stableSnapShot() async -> UIImage? {
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

    try? await Task.sleep(nanoseconds: 100_000_000)

    var secondScreenshot = UIApplication.shared.firstWindow?.snapshot(resize: true)

    for _ in [0 ... 5] where firstScreenshot?.pngData() != secondScreenshot?.pngData() {
      firstScreenshot = secondScreenshot

      try? await Task.sleep(nanoseconds: 100_000_000)

      secondScreenshot = UIApplication.shared.firstWindow?.snapshot(resize: true)
    }

    return secondScreenshot
  }
}
