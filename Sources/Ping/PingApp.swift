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

  private let state: AppState
  private let dockPoller: DockPoller
  private var glowWindow: GlowWindow?
  private var colorCycleTimer: Timer?
  private var currentColorIndex = 0

  init() {
    let state = AppState()
    self.state = state
    self.dockPoller = DockPoller(state: state)

    if let screen = NSScreen.main {
      self.glowWindow = GlowWindow(
        screen: screen, width: 1, height: 0.25,
        baseColor: NSColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.9)
      )
      self.glowWindow?.hideGlow()
    }
  }

  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup("Accessibility") {
      AccessibilityView()
    }
    .windowLevel(.floating)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)

    MenuBarExtra("Ping", systemImage: "bell.fill") {
      Text("ping").font(.custom("Chango", size: 13))
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
    .environment(state)
    .windowLevel(.floating)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)

    GlowScene(state: state, glowWindow: glowWindow)
  }
}

@available(macOS 26, *)
struct GlowScene: Scene {
  let state: AppState
  let glowWindow: GlowWindow?

  var body: some Scene {
    MenuBarExtra("GlowController", isInserted: .constant(false)) {
      GlowController(state: state, glowWindow: glowWindow)
    }
  }
}

@available(macOS 26, *)
struct GlowController: View {
  @State var state: AppState
  let glowWindow: GlowWindow?
  @State private var colorCycleIndex = 0
  @State private var cycleTimer: Timer?

  var body: some View {
    EmptyView()
      .onChange(of: state.activeGlowColors) { _, newColors in
        handleColorChange(newColors)
      }
  }

  private func handleColorChange(_ colors: [NSColor]) {
    cycleTimer?.invalidate()
    cycleTimer = nil
    colorCycleIndex = 0

    if colors.isEmpty {
      glowWindow?.hideGlow()
      return
    }

    glowWindow?.updateColor(colors[0])
    glowWindow?.showGlow()

    if colors.count > 1 {
      cycleTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) {
        _ in
        DispatchQueue.main.async {
          colorCycleIndex = (colorCycleIndex + 1) % colors.count
          glowWindow?.updateColor(colors[colorCycleIndex])
        }
      }
    }
  }
}
