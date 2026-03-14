import SwiftUI

@MainActor
class GlowController {
  private let state: AppState
  private var windows: [ScreenPositionKey: GlowWindow] = [:]
  nonisolated(unsafe) private var screenObserver: NSObjectProtocol?

  init(state: AppState) {
    self.state = state
    handleConfigChange(state.activeGlowConfigs)
    observeConfigs()
    observePreview()
    observeSnooze()
    observeMonitorMode()
    screenObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.handleScreenChange()
      }
    }
  }

  deinit {
    if let screenObserver {
      NotificationCenter.default.removeObserver(screenObserver)
    }
  }

  private var targetScreens: [NSScreen] {
    switch state.monitorMode {
    case .mainMonitor: [NSScreen.main].compactMap { $0 }
    case .allMonitors: NSScreen.screens
    }
  }

  private func window(for position: GlowPosition, on screen: NSScreen) -> GlowWindow {
    let key = ScreenPositionKey(displayID: screen.displayID, position: position)
    if let existing = windows[key] { return existing }
    let w = GlowWindow(screen: screen, position: position)
    w.hideGlow()
    windows[key] = w
    return w
  }

  private func handleScreenChange() {
    closeAllWindows()
    handleConfigChange(state.activeGlowConfigs)
  }

  private func closeAllWindows() {
    for (_, win) in windows {
      win.orderOut(nil)
    }
    windows.removeAll()
  }

  private func observeMonitorMode() {
    withObservationTracking {
      _ = state.monitorMode
    } onChange: {
      Task { @MainActor in
        self.closeAllWindows()
        self.handleConfigChange(self.state.activeGlowConfigs)
        self.observeMonitorMode()
      }
    }
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
        let screens = [NSScreen.main].compactMap { $0 }
        if let config = self.state.previewGlowConfig {
          for screen in screens {
            let w = self.window(for: config.position, on: screen)
            w.setPreviewConfig(config)
            w.showGlow()
          }
          for (key, win) in self.windows where key.position != config.position {
            win.clearPreview()
            if self.state.activeGlowConfigs.filter({ $0.position == key.position }).isEmpty {
              win.hideGlow()
            }
          }
        } else {
          for (key, win) in self.windows {
            win.clearPreview()
            if self.state.activeGlowConfigs.filter({ $0.position == key.position }).isEmpty {
              win.hideGlow()
            }
          }
        }
        self.observePreview()
      }
    }
  }

  private func observeSnooze() {
    withObservationTracking {
      _ = state.snoozedUntil
    } onChange: {
      Task { @MainActor in
        self.handleConfigChange(self.state.activeGlowConfigs)
        self.observeSnooze()
      }
    }
  }

  private func handleConfigChange(_ configs: [GlowConfig]) {
    if state.isSnoozed {
      for (_, win) in windows {
        win.updateConfigs([])
        win.hideGlow()
      }
      return
    }

    let grouped = Dictionary(grouping: configs, by: { $0.position })
    var activeKeys = Set<ScreenPositionKey>()

    for screen in targetScreens {
      for (position, posConfigs) in grouped {
        let key = ScreenPositionKey(displayID: screen.displayID, position: position)
        activeKeys.insert(key)
        let w = window(for: position, on: screen)
        w.updateConfigs(posConfigs)
        w.showGlow()
      }
    }

    for (key, win) in windows where !activeKeys.contains(key) {
      win.updateConfigs([])
      win.hideGlow()
    }
  }
}
