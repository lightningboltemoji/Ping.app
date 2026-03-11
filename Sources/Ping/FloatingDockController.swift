import SwiftUI

@MainActor
class FloatingDockController {
  private let state: AppState
  private var window: FloatingDockWindow?
  private var lastPosition: DockPosition
  private var lastMargin: Double

  init(state: AppState) {
    self.state = state
    self.lastPosition = state.floatingDockSettings.position
    self.lastMargin = state.floatingDockSettings.margin
    observeApps()
    observePreview()
    observeSnooze()
    observeSettings()
  }

  private func recreateWindow() {
    let wasVisible = window?.isVisible ?? false
    window?.orderOut(nil)
    window = nil
    if wasVisible {
      let w = ensureWindow()
      w.orderFrontRegardless()
    }
  }

  private func repositionWindow() {
    guard let window else { return }
    let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let frame = FloatingDockWindow.windowFrame(
      position: state.floatingDockSettings.position,
      margin: state.floatingDockSettings.margin,
      screen: screen
    )
    window.setFrame(frame, display: true)
  }

  private func ensureWindow() -> FloatingDockWindow {
    if let window { return window }
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let w = FloatingDockWindow(state: state, screen: screenFrame)
    window = w
    return w
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
          self.recreateWindow()
        } else if settings.margin != self.lastMargin {
          self.lastMargin = settings.margin
          self.repositionWindow()
        }
        // All other changes (opacity, iconSize, padding, backgroundColor,
        // showAppNames) are handled reactively by the SwiftUI view.
        self.observeSettings()
      }
    }
  }

  private func updateVisibility() {
    let shouldShow =
      !state.isSnoozed
      && (!state.activeFloatingDockApps.isEmpty || !state.previewFloatingDockApps.isEmpty)

    if shouldShow {
      let w = ensureWindow()
      w.orderFrontRegardless()
    } else {
      window?.orderOut(nil)
    }
  }
}
