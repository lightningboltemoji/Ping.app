//
//  ContentView.swift
//  Ping
//
//  Created by Tanner on 9/13/25.
//

import SwiftUI

struct FloatingDockView: View {

    @ObservedObject private var dockPoller = DockPoller(interval: 2.0)

    var body: some View {
        VStack {
            Text("Overlay \(dockPoller.count)")
                .foregroundColor(.white)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .onAppear {
            print("Starting poller...")
            dockPoller.start()
        }
        .onDisappear {
            dockPoller.stop()
        }
    }
}

#Preview {
    FloatingDockView()
}
