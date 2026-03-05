//
//  ContentView.swift
//  Ping
//
//  Created by Tanner on 9/13/25.
//

import SwiftUI

struct FloatingDockView: View {

  @Environment(AppState.self) private var state

  var body: some View {
    @Bindable var state = state
    VStack {
      Text("Overlay \(state.count)")
        .foregroundColor(.white)
        .font(.headline)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.5))
  }
}

#Preview {
  FloatingDockView()
}
