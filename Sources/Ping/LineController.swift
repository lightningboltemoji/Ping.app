import SwiftUI

@MainActor
class LineController {
  private let state: AppState
  private var windows: [ScreenPositionKey: LineWindow] = [:]
  nonisolated(unsafe) private var screenObserver: NSObjectProtocol?

  init(state: AppState) {
    self.state = state
    handleConfigChange(state.activeLineConfigs)
    observeConfigs()
    observeLineSettings()
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

  private func window(for position: GlowPosition, on screen: NSScreen) -> LineWindow {
    let key = ScreenPositionKey(displayID: screen.displayID, position: position)
    if let existing = windows[key] { return existing }
    let w = LineWindow(screen: screen, position: position)
    w.hideLine()
    windows[key] = w
    return w
  }

  private func handleScreenChange() {
    closeAllWindows()
    handleConfigChange(state.activeLineConfigs)
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
        self.handleConfigChange(self.state.activeLineConfigs)
        self.observeMonitorMode()
      }
    }
  }

  private func observeConfigs() {
    withObservationTracking {
      _ = state.activeLineConfigs
    } onChange: {
      Task { @MainActor in
        self.handleConfigChange(self.state.activeLineConfigs)
        self.observeConfigs()
      }
    }
  }

  private func observeLineSettings() {
    withObservationTracking {
      _ = state.lineSettings
    } onChange: {
      Task { @MainActor in
        self.reResolveConfigs()
        self.observeLineSettings()
      }
    }
  }

  private func reResolveConfigs() {
    var configs: [GlowConfig] = []
    for app in state.apps where app.effect == .line {
      guard let badge = state.currentBadges[app.name] else { continue }
      configs.append(
        AppState.resolvedLineConfig(for: app, badge: badge, lineSettings: state.lineSettings))
    }
    state.activeLineConfigs = configs
  }

  private func observePreview() {
    withObservationTracking {
      _ = state.previewLineConfigs
    } onChange: {
      Task { @MainActor in
        let configs = self.state.previewLineConfigs
        let screens = [NSScreen.main].compactMap { $0 }
        if !configs.isEmpty {
          let grouped = Dictionary(grouping: configs, by: { $0.position })
          for screen in screens {
            for (position, posConfigs) in grouped {
              let w = self.window(for: position, on: screen)
              w.setPreviewConfigs(posConfigs)
              w.showLine()
            }
          }
          for (key, win) in self.windows where grouped[key.position] == nil {
            win.clearPreview()
            if self.state.activeLineConfigs.filter({ $0.position == key.position }).isEmpty {
              win.hideLine()
            }
          }
        } else {
          for (key, win) in self.windows {
            win.clearPreview()
            if self.state.activeLineConfigs.filter({ $0.position == key.position }).isEmpty {
              win.hideLine()
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
        self.handleConfigChange(self.state.activeLineConfigs)
        self.observeSnooze()
      }
    }
  }

  private func handleConfigChange(_ configs: [GlowConfig]) {
    if state.isSnoozed {
      for (_, win) in windows {
        win.updateConfigs([])
        win.hideLine()
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
        w.showLine()
      }
    }

    for (key, win) in windows where !activeKeys.contains(key) {
      win.updateConfigs([])
      win.hideLine()
    }
  }
}
