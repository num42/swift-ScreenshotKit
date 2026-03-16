public import UIKit

public extension UIApplication {
  var firstWindow: UIWindow? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first?
      .windows
      .first(where: \.isKeyWindow)
  }
}
