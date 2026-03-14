import SwiftUI

@MainActor
class FloatingDockController {
  private let state: AppState
  private var windows: [CGDirectDisplayID: FloatingDockWindow] = [:]
  private var lastPosition: DockPosition
  private var lastMargin: Double
  nonisolated(unsafe) private var screenObserver: NSObjectProtocol?

  init(state: AppState) {
    self.state = state
    self.lastPosition = state.floatingDockSettings.position
    self.lastMargin = state.floatingDockSettings.margin
    observeApps()
    observePreview()
    observeSnooze()
    observeSettings()
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

  private func handleScreenChange() {
    recreateWindows()
  }

  private func recreateWindows() {
    let wasVisible = windows.values.contains { $0.isVisible }
    for (_, win) in windows {
      win.orderOut(nil)
    }
    windows.removeAll()
    if wasVisible {
      for screen in targetScreens {
        let w = ensureWindow(for: screen)
        w.orderFrontRegardless()
      }
    }
  }

  private func repositionWindows() {
    for (displayID, win) in windows {
      guard let screen = targetScreens.first(where: { $0.displayID == displayID }) else {
        continue
      }
      let frame = FloatingDockWindow.windowFrame(
        position: state.floatingDockSettings.position,
        margin: state.floatingDockSettings.margin,
        screen: screen.visibleFrame
      )
      win.setFrame(frame, display: true)
    }
  }

  private func ensureWindow(for screen: NSScreen) -> FloatingDockWindow {
    let displayID = screen.displayID
    if let existing = windows[displayID] { return existing }
    let w = FloatingDockWindow(state: state, screen: screen.visibleFrame)
    windows[displayID] = w
    return w
  }

  private func observeMonitorMode() {
    withObservationTracking {
      _ = state.monitorMode
    } onChange: {
      Task { @MainActor in
        self.recreateWindows()
        self.observeMonitorMode()
      }
    }
  }

  private func observeApps() {
    withObservationTracking {
      _ = state.activeFloatingDockApps
    } onChange: {
      Task { @MainActor in
        self.updateVisibility()
        self.observeApps()
      }
    }
  }

  private func observePreview() {
    withObservationTracking {
      _ = state.previewFloatingDockApps
    } onChange: {
      Task { @MainActor in
        self.updateVisibility()
        self.observePreview()
      }
    }
  }

  private func observeSnooze() {
    withObservationTracking {
      _ = state.snoozedUntil
    } onChange: {
      Task { @MainActor in
        self.updateVisibility()
        self.observeSnooze()
      }
    }
  }

  private func observeSettings() {
    withObservationTracking {
      _ = state.floatingDockSettings
    } onChange: {
      Task { @MainActor in
        let settings = self.state.floatingDockSettings
        if settings.position != self.lastPosition {
          self.lastPosition = settings.position
          self.lastMargin = settings.margin
          self.recreateWindows()
        } else if settings.margin != self.lastMargin {
          self.lastMargin = settings.margin
          self.repositionWindows()
        }
        self.observeSettings()
      }
    }
  }

  private func updateVisibility() {
    let shouldShow =
      !state.isSnoozed
      && (!state.activeFloatingDockApps.isEmpty || !state.previewFloatingDockApps.isEmpty)

    if shouldShow {
      let screens =
        state.previewFloatingDockApps.isEmpty
        ? targetScreens : [NSScreen.main].compactMap { $0 }
      let targetDisplayIDs = Set(screens.map { $0.displayID })

      for screen in screens {
        let w = ensureWindow(for: screen)
        w.orderFrontRegardless()
      }

      for (displayID, win) in windows where !targetDisplayIDs.contains(displayID) {
        win.orderOut(nil)
      }
    } else {
      for (_, win) in windows {
        win.orderOut(nil)
      }
    }
  }
}
