import Foundation
import Yams

struct PersistedApp: Codable {
  var name: String
  var color: String
  var position: GlowPosition
  var size: Double
  var opacity: Double
  var color_option: String
  var numeric_color: String
  var non_numeric_color: String

  init(from app: AppSettings) {
    name = app.name
    color = app.color
    position = app.position
    size = app.size
    opacity = app.opacity
    color_option = app.colorOption.rawValue
    numeric_color = app.numericColor
    non_numeric_color = app.nonNumericColor
  }

  func toAppSettings() -> AppSettings {
    AppSettings(
      name: name,
      color: color,
      position: position,
      size: size,
      opacity: opacity,
      colorOption: ColorOptions(rawValue: color_option) ?? .basic,
      numericColor: numeric_color,
      nonNumericColor: non_numeric_color
    )
  }
}

struct PersistedSettings: Codable {
  var launch_on_startup: Bool
  var refresh_interval: Double
  var apps: [PersistedApp]

  init(from state: AppState) {
    launch_on_startup = state.launchOnStartup
    refresh_interval = state.refreshInterval
    apps = state.apps.map { PersistedApp(from: $0) }
  }
}

enum SettingsPersistence {
  static var configFile: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".config/ping/settings.yaml")
  }

  static func save(state: AppState) {
    let persisted = PersistedSettings(from: state)
    do {
      let encoder = YAMLEncoder()
      let yaml = try encoder.encode(persisted)
      let dir = configFile.deletingLastPathComponent()
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      try yaml.write(to: configFile, atomically: true, encoding: .utf8)
    } catch {
      print("Failed to save settings: \(error)")
    }
  }

  static func load() -> (launchOnStartup: Bool, refreshInterval: Double, apps: [AppSettings])? {
    guard FileManager.default.fileExists(atPath: configFile.path) else { return nil }
    do {
      let yaml = try String(contentsOf: configFile, encoding: .utf8)
      let decoder = YAMLDecoder()
      let persisted = try decoder.decode(PersistedSettings.self, from: yaml)
      return (
        launchOnStartup: persisted.launch_on_startup,
        refreshInterval: persisted.refresh_interval,
        apps: persisted.apps.map { $0.toAppSettings() }
      )
    } catch {
      print("Failed to load settings: \(error)")
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
