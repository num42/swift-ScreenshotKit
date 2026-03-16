internal import Foundation
public import UIKit

extension UIApplication {
  public var splashScreens: [UIImage] {
    let snapshotsDir = ProcessInfo.processInfo.environment["TMPDIR"]!
      .replacing("tmp", with: "Library/SplashBoard/Snapshots")

    let splashDir = (try! FileManager.default.contentsOfDirectory(atPath: snapshotsDir))
      .first { $0.contains(Bundle.main.bundleIdentifier!) }!

    return try! FileManager.default.contentsOfDirectory(atPath: snapshotsDir + "/" + splashDir)
      .filter { $0.hasSuffix("ktx") }
      .map { imageName in
        let path = "file://" + snapshotsDir + "/" + splashDir + "/" + imageName

        // By loading the ktx file to a CI Image we get the full-scale version instead of a scaled down version
        let ciImage = CIImage(contentsOf: URL(string: path)!)!

        return UIImage(ciImage: ciImage)
      }
  }
}
