public import UIKit

public extension UIApplication {
  var topViewController: UIViewController? {
    topViewController(
      base: firstWindow?.rootViewController
    )
  }

  func topViewController(base: UIViewController?) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }

    if let tab = base as? UITabBarController,
       let selected = tab.selectedViewController {
        return topViewController(base: selected)
    }

    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }

    return base
  }
}
