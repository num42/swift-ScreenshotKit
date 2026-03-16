# ScreenshotKit

A Swift package for capturing screenshots of iOS UI — including full-page scrollable content and stable captures that wait for rendering to settle.

## Requirements

- iOS 13.0+
- Swift 6.2+

## Installation

### Swift Package Manager

Add ScreenshotKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/swift-ScreenshotKit", from: "1.0.0")
]
```

Or add it in Xcode via **File → Add Package Dependencies**.

## Usage

### Capture the largest available screenshot

Automatically captures the full scrollable content if a `UIScrollView` is present in the top view controller, otherwise falls back to a window snapshot.

```swift
import ScreenshotKit

let image = await UIApplication.shared.largestScreenshot(resize: true)
```

### Stable window snapshot

Captures a window snapshot that polls until two consecutive frames match, ensuring animations and async rendering have settled before capturing.

```swift
let image = await UIApplication.shared.stableSnapShot()
```

### Stable scroll view snapshot

Captures the full scrollable content of the top view controller's scroll view, waiting for rendering to settle before compositing the full-page image.

```swift
let image = await UIApplication.shared.stableScrollViewSnapshot()
```

### Capture a specific scroll view

```swift
let image = await myScrollView.stableScrollViewSnapshot()
```

### Basic view snapshot

```swift
let image = myView.snapshot(resize: true)
```

### Access the top view controller

```swift
let vc = UIApplication.shared.topViewController
```

### Access the key window

```swift
let window = UIApplication.shared.firstWindow
```

### Find a subview by type

```swift
let scrollView = view.subviewOfType(UIScrollView.self)
```

### Access splash screen images

Retrieves the app's splash screen images from the system's SplashBoard cache. Returns an empty array if unavailable.

```swift
let splashImages = UIApplication.shared.splashScreens
```

## How stable capture works

The `stableSnapShot()` and `stableScrollViewSnapshot()` methods use a polling strategy:

1. Capture two consecutive screenshots with a 100ms delay between them.
2. Compare their PNG data.
3. If they differ, wait another 100ms and capture again.
4. Repeat up to 6 times until two consecutive captures match.

This ensures the UI has finished rendering (including async image loads, animations, etc.) before the final screenshot is taken.

## Scroll view capture

`UIScrollView.stableScrollViewSnapshot()` composes a full-page image of the entire scrollable content by:

1. Waiting for stable rendering (polling loop above).
2. Temporarily zeroing out content insets and offsets.
3. Iterating through vertical offsets equal to the viewport height.
4. Drawing each visible section into a `CGContext` with the correct translation.
5. Restoring original insets and offset via `defer`.

The resulting image always uses a scale of `1.0` (device-independent pixels) for predictable output dimensions.

## API Reference

### `UIApplication`

| API | Description |
|-----|-------------|
| `firstWindow: UIWindow?` | The key window from the first connected window scene. |
| `topViewController: UIViewController?` | The topmost presented view controller, traversing nav, tab, and modal stacks. |
| `topViewController(base:)` | Recursive helper for traversing the view controller hierarchy. |
| `largestScreenshot(resize:) async -> UIImage?` | Best-effort screenshot: full scroll view content or window snapshot. iOS 16+. |
| `stableSnapShot() async -> UIImage?` | Window snapshot that waits for rendering to settle. |
| `stableScrollViewSnapshot() async -> UIImage?` | Full-page scroll view capture that waits for rendering to settle. |
| `splashScreens: [UIImage]` | Splash screen images from the system SplashBoard cache. |

### `UIScrollView`

| API | Description |
|-----|-------------|
| `stableScrollViewSnapshot() async -> UIImage?` | Full-page capture of scrollable content, polling until stable. |

### `UIView`

| API | Description |
|-----|-------------|
| `snapshot(resize:) -> UIImage?` | Snapshot of the view and its subview hierarchy. |
| `subviewOfType<T>(_:) -> T?` | Recursive depth-first search for a subview of a given type. |

## License

MIT
