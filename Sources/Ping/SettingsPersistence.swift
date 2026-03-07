import Foundation
import Yams
import os

private let logger = Logger(subsystem: "Ping", category: "settings")

struct SettingsFile: Codable {
  var launchOnStartup: Bool
  var refreshInterval: Double
  var apps: [AppSettings]

  enum CodingKeys: String, CodingKey {
    case launchOnStartup = "launch_on_startup"
    case refreshInterval = "refresh_interval"
    case apps
  }

  init(state: AppState) {
    launchOnStartup = state.launchOnStartup
    refreshInterval = state.refreshInterval
    apps = state.apps
  }
}

enum SettingsPersistence {
  static var configFile: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".config/ping/settings.yaml")
  }

  static func save(state: AppState) {
    let settings = SettingsFile(state: state)
    do {
      let encoder = YAMLEncoder()
      let yaml = try encoder.encode(settings)
      let dir = configFile.deletingLastPathComponent()
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      try yaml.write(to: configFile, atomically: true, encoding: .utf8)
    } catch {
      logger.error("Failed to save settings: \(error)")
    }
  }

  static func load() -> (launchOnStartup: Bool, refreshInterval: Double, apps: [AppSettings])? {
    guard FileManager.default.fileExists(atPath: configFile.path) else { return nil }
    do {
      let yaml = try String(contentsOf: configFile, encoding: .utf8)
      let decoder = YAMLDecoder()
      let settings = try decoder.decode(SettingsFile.self, from: yaml)
      return (
        launchOnStartup: settings.launchOnStartup,
        refreshInterval: settings.refreshInterval,
        apps: settings.apps
      )
    } catch {
      logger.error("Failed to load settings: \(error)")
      return nil
    }
  }
}

@MainActor
class SettingsAutoSaver {
  private let state: AppState
  private var saveTask: Task<Void, Never>?

  init(state: AppState) {
    self.state = state
    observe()
  }

  private func observe() {
    withObservationTracking {
      _ = state.launchOnStartup
      _ = state.refreshInterval
      _ = state.apps
    } onChange: {
      Task { @MainActor in
        self.scheduleSave()
        self.observe()
      }
    }
  }

  private func scheduleSave() {
    saveTask?.cancel()
    saveTask = Task {
      do {
        try await Task.sleep(for: .milliseconds(500))
      } catch {
        return
      }
      SettingsPersistence.save(state: state)
    }
  }
}
