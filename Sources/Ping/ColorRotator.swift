//
//  ColorRotator.swift
//  Ping
//
//  Created by Tanner on 3/4/26.
//

import Cocoa

struct GlowConfigRotator {
  /// LRU order: front = next to show
  private var queue: [GlowConfig] = []
  private(set) var currentConfig: GlowConfig?

  var isEmpty: Bool { currentConfig == nil && queue.isEmpty }

  var hasMultipleConfigs: Bool {
    currentConfig != nil && !queue.isEmpty
  }

  /// Update available configs. New configs go to front of queue,
  /// existing configs keep LRU order. Idempotent with same set.
  mutating func setAvailable(_ configs: [GlowConfig]) {
    guard !configs.isEmpty else {
      queue = []
      currentConfig = nil
      return
    }

    // If we have no current config, start fresh
    guard let current = currentConfig else {
      currentConfig = configs.first
      queue = Array(configs.dropFirst())
      return
    }

    let allKnown = [current] + queue

    // Brand-new configs go to front (highest priority)
    var newQueue: [GlowConfig] = []
    for config in configs {
      if !allKnown.contains(where: { $0 == config }) {
        newQueue.append(config)
      }
    }

    // Existing queue configs still available keep their LRU order
    for config in queue {
      if configs.contains(where: { $0 == config }) {
        newQueue.append(config)
      }
    }

    queue = newQueue

    // If current was removed, pull next from queue
    if !configs.contains(where: { $0 == current }) {
      currentConfig = queue.isEmpty ? nil : queue.removeFirst()
    }
  }

  /// Advance to next config. Returns the new current config.
  /// If only one config, returns current again. If empty, returns nil.
  mutating func next() -> GlowConfig? {
    guard let current = currentConfig else { return nil }
    guard !queue.isEmpty else { return current }

    let next = queue.removeFirst()
    queue.append(current)
    currentConfig = next
    return next
  }
}
