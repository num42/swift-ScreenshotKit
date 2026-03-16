public import UIKit

extension UIView {
  @MainActor
  public func snapshot(resize: Bool) -> UIImage? {
    bounds = CGRect(origin: .zero, size: frame.size)
    backgroundColor = .clear

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
