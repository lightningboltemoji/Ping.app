//
//  SettingsView.swift
//  Ping
//
//  Created by Tanner on 9/28/25.
//

import SwiftUI

@available(macOS 26, *)
struct SettingsView: View {

  @Environment(AppState.self) private var state

  var body: some View {
    @Bindable var state = state
    VStack {
      Text("ping").font(.custom("Chango", size: 60))

      Toggle(isOn: $state.launchOnStartup) {
        Text("Launch on startup")
      }.padding(.top, 20)

      Slider(value: $state.refreshInterval, in: 0.1...5, step: 0.1) {
        Text(
          String(
            format: "Dock polling interval (%.1f sec)", state.refreshInterval)
        ).padding(.horizontal, 10)
      }.padding(.top, 20)

      Text(
        "A lower value will detect notifications more quickly, but may use more power"
      ).font(.system(size: 11))

      VStack(spacing: 0) {
        ForEach(Array(state.apps.enumerated()), id: \.element.id) {
          index, app in
          HStack {
            Picker("App", selection: $state.apps[index].name) {
              Text("Select app...").tag("")
              ForEach(state.dockAppNames, id: \.self) { name in
                Text(name).tag(name)
              }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Picker("Color", selection: $state.apps[index].color) {
              ForEach(AppState.colorPalette, id: \.name) { entry in
                HStack {
                  Circle()
                    .fill(Color(nsColor: entry.color))
                    .frame(width: 10, height: 10)
                  Text(entry.name)
                }
                .tag(entry.name)
              }
            }
            .labelsHidden()
            .frame(width: 120)

            Button {
              let id = app.id
              state.apps.removeAll { $0.id == id }
            } label: {
              Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 8)
        }
      }
      .frame(height: 150)
      .background(Color(nsColor: .controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .padding(.top, 20)

      HStack {
        Spacer()
        Button(action: {
          state.apps.append(AppSettings(name: "", color: "Green"))
        }) {
          Image(systemName: "plus")
        }
      }
      .padding(.top, 4)
    }
    .scenePadding()
    .frame(maxWidth: 450, minHeight: 100)
    .fixedSize()
  }
}
