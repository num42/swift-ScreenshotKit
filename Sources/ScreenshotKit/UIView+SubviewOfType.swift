public import UIKit

extension UIView {
  public func subviewOfType<T>(_ type: T.Type) -> T? {
    subviews.compactMap { $0 as? T ?? $0.subviewOfType(type) }.first
  }
}
