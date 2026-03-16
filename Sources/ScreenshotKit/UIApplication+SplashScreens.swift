internal import Foundation
public import UIKit

extension UIApplication {
  /// Splash screen images retrieved from the system's SplashBoard cache.
  ///
  /// Locates KTX files in the app's SplashBoard snapshot directory and loads
  /// them via `CIImage` to obtain the full-resolution version. Returns an empty
  /// array if the snapshot directory or bundle identifier is unavailable.
  public var splashScreens: [UIImage] {
    guard
      let tmpDir = ProcessInfo.processInfo.environment["TMPDIR"],
      let bundleID = Bundle.main.bundleIdentifier
    else { return [] }

    let snapshotsDir = tmpDir.replacing("tmp", with: "Library/SplashBoard/Snapshots")

    guard
      let contents = try? FileManager.default.contentsOfDirectory(atPath: snapshotsDir),
      let splashDir = contents.first(where: { $0.contains(bundleID) }),
      let ktxFiles = try? FileManager.default.contentsOfDirectory(
        atPath: snapshotsDir + "/" + splashDir
      )
    else { return [] }

    return ktxFiles
      .filter { $0.hasSuffix("ktx") }
      .compactMap { imageName -> UIImage? in
        let path = "file://" + snapshotsDir + "/" + splashDir + "/" + imageName
        guard
          let url = URL(string: path),
          // By loading the ktx file to a CIImage we get the full-scale version instead of a scaled down version
          let ciImage = CIImage(contentsOf: url)
        else { return nil }
        return UIImage(ciImage: ciImage)
      }
  }
}
