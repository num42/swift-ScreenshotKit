public import UIKit

extension UIView {
  /// Captures a snapshot of this view and its subview hierarchy.
  ///
  /// - Parameter resize: When `true`, the image is rendered at 1× scale
  ///   (device-independent pixels). When `false`, the device's native screen
  ///   scale is used.
  /// - Returns: A snapshot image, or `nil` if the view has zero size.
  @MainActor
  public func snapshot(resize: Bool) -> UIImage? {
    bounds = CGRect(origin: .zero, size: frame.size)
    let originalBackgroundColor = backgroundColor
    backgroundColor = .clear
    defer { backgroundColor = originalBackgroundColor }

    let format = UIGraphicsImageRendererFormat()

    if resize {
      format.scale = 1.0
    }

    return UIGraphicsImageRenderer(
      size: frame.size,
      format: format
    )
    .image { [unowned self] _ in
      self.drawHierarchy(
        in: self.bounds,
        afterScreenUpdates: true
      )
    }
  }
}
