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
  private var colors: [NSColor] = []
  private var colorCycleIndex = 0

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
    self.colors = [baseColor]
    super.init(frame: frameRect)
    setupGlowEffect()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupGlowEffect()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    setupGlowEffect()
  }

  func setGlowColor(color: NSColor) {
    setGlowColors(colors: [color])
  }

  func setGlowColors(colors: [NSColor]) {
    self.colors = colors
    self.colorCycleIndex = 0
    if let first = colors.first {
      applyColor(first)
    }
    startFadeIn()
  }

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

  private func setupGlowEffect() {
    self.wantsLayer = true

    glowLayer = CAGradientLayer()
    glowLayer.frame = self.bounds
    glowLayer.type = .radial

    if let first = colors.first {
      applyColor(first)
    }
    glowLayer.startPoint = CGPoint(x: 0.5, y: 0)
    glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

    glowLayer.opacity = minOpacity
    self.layer?.addSublayer(glowLayer)

    startFadeIn()
  }

  private func startFadeIn() {
    phase = .fadeIn
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

  private func startCrossfade() {
    phase = .crossfade
    let oldColors = glowLayer.colors
    colorCycleIndex = (colorCycleIndex + 1) % colors.count
    let newColors = gradientColors(for: colors[colorCycleIndex])

    glowLayer.colors = newColors

    let anim = CABasicAnimation(keyPath: "colors")
    anim.fromValue = oldColors
    anim.toValue = newColors
    anim.duration = crossfadeDuration
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
      if colors.count > 1 {
        startCrossfade()
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
