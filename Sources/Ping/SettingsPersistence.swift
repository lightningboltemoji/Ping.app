import Foundation
import Yams

struct PersistedGlowAppearance: Codable {
  var position: GlowPosition
  var size: Double
  var opacity: Double
  var color: String

  init(from appearance: GlowAppearance) {
    position = appearance.position
    size = appearance.size
    opacity = appearance.opacity
    color = appearance.color
  }

  func toGlowAppearance() -> GlowAppearance {
    GlowAppearance(position: position, size: size, opacity: opacity, color: color)
  }
}

struct PersistedGlowSettings: Codable {
  var settings_mode: String
  var position: GlowPosition
  var size: Double
  var opacity: Double
  var color: String
  var non_numeric: PersistedGlowAppearance?

  // Legacy fields for backward compatibility
  var color_option: String?
  var non_numeric_color: String?

  init(from glow: GlowSettings) {
    settings_mode = glow.settingsMode.rawValue
    position = glow.normal.position
    size = glow.normal.size
    opacity = glow.normal.opacity
    color = glow.normal.color
    non_numeric = PersistedGlowAppearance(from: glow.nonNumeric)
  }

  func toGlowSettings() -> GlowSettings {
    let mode =
      ColorOptions(rawValue: settings_mode)
      ?? ColorOptions(rawValue: color_option ?? "") ?? .basic
    let normal = GlowAppearance(position: position, size: size, opacity: opacity, color: color)
    let nonNumeric: GlowAppearance
    if let nn = non_numeric {
      nonNumeric = nn.toGlowAppearance()
    } else {
      // Legacy migration: use non_numeric_color if present, otherwise copy normal
      nonNumeric = GlowAppearance(
        position: position, size: size, opacity: opacity,
        color: non_numeric_color ?? color)
    }
    return GlowSettings(settingsMode: mode, normal: normal, nonNumeric: nonNumeric)
  }
}

struct PersistedFloatingDockSettings: Codable {
  var show_app_name: Bool

  init(from settings: FloatingDockSettings) {
    show_app_name = settings.showAppName
  }

  func toFloatingDockSettings() -> FloatingDockSettings {
    FloatingDockSettings(showAppName: show_app_name)
  }
}

struct PersistedApp: Codable {
  var name: String
  var effect: String
  var glow_settings: PersistedGlowSettings?
  var floating_dock_settings: PersistedFloatingDockSettings?

  init(from app: AppSettings) {
    name = app.name
    effect = app.effect.rawValue
    glow_settings = PersistedGlowSettings(from: app.glowSettings)
    floating_dock_settings = PersistedFloatingDockSettings(from: app.floatingDockSettings)
  }

  func toAppSettings() -> AppSettings {
    AppSettings(
      name: name,
      effect: Effect(rawValue: effect) ?? .glow,
      glowSettings: glow_settings?.toGlowSettings() ?? GlowSettings(),
      floatingDockSettings: floating_dock_settings?.toFloatingDockSettings()
        ?? FloatingDockSettings()
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
