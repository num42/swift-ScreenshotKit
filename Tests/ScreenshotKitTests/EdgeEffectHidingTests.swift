import ScreenshotKit
import Testing
import UIKit

@MainActor
struct EdgeEffectHidingTests {
  @Test
  @available(iOS 26.0, *)
  func everyPageIsDrawnWithHiddenEdgeEffects() async throws {
    let scrollView = RecordingScrollView(contentHeight: 1000)
    scrollView.showsEdgeEffectsOnLayout = true

    _ = await scrollView.stableScrollViewSnapshot(sleepDuration: 0)

    #expect(scrollView.layoutsThatShowedEdgeEffects > 0)
    #expect(scrollView.draws.allSatisfy { $0.topHidden && $0.bottomHidden })
    // Two captures (the stability check) of the pages at 0, 400 and the last page at 600.
    #expect(scrollView.draws.map(\.offsetY) == [0, 400, 600, 0, 400, 600])
  }

  @Test
  @available(iOS 26.0, *)
  func pageIsDrawnAgainWhenTheScreenUpdateShowsTheEdgeEffects() async throws {
    let scrollView = RecordingScrollView(contentHeight: 400)
    scrollView.drawsThatShowEdgeEffects = 1

    _ = await scrollView.stableScrollViewSnapshot(sleepDuration: 0)

    #expect(scrollView.draws.allSatisfy { $0.topHidden && $0.bottomHidden })
    // The first capture draws its only page twice, the second capture once.
    #expect(scrollView.draws.count == 3)
  }

  @Test
  @available(iOS 26.0, *)
  func pageIsDrawnAtMostThreeTimes() async throws {
    let scrollView = RecordingScrollView(contentHeight: 400)
    scrollView.drawsThatShowEdgeEffects = .max

    _ = await scrollView.stableScrollViewSnapshot(sleepDuration: 0)

    #expect(scrollView.draws.count == 6)
  }

  @Test(arguments: [false, true], [false, true])
  @available(iOS 26.0, *)
  func captureRestoresTheEdgeEffects(topHidden: Bool, bottomHidden: Bool) async throws {
    let scrollView = RecordingScrollView(contentHeight: 1000)
    scrollView.topEdgeEffect.isHidden = topHidden
    scrollView.bottomEdgeEffect.isHidden = bottomHidden
    scrollView.drawsThatShowEdgeEffects = .max

    let image = await scrollView.stableScrollViewSnapshot(sleepDuration: 0)

    #expect(image != nil)
    #expect(scrollView.topEdgeEffect.isHidden == topHidden)
    #expect(scrollView.bottomEdgeEffect.isHidden == bottomHidden)
  }

  @Test(arguments: [false, true], [false, true])
  @available(iOS 26.0, *)
  func failedCaptureRestoresTheEdgeEffects(topHidden: Bool, bottomHidden: Bool) async throws {
    let scrollView = RecordingScrollView(viewport: .zero, contentHeight: 0)
    scrollView.topEdgeEffect.isHidden = topHidden
    scrollView.bottomEdgeEffect.isHidden = bottomHidden

    let image = await scrollView.stableScrollViewSnapshot(sleepDuration: 0)

    #expect(image == nil)
    #expect(scrollView.draws.isEmpty)
    #expect(scrollView.topEdgeEffect.isHidden == topHidden)
    #expect(scrollView.bottomEdgeEffect.isHidden == bottomHidden)
  }
}

/// Records the edge effect state of every page draw. It can show the edge effects again
/// during layout or after a draw, as SwiftUI does when it re-applies its scroll view
/// configuration.
@available(iOS 26.0, *)
private final class RecordingScrollView: UIScrollView {
  struct Draw {
    let offsetY: CGFloat
    let topHidden: Bool
    let bottomHidden: Bool
  }

  var showsEdgeEffectsOnLayout = false
  var drawsThatShowEdgeEffects = 0
  private(set) var layoutsThatShowedEdgeEffects = 0
  private(set) var draws: [Draw] = []

  init(viewport: CGSize = CGSize(width: 320, height: 400), contentHeight: CGFloat) {
    super.init(frame: CGRect(origin: .zero, size: viewport))
    contentSize = CGSize(width: viewport.width, height: contentHeight)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var contentOffset: CGPoint {
    didSet { setNeedsLayout() }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if showsEdgeEffectsOnLayout {
      showEdgeEffects()
      layoutsThatShowedEdgeEffects += 1
    }
  }

  override func drawHierarchy(in rect: CGRect, afterScreenUpdates afterUpdates: Bool) -> Bool {
    draws.append(
      Draw(
        offsetY: contentOffset.y,
        topHidden: topEdgeEffect.isHidden,
        bottomHidden: bottomEdgeEffect.isHidden
      )
    )

    if drawsThatShowEdgeEffects > 0 {
      drawsThatShowEdgeEffects -= 1
      showEdgeEffects()
    }

    return true
  }

  private func showEdgeEffects() {
    topEdgeEffect.isHidden = false
    bottomEdgeEffect.isHidden = false
  }
}
