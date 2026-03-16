public import UIKit

public extension UIApplication {
  /// The topmost visible view controller in the app's window hierarchy.
  ///
  /// Traverses navigation stacks, tab bar selections, and modal presentations
  /// to find the currently visible view controller. Returns `nil` if there is
  /// no root view controller.
  var topViewController: UIViewController? {
    topViewController(
      base: firstWindow?.rootViewController
    )
  }

  /// Recursively traverses the view controller hierarchy to find the topmost visible controller.
  ///
  /// - Parameter base: The starting view controller for the traversal.
  /// - Returns: The topmost visible view controller, or `base` if it has no children.
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
