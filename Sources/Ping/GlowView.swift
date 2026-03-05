//
//  GlowView.swift
//  Ping
//
//  Created by Tanner on 9/17/25.
//

import Cocoa
import QuartzCore

class GlowView: NSView, @preconcurrency CAAnimationDelegate {
  private var glowLayer: CAGradientLayer!

  // Color cycling: queue ordered by priority (front = show next, LRU)
  private var colorQueue: [NSColor] = []
  private var currentColor: NSColor?
  private var isAnimating = false

  // Preview state
  private var previewColor: NSColor?
  private var savedColorQueue: [NSColor]?
  private var savedCurrentColor: NSColor?

  private enum AnimationPhase {
    case fadeIn
    case fadeOut
    case crossfade
  }

  private var phase: AnimationPhase = .fadeIn

  private let minOpacity: Float = 0.25
  private let maxOpacity: Float = 0.95
  private let fadeDuration: CFTimeInterval = 2.0
  private let crossfadeDuration: CFTimeInterval = 0.6

  init(frame frameRect: NSRect, baseColor: NSColor) {
    super.init(frame: frameRect)
    setupGlowEffect()
    updateAvailableColors([baseColor])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupGlowEffect()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    setupGlowEffect()
  }

  // MARK: - Public API

  /// Update the set of colors to cycle through without interrupting the current animation.
  /// New colors are prioritized (shown next), existing colors maintain LRU order.
  func updateAvailableColors(_ newColors: [NSColor]) {
    guard previewColor == nil else {
      // During preview, just save the updated pool for when preview ends
      savedCurrentColor = pickSavedCurrent(from: newColors)
      savedColorQueue = buildUpdatedQueue(
        newColors: newColors, excluding: savedCurrentColor)
      return
    }

    let allCurrent = ([currentColor].compactMap { $0 }) + colorQueue
    let sameSet =
      allCurrent.count == newColors.count
      && newColors.allSatisfy({ nc in
        allCurrent.contains(where: { colorsEqual($0, nc) })
      })
    if sameSet { return }

    if !isAnimating || currentColor == nil {
      // Not animating yet — start fresh
      currentColor = newColors.first
      colorQueue = Array(newColors.dropFirst())
      if let current = currentColor {
        applyColor(current)
        startFadeIn()
      }
      return
    }

    // Build new queue preserving LRU ordering
    var newQueue: [NSColor] = []

    // Brand new colors go to front (never shown = highest priority)
    let allKnown = allCurrent
    for color in newColors {
      if !allKnown.contains(where: { colorsEqual($0, color) }) {
        newQueue.append(color)
      }
    }

    // Existing queue colors that are still available keep their order
    for color in colorQueue {
      if newColors.contains(where: { colorsEqual($0, color) }) {
        newQueue.append(color)
      }
    }

    colorQueue = newQueue

    if newColors.isEmpty {
      isAnimating = false
      glowLayer?.removeAllAnimations()
      currentColor = nil
      colorQueue = []
    } else if let current = currentColor,
      !newColors.contains(where: { colorsEqual($0, current) })
    {
      // Current color was removed — ensure queue has a next color, then
      // accelerate the fade-out so stale color doesn't linger
      if colorQueue.isEmpty, let first = newColors.first {
        colorQueue = [first]
      }
      accelerateTransitionAway()
    }
  }

  /// Show a preview color, interrupting normal cycling.
  func setPreviewColor(_ color: NSColor) {
    if previewColor == nil {
      savedColorQueue = colorQueue
      savedCurrentColor = currentColor
    }
    previewColor = color
    currentColor = color
    colorQueue = []
    applyColor(color)
    startFadeIn()
  }

  /// End preview and resume normal cycling.
  func clearPreview() {
    guard previewColor != nil else { return }
    previewColor = nil

    if let saved = savedCurrentColor {
      currentColor = saved
      colorQueue = savedColorQueue ?? []
      savedColorQueue = nil
      savedCurrentColor = nil
      applyColor(saved)
      startFadeIn()
    } else {
      isAnimating = false
      glowLayer?.removeAllAnimations()
    }
  }

  // MARK: - Color helpers

