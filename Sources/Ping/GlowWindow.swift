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
  let position: GlowPosition

  init(
    screen: NSScreen,
    position: GlowPosition,
    depth: Double = 0.25,
  ) {
    self.position = position
    let sf = screen.frame
    let depthPx = sf.height * CGFloat(depth)

    let windowRect: NSRect
    switch position {
    case .bottom:
      windowRect = NSRect(
        x: sf.minX, y: sf.minY,
        width: sf.width, height: depthPx)
    case .top:
      windowRect = NSRect(
        x: sf.minX, y: sf.maxY - depthPx,
        width: sf.width, height: depthPx)
    case .left:
      windowRect = NSRect(
        x: sf.minX, y: sf.minY,
        width: depthPx, height: sf.height)
    case .right:
      windowRect = NSRect(
        x: sf.maxX - depthPx, y: sf.minY,
        width: depthPx, height: sf.height)
    }

    super.init(
      contentRect: windowRect,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    self.backgroundColor = NSColor.clear
    self.isOpaque = false
    self.hasShadow = false
    self.level = NSWindow.Level.floating
    self.ignoresMouseEvents = true

    glowView = GlowView(frame: windowRect, position: position)
    self.contentView = glowView
  }

  func updateConfigs(_ configs: [GlowConfig]) {
    glowView.updateAvailableConfigs(configs)
  }

  func setPreviewConfig(_ config: GlowConfig) {
    glowView.setPreviewConfig(config)
  }

  func clearPreview() {
    glowView.clearPreview()
  }

  func showGlow() {
    self.makeKeyAndOrderFront(nil)
  }

  func hideGlow() {
    self.orderOut(nil)
  }
}
