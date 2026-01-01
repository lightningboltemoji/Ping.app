//
//  PingApp.swift
//  Ping
//
//  Created by Tanner on 9/13/25.
//

import SwiftUI

@main
@available(macOS 26, *)
struct PingApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup("Accessibility") {
            AccessibilityView()
        }
        .windowLevel(.floating)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        MenuBarExtra("Ping", systemImage: "bell.fill") {
            Text("ping").font(.custom("Chango", size: 14))
            Divider()
            SettingsLink {
                Text("Settings")
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        Settings {
            SettingsView().onAppear {
                if let window = NSApplication.shared.windows.first(where: {
                    $0.identifier?.rawValue.contains("Settings") ?? false
                }) {
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    window.styleMask.insert(.fullSizeContentView)
                }
            }
        }
        .windowLevel(.floating)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