  private func colorsEqual(_ a: NSColor, _ b: NSColor) -> Bool {
    guard let a = a.usingColorSpace(.sRGB),
      let b = b.usingColorSpace(.sRGB)
    else { return false }
    return abs(a.redComponent - b.redComponent) < 0.01
      && abs(a.greenComponent - b.greenComponent) < 0.01
      && abs(a.blueComponent - b.blueComponent) < 0.01
      && abs(a.alphaComponent - b.alphaComponent) < 0.01
  }

  private func nextColor() -> NSColor? {
    guard !colorQueue.isEmpty else { return nil }
    let next = colorQueue.removeFirst()
    if let current = currentColor {
      colorQueue.append(current)
    }
    return next
  }

  private func pickSavedCurrent(from newColors: [NSColor]) -> NSColor? {
    // Keep saved current if still available, otherwise pick first new color
    if let saved = savedCurrentColor,
      newColors.contains(where: { colorsEqual($0, saved) })
    {
      return saved
    }
    return newColors.first
  }

  private func buildUpdatedQueue(newColors: [NSColor], excluding: NSColor?)
    -> [NSColor]
  {
    newColors.filter { nc in
      if let ex = excluding, colorsEqual(nc, ex) { return false }
      return true
    }
  }

  // MARK: - Gradient

  private func gradientColors(for color: NSColor) -> [CGColor] {
    [
      color.cgColor,
      color.withAlphaComponent(0.15).cgColor,
      color.withAlphaComponent(0.0).cgColor,
    ]
  }

  private func applyColor(_ color: NSColor) {
    glowLayer.colors = gradientColors(for: color)
    glowLayer.locations = [0.0, 0.85, 1.0]
  }

  // MARK: - Setup

  private func setupGlowEffect() {
    self.wantsLayer = true

    glowLayer = CAGradientLayer()
    glowLayer.frame = self.bounds
    glowLayer.type = .radial

    glowLayer.startPoint = CGPoint(x: 0.5, y: 0)
    glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

    glowLayer.opacity = minOpacity
    self.layer?.addSublayer(glowLayer)
  }

  // MARK: - Animation

  private func startFadeIn() {
    phase = .fadeIn
    isAnimating = true
    glowLayer?.removeAllAnimations()

    glowLayer.opacity = maxOpacity

    let anim = CABasicAnimation(keyPath: "opacity")
    anim.fromValue = minOpacity
    anim.toValue = maxOpacity
    anim.duration = fadeDuration
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    anim.delegate = self

    glowLayer?.add(anim, forKey: "glowAnimation")
  }

  private func startFadeOut() {
    phase = .fadeOut

    glowLayer.opacity = minOpacity

    let anim = CABasicAnimation(keyPath: "opacity")
    anim.fromValue = maxOpacity
    anim.toValue = minOpacity
    anim.duration = fadeDuration
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    anim.delegate = self

    glowLayer?.add(anim, forKey: "glowAnimation")
  }

  private func startCrossfade(to color: NSColor) {
    phase = .crossfade
    let oldColors = glowLayer.colors
    currentColor = color
    let newColors = gradientColors(for: color)

    glowLayer.colors = newColors

    let anim = CABasicAnimation(keyPath: "colors")
    anim.fromValue = oldColors
    anim.toValue = newColors
    anim.duration = crossfadeDuration
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    anim.delegate = self

    glowLayer.add(anim, forKey: "glowAnimation")
  }

  private func accelerateTransitionAway() {
    guard phase != .crossfade else { return }

    let currentOpacity =
      glowLayer.presentation()?.opacity ?? glowLayer.opacity
    glowLayer.removeAllAnimations()

    let duration = max(
      0.15, Double(currentOpacity / maxOpacity) * fadeDuration * 0.5)

    phase = .fadeOut
    glowLayer.opacity = minOpacity

    let anim = CABasicAnimation(keyPath: "opacity")
    anim.fromValue = currentOpacity
    anim.toValue = minOpacity
    anim.duration = duration
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    anim.delegate = self

    glowLayer.add(anim, forKey: "glowAnimation")
  }

  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    guard flag else { return }

    switch phase {
    case .fadeIn:
      startFadeOut()
    case .fadeOut:
      if let next = nextColor() {
        startCrossfade(to: next)
      } else {
        startFadeIn()
      }
    case .crossfade:
      startFadeIn()
    }
  }

  override func layout() {
    super.layout()
    glowLayer?.frame = self.bounds
  }
}
