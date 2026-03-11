import SwiftUI

struct FloatingDockView: View {

  @Environment(AppState.self) private var state

  var body: some View {
    let items =
      state.previewFloatingDockApps.isEmpty
      ? state.activeFloatingDockApps : state.previewFloatingDockApps
    let settings = state.floatingDockSettings
    if !items.isEmpty {
      HStack(spacing: 12) {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
          VStack(spacing: 4) {
            let iconImage = Group {
              if let icon = item.icon {
                Image(nsImage: icon)
                  .resizable()
                  .frame(width: settings.iconSize, height: settings.iconSize)
              } else {
                Image(systemName: "app.fill")
                  .resizable()
                  .frame(width: settings.iconSize, height: settings.iconSize)
                  .foregroundStyle(.secondary)
              }
            }
            if settings.showBadges {
              iconImage.overlay(alignment: .topTrailing) {
                badgeView(for: item.badge, iconSize: settings.iconSize)
                  .offset(x: settings.iconSize * 0.1, y: -settings.iconSize * 0.05)
              }
            } else {
              iconImage
            }
            if settings.showAppNames {
              Text(item.appName)
                .font(.system(size: 10))
                .foregroundStyle(.primary)
                .lineLimit(1)
            }
          }
        }
      }
      .padding(.horizontal, settings.padding)
      .padding(.vertical, 10)
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Color(nsColor: settings.backgroundColor.nsColor).opacity(0.15))
          )
      }
      .opacity(settings.opacity)
    }
  }

  @ViewBuilder
  private func badgeView(for badge: String, iconSize: Double) -> some View {
    let badgeSize = max(iconSize * 0.44, 16.0)
    let isNumeric = !badge.isEmpty && badge.allSatisfy(\.isNumber)

    Circle()
      .fill(.red)
      .frame(width: badgeSize, height: badgeSize)
      .overlay {
        if isNumeric {
          Text(badge)
            .font(.system(size: badgeSize * 0.55, weight: .bold))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
      }
  }
}
