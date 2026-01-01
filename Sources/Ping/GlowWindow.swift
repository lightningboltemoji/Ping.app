//
//  GlowWindow.swift
//  Ping
//
//  Created by Tanner on 9/17/25.
//

import Cocoa
import QuartzCore

class GlowWindow: NSWindow {

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: backingStoreType,
            defer: flag
        )

        // Make window transparent and allow it to appear above other windows
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        self.level = NSWindow.Level.floating
        self.ignoresMouseEvents = true  // Allow clicks to pass through

        // Create and set the glow view
        let glowView = GlowView(frame: contentRect)
        self.contentView = glowView
    }
}
