import AppKit
import SwiftUI

enum GlowPosition: String, Codable, CaseIterable {
  case top, bottom, left, right
}

enum ColorOptions: String, Codable, CaseIterable {
  case basic, advanced
}

enum Effect: String, Codable, CaseIterable {
  case glow
  case floatingDock

  var label: String {
    switch self {
    case .glow: "Glow"
    case .floatingDock: "Floating Dock"
    }
  }
}

struct GlowAppearance: Codable, Equatable {
  var position: GlowPosition = .bottom
  var size: Double = 1.0
  var opacity: Double = 1.0
  var color: String = "Green"
}

struct GlowSettings: Codable, Equatable {
  var settingsMode: ColorOptions = .basic
  var normal: GlowAppearance = GlowAppearance()
  var nonNumeric: GlowAppearance = GlowAppearance()
}

struct FloatingDockSettings: Codable, Equatable {
  var showAppName: Bool = true
}

struct AppSettings: Codable, Equatable, Identifiable {
  var id = UUID()
  var name: String
  var effect: Effect = .glow
  var glowSettings: GlowSettings = GlowSettings()
  var floatingDockSettings: FloatingDockSettings = FloatingDockSettings()
}

@Observable
class AppState {

  static let colorPalette: [(name: String, color: NSColor)] = [
    ("Red", NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.9)),
    ("Orange", NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)),
    ("Yellow", NSColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.9)),
    ("Green", NSColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.9)),
    ("Blue", NSColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 0.9)),
    ("Purple", NSColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 0.9)),
    ("Pink", NSColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 0.9)),
    ("White", NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)),
  ]

  static func nsColor(forName name: String) -> NSColor {
    colorPalette.first(where: { $0.name.lowercased() == name.lowercased() })?.color
      ?? NSColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.9)
  }

  static func resolvedAppearance(for app: AppSettings, badge: String) -> GlowAppearance {
    let glow = app.glowSettings
    if glow.settingsMode == .advanced && badge.isEmpty {
      return glow.nonNumeric
    }
    return glow.normal
  }

  static func resolvedColor(for app: AppSettings, badge: String) -> NSColor {
    let appearance = resolvedAppearance(for: app, badge: badge)
    return nsColor(forName: appearance.color).withAlphaComponent(appearance.opacity)
  }

  static func resolvedConfig(for app: AppSettings, badge: String) -> GlowConfig {
    let appearance = resolvedAppearance(for: app, badge: badge)
    return GlowConfig(
      color: nsColor(forName: appearance.color).withAlphaComponent(appearance.opacity),
      size: appearance.size, opacity: appearance.opacity,
      position: appearance.position)
  }

  var launchOnStartup = true
  var refreshInterval = 1.0
  var count = 0
  var apps: [AppSettings] = []
  var dockAppNames: [String] = []
  var appIcons: [String: NSImage] = [:]
  var activeGlowConfigs: [GlowConfig] = []
  var previewGlowConfig: GlowConfig? = nil
}
