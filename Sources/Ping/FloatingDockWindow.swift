import SwiftUI

class FloatingDockWindow: NSWindow {
  init(state: AppState, screen: NSRect) {
    super.init(
      contentRect: NSRect(
        x: screen.origin.x,
        y: screen.maxY - 70,
        width: screen.width,
        height: 70
      ),
      styleMask: [.borderless],
      backing: .buffered,
      defer: true
    )

    self.level = .statusBar
    self.isOpaque = false
    self.backgroundColor = .clear
    self.ignoresMouseEvents = true
    self.hasShadow = false
    self.collectionBehavior = [.canJoinAllSpaces, .stationary]

    let view = FloatingDockView()
      .frame(maxWidth: .infinity)
      .environment(state)
    self.contentView = NSHostingView(rootView: view)
  }
}
