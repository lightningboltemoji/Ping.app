//
//  AccessibilityView.swift
//  Ping
//
//  Created by Tanner on 10/3/25.
//

@preconcurrency import ApplicationServices
import SwiftUI

struct AccessibilityView: View {

  var body: some View {
    VStack {
      if !AccessibilityView.hasAxPermission() {
        VStack {
          Text("ping").font(.custom("Chango", size: 60))

          Text(
            "Accessbility permissions are required"
          ).fontWeight(.bold).padding(.top, 10)

          Text(
            "The Accessibility API is used to communicate with Dock.app to check what apps have notification badges"
          ).multilineTextAlignment(.center).padding(.horizontal, 20)
            .padding(.top, 10)

          Button("Open Accessibility Settings") {
            Task {
              AccessibilityView.openSettings()
            }
          }.padding(.top, 15)

          Text(
            "Unfortunately, I don't think there's an alternative :("
          ).multilineTextAlignment(.center).padding(.horizontal, 20)
            .padding(.top, 15).font(
              .system(size: 11, weight: .thin)
            )
        }
        .frame(width: 400)
        .padding()
        .fixedSize()
        .onAppear {
          AccessibilityView.requestAxPermission()
        }
      } else {
        EmptyView().frame(width: 0, height: 0).hidden()
      }
    }
  }

  private static func hasAxPermission() -> Bool {
    return AXIsProcessTrusted()
  }

  private static func requestAxPermission() {
    let options = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
    ]
    print(AXIsProcessTrustedWithOptions(options as CFDictionary))
  }

  private static func openSettings() {
    if let url = URL(
      string:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    ) {
      NSWorkspace.shared.open(url)
    }
  }
}
