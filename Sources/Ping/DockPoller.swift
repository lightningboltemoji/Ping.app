import Foundation
import SwiftUI
import os

private let logger = Logger(subsystem: "Ping", category: "polling")

private struct BadgeOverride: Decodable {
  let appName: String
  let badge: String?
  let at: Double?
}

@MainActor
class DockPoller {

  private let state: AppState
  private var pollingTask: Task<Void, Never>?
  private let badgeOverrideEntries: [BadgeOverride]?
  private let launchTime: Date

  init(state: AppState) {
    self.state = state
    self.launchTime = Date()

    if let json = ProcessInfo.processInfo.environment["BADGES"],
      let data = json.data(using: .utf8),
      let entries = try? JSONDecoder().decode([BadgeOverride].self, from: data)
    {
      self.badgeOverrideEntries = entries
    } else {
      self.badgeOverrideEntries = nil
    }

    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil, queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      let app =
        notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
      Task { @MainActor in
        self.state.frontmostAppName = app?.localizedName
        if self.state.suppressWhileFocused {
          self.rebuildEffectConfigs()
        }
      }
    }
    state.frontmostAppName = NSWorkspace.shared.frontmostApplication?.localizedName

    pollingTask = Task {
      while !Task.isCancelled {
        self.poll()
        try? await Task.sleep(for: .seconds(self.state.refreshInterval))
      }
    }
  }

  private func currentBadgeOverrides() -> [String: String?]? {
    guard let entries = badgeOverrideEntries else { return nil }
    let elapsed = Date().timeIntervalSince(launchTime)
    var dict: [String: String?] = [:]
    for entry in entries where elapsed >= (entry.at ?? 0) {
      dict[entry.appName] = entry.badge
    }
    return dict
  }

  private func shouldSuppress(current: String, acknowledged: String) -> Bool {
    if let ackNum = Int(acknowledged) {
      if let curNum = Int(current) {
        return curNum <= ackNum
      }
      return false
    }
    // Ack was non-numeric
    if Int(current) != nil {
      return false
    }
    return true
  }

  private func rebuildEffectConfigs() {
    var configs: [GlowConfig] = []
    var lineConfigs: [GlowConfig] = []
    var floatingDockItems: [FloatingDockItem] = []

    let frontmost = state.suppressWhileFocused ? state.frontmostAppName : nil

    for app in state.apps {
      guard let badge = state.currentBadges[app.name] else { continue }

      if let acked = state.acknowledgedBadges[app.name],
        shouldSuppress(current: badge, acknowledged: acked)
      {
        continue
      }

      if let frontmost, frontmost == app.name {
        continue
      }

      switch app.effect {
      case .glow:
        configs.append(AppState.resolvedConfig(for: app, badge: badge))
      case .line:
        lineConfigs.append(
          AppState.resolvedLineConfig(for: app, badge: badge, lineSettings: state.lineSettings))
      case .floatingDock:
        floatingDockItems.append(
          FloatingDockItem(
            appName: app.name,
            badge: badge,
            icon: state.appIcons[app.name]
          ))
      }
    }

    state.activeGlowConfigs = configs
    state.activeLineConfigs = lineConfigs
    state.activeFloatingDockApps = floatingDockItems
  }

  private func poll() {
    let dockItems = DockItem.list()

    let names = dockItems.compactMap { $0.title }.sorted()
    if names != state.dockAppNames {
      state.dockAppNames = names
    }

    for item in dockItems {
      guard state.appIcons[item.title] == nil, let url = item.appURL else { continue }
      let icon = NSWorkspace.shared.icon(forFile: url.path)
      icon.size = NSSize(width: 32, height: 32)
      state.appIcons[item.title] = icon
    }

    var pollBadges: [String: String] = [:]

    for app in state.apps {
      let badge: String?
      if let overrides = currentBadgeOverrides(), let override = overrides[app.name] {
        badge = override
      } else if let dockItem = dockItems.first(where: { $0.title == app.name }) {
        badge = dockItem.badgeCount()
      } else {
        badge = nil
      }

      if let badge {
        pollBadges[app.name] = badge
      }

      guard badge != nil else {
        state.acknowledgedBadges.removeValue(forKey: app.name)
        continue
      }

      if let acked = state.acknowledgedBadges[app.name] {
        if shouldSuppress(current: badge!, acknowledged: acked) {
          // Track decreases so a return to the prior level counts as an increase
          if badge! != acked {
            state.acknowledgedBadges[app.name] = badge!
          }
        } else {
          state.acknowledgedBadges.removeValue(forKey: app.name)
        }
      }
    }

    state.currentBadges = pollBadges
    rebuildEffectConfigs()
  }
}
