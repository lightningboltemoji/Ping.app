import SwiftUI

struct FloatingDockView: View {

  @Environment(AppState.self) private var state

  var body: some View {
    let items =
      state.previewFloatingDockApps.isEmpty
      ? state.activeFloatingDockApps : state.previewFloatingDockApps
    if !items.isEmpty {
      HStack(spacing: 12) {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
          VStack(spacing: 4) {
            if let icon = item.icon {
              Image(nsImage: icon)
                .resizable()
                .frame(width: 32, height: 32)
            } else {
              Image(systemName: "app.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.secondary)
            }
            if item.showAppName {
              Text(item.appName)
                .font(.system(size: 10))
                .foregroundStyle(.primary)
                .lineLimit(1)
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .opacity(0.8)
    }
  }
}
