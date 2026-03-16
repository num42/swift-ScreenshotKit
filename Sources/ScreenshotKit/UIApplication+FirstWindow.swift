public import UIKit

public extension UIApplication {
  /// The key window of the first connected window scene.
  ///
  /// Returns `nil` if no window scene is connected or no key window exists.
  var firstWindow: UIWindow? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first?
      .windows
      .first(where: \.isKeyWindow)
  }
}
