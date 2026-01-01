//
//  SettingsView.swift
//  Ping
//
//  Created by Tanner on 9/28/25.
//

import SwiftUI

struct AppSettings: Codable, Identifiable {
    var id = UUID()
    let name: String
    let color: String
}

@available(macOS 26, *)
struct SettingsView: View {
    @AppStorage("launchOnStartup") var launchOnStartup = true
    @AppStorage("refreshInterval") var refreshInterval = 1.0

    @AppStorage("apps") var apps: [AppSettings] = [
        AppSettings(name: "Slack", color: "red")
    ]

    init() {

    }

    var body: some View {
        VStack {
            Text("ping").font(.custom("Chango", size: 60))

            Toggle(isOn: $launchOnStartup) {
                Text("Launch on startup")
            }.padding(.top, 20)

            Slider(value: $refreshInterval, in: 0.1...5, step: 0.1) {
                Text(
                    String(
                        format: "Dock polling interval (%.1f sec)", $refreshInterval.wrappedValue)
                ).padding(.horizontal, 10)
            }.padding(.top, 20)

            Text(
                "A lower value will detect notifications more quickly, but may use more power"
            ).font(.system(size: 11))

            Table(apps) {
                TableColumn("App", value: \.name)
                TableColumn("Color", value: \.color)
            }.frame(height: 200).padding(.top, 30)
        }
        .scenePadding()
        .frame(maxWidth: 450, minHeight: 100)
        .fixedSize()
    }
}
