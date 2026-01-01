//
//  DockPoller.swift
//  Ping
//
//  Created by Tanner on 9/16/25.
//

internal import Combine
import Foundation

class DockPoller: ObservableObject {

    @Published var count = 0

    private var pollingTimer: Timer?
    private var interval: TimeInterval

    init(interval: TimeInterval) {
        self.interval = interval
    }

    func start() {
        self.poll()
        self.pollingTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true,
        ) { _ in
            self.poll()
        }
    }

    func stop() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    func poll() {
        print("Poll")
        if let s = DockItem.list().first(where: { i in i.title == "Mail" }),
            let i = Int(s.badgeCount() ?? "")
        {
            print("Count: ", i)
            count = i
        }
    }
}
