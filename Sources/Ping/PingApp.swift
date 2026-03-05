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

    var glowWindow: GlowWindow?
    if let screen = NSScreen.main {
      glowWindow = GlowWindow(
        screen: screen, width: 1, height: 0.25
      )
      glowWindow?.hideGlow()
    }
    self.glowController = GlowController(state: state, glowWindow: glowWindow)
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
  private let glowWindow: GlowWindow?

  init(state: AppState, glowWindow: GlowWindow?) {
    self.state = state
    self.glowWindow = glowWindow
    observeConfigs()
    observePreview()
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
          self.glowWindow?.setPreviewConfig(config)
          self.glowWindow?.showGlow()
        } else {
          self.glowWindow?.clearPreview()
          // If no active configs, hide after preview ends
          if self.state.activeGlowConfigs.isEmpty {
            self.glowWindow?.hideGlow()
          }
        }
        self.observePreview()
      }
    }
  }

  private func handleConfigChange(_ configs: [GlowConfig]) {
    if configs.isEmpty {
      glowWindow?.hideGlow()
      return
    }

    glowWindow?.updateConfigs(configs)
    glowWindow?.showGlow()
  }
}
