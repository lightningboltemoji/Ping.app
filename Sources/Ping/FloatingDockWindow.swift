//
//  FloatingDock.swift
//  Ping
//
//  Created by Tanner on 9/28/25.
//

import SwiftUI

class FloatingDockWindow: NSWindow {
  init(screen: NSRect) {
    super.init(
      contentRect: NSRect(
        x: screen.midX - screen.midX / 2,
        y: screen.size.height - 140,
        width: screen.midX,
        height: 70
      ),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    // Always on top
    self.level = .statusBar
    self.makeKeyAndOrderFront(nil)
    self.orderFrontRegardless()

    // Opaque
    self.isOpaque = false
    self.backgroundColor = .clear
    self.ignoresMouseEvents = true

    let contentView = FloatingDockView()
    self.contentView = NSHostingView(rootView: contentView)
  }
}
