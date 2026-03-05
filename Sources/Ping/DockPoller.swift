//
//  DockPoller.swift
//  Ping
//
//  Created by Tanner on 9/16/25.
//

import Atomics
internal import Combine
import Foundation
import SwiftUI

@MainActor
class DockPoller {

  private let state: AppState
  private var pollingTimer: Timer?

  init(state: AppState) {
    self.state = state
    self.start()
    self.observe()
  }

  private func observe() {
    withObservationTracking {
      _ = state.refreshInterval
    } onChange: {
      Task { @MainActor in
        print("Interval changed: \(self.state.refreshInterval)")
        self.setInterval(interval: self.state.refreshInterval)
        self.observe()
      }
    }
  }

  func start() {
    self.poll()
    self.pollingTimer = Timer.scheduledTimer(
      withTimeInterval: state.refreshInterval,
      repeats: true,
    ) { _ in
      self.poll()
    }
  }

  func stop() {
    pollingTimer?.invalidate()
  }

  func setInterval(interval: TimeInterval) {
    stop()
    start()
  }

  func poll() {
    let dockItems = DockItem.list()

    // Update dock app names for the settings picker
    let names = dockItems.compactMap { $0.title }.sorted()
    if names != state.dockAppNames {
      state.dockAppNames = names
    }

    // Load icons for any app not yet cached
    for item in dockItems {
      guard state.appIcons[item.title] == nil, let url = item.appURL else { continue }
      let icon = NSWorkspace.shared.icon(forFile: url.path)
      icon.size = NSSize(width: 32, height: 32)
      state.appIcons[item.title] = icon
    }

    // Check configured apps for badges
    var configs: [GlowConfig] = []
    for app in state.apps {
      if let dockItem = dockItems.first(where: { $0.title == app.name }) {
        if let badge = dockItem.badgeCount() {
          configs.append(AppState.resolvedConfig(for: app, badge: badge))
        }
      }
    }

    state.activeGlowConfigs = configs
  }
}
