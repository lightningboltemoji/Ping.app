import SwiftUI

@MainActor
class FloatingDockController {
  private let state: AppState
  private var window: FloatingDockWindow?

  init(state: AppState) {
    self.state = state
    observeApps()
    observePreview()
    observeSnooze()
  }

  private func ensureWindow() -> FloatingDockWindow {
    if let window { return window }
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
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
      _ = state.previewFloatingDock
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

  private func updateVisibility() {
    let shouldShow =
      !state.isSnoozed
      && (!state.activeFloatingDockApps.isEmpty || state.previewFloatingDock)

    if shouldShow {
      let w = ensureWindow()
      w.orderFrontRegardless()
    } else {
      window?.orderOut(nil)
    }
  }
}
