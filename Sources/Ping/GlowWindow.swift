//
//  GlowWindow.swift
//  Ping
//
//  Created by Tanner on 9/17/25.
//

import Cocoa
import QuartzCore
import SwiftUI

class GlowWindow: NSWindow {

  private var glowView: GlowView!

  init(
    screen: NSScreen,
    width: Double,
    height: Double,
    baseColor: NSColor,
  ) {
    let height = screen.frame.height * height as CGFloat
    let windowRect = NSRect(
      x: (screen.frame.width - screen.frame.width * width) / 2 as CGFloat,
      y: -height,
      width: screen.frame.width * width,
      height: height * 2
    )

    super.init(
      contentRect: windowRect,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    // Make window transparent and allow it to appear above other windows
    self.backgroundColor = NSColor.clear
    self.isOpaque = false
    self.hasShadow = false
    self.level = NSWindow.Level.floating
    self.ignoresMouseEvents = true  // Allow clicks to pass through

    // Create and set the glow view
    glowView = GlowView(frame: windowRect, baseColor: baseColor)
    self.contentView = glowView
  }

  func updateColor(_ color: NSColor) {
    glowView.setGlowColor(color: color)
  }

  func updateColors(_ colors: [NSColor]) {
    glowView.setGlowColors(colors: colors)
  }

  func showGlow() {
    self.makeKeyAndOrderFront(nil)
  }

  func hideGlow() {
    self.orderOut(nil)
  }
}
