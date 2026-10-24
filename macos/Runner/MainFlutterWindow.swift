import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let frameName = "MainWindow"

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // Narrow windows get the phone layout; any smaller and it clips.
    self.contentMinSize = NSSize(width: 400, height: 620)
    self.setFrame(defaultFrame(), display: true)
    // Reopen where the player left it.
    _ = self.setFrameUsingName(Self.frameName)
    _ = self.setFrameAutosaveName(Self.frameName)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// A desktop-sized window, up to 1280x820, centred on the screen.
  private func defaultFrame() -> NSRect {
    guard let visible = (self.screen ?? NSScreen.main)?.visibleFrame else {
      return self.frame
    }
    let content = NSSize(
      width: min(1280, (visible.width * 0.9).rounded()),
      height: min(820, (visible.height * 0.9).rounded()))
    var frame = self.frameRect(forContentRect: NSRect(origin: .zero, size: content))
    frame.origin = NSPoint(
      x: visible.midX - frame.width / 2,
      y: visible.midY - frame.height / 2)
    return frame
  }
}
