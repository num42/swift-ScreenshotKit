public import UIKit

extension UIView {
  /// Recursively searches the view hierarchy for the first subview of the given type.
  ///
  /// Performs a depth-first search through the receiver's subview tree.
  ///
  /// - Parameter type: The type to search for.
  /// - Returns: The first subview that can be cast to `T`, or `nil` if none is found.
  public func subviewOfType<T>(_ type: T.Type) -> T? {
    subviews.compactMap { $0 as? T ?? $0.subviewOfType(type) }.first
  }
}
