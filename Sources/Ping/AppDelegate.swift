//
//  AppDelegate.swift
//  Ping
//
//  Created by Tanner on 9/16/25.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!

    override init() {
        FontLoader.load()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }

        let floatingDock = FloatingDockWindow(screen: screen.frame)

        let height = screen.frame.height / 3 as CGFloat
        let windowRect = NSRect(
            x: 0,
            y: -height,
            width: screen.frame.width,
            height: height * 2
        )
        let glowWindow = GlowWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        glowWindow.makeKeyAndOrderFront(nil)
    }
}
