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
  private let glowController: GlowController

  init() {
    let state = AppState()
    self.state = state
    self.dockPoller = DockPoller(state: state)
    self.glowController = GlowController(state: state, screen: NSScreen.main)
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
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: {
          $0.identifier?.rawValue.contains("Settings") ?? false
        }) {
          window.titlebarAppearsTransparent = true
          window.titleVisibility = .hidden
          window.styleMask.insert(.fullSizeContentView)
        }
      }
      .onDisappear {
        NSApp.setActivationPolicy(.accessory)
      }
    }
    .environment(state)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
  }
}

@MainActor
class GlowController {
  private let state: AppState
  private let screen: NSScreen?
  private var windows: [GlowPosition: GlowWindow] = [:]

  init(state: AppState, screen: NSScreen?) {
    self.state = state
    self.screen = screen
    observeConfigs()
    observePreview()
  }

  private func window(for position: GlowPosition) -> GlowWindow? {
    if let existing = windows[position] { return existing }
    guard let screen = screen else { return nil }
    let w = GlowWindow(screen: screen, position: position)
    w.hideGlow()
    windows[position] = w
    return w
  }

  private func observeConfigs() {
    withObservationTracking {
      _ = state.activeGlowConfigs
    } onChange: {
      Task { @MainActor in
        self.handleConfigChange(self.state.activeGlowConfigs)
        self.observeConfigs()
      }
    }
  }

  private func observePreview() {
    withObservationTracking {
      _ = state.previewGlowConfig
    } onChange: {
      Task { @MainActor in
        if let config = self.state.previewGlowConfig {
          let w = self.window(for: config.position)
          w?.setPreviewConfig(config)
          w?.showGlow()
          // Clear preview on other windows
          for (pos, win) in self.windows where pos != config.position {
            win.clearPreview()
            if self.state.activeGlowConfigs.filter({ $0.position == pos }).isEmpty {
              win.hideGlow()
            }
          }
        } else {
          for (pos, win) in self.windows {
            win.clearPreview()
            if self.state.activeGlowConfigs.filter({ $0.position == pos }).isEmpty {
              win.hideGlow()
            }
          }
        }
        self.observePreview()
      }
    }
  }

  private func handleConfigChange(_ configs: [GlowConfig]) {
    let grouped = Dictionary(grouping: configs, by: { $0.position })

    // Update each position that has configs
    for (position, posConfigs) in grouped {
      let w = window(for: position)
      w?.updateConfigs(posConfigs)
      w?.showGlow()
    }

    // Hide windows for positions with no configs
    for (position, win) in windows where grouped[position] == nil {
      win.updateConfigs([])
      win.hideGlow()
    }
  }
}
