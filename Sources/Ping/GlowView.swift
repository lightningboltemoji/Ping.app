//
//  GlowView.swift
//  Ping
//
//  Created by Tanner on 9/17/25.
//

import Cocoa
import QuartzCore

class GlowView: NSView {
  private var glowLayer: CAGradientLayer!
  private var pulseAnimation: CABasicAnimation!
  private var baseColor: NSColor

  init(frame frameRect: NSRect, baseColor: NSColor) {
    self.baseColor = baseColor
    super.init(frame: frameRect)
    setupGlowEffect()
  }

  required init?(coder: NSCoder) {
    self.baseColor = NSColor()
    super.init(coder: coder)
    setupGlowEffect()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    setupGlowEffect()
  }

  func setGlowColor(color: NSColor) {
    self.baseColor = color
    let one = color.cgColor
    let two = color.withAlphaComponent(0.15).cgColor
    let three = color.withAlphaComponent(0.0).cgColor

    glowLayer.colors = [one, two, three]
    glowLayer.locations = [0.0, 0.85, 1.0]
  }

  private func setupGlowEffect() {
    self.wantsLayer = true

    glowLayer = CAGradientLayer()
    glowLayer.frame = self.bounds
    glowLayer.type = .radial

    setGlowColor(color: self.baseColor)
    glowLayer.startPoint = CGPoint(x: 0.5, y: 0)
    glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

    self.layer?.addSublayer(glowLayer)

    setupPulseAnimation()
  }

  private func setupPulseAnimation() {
    pulseAnimation = CABasicAnimation(keyPath: "opacity")
    pulseAnimation.fromValue = 0.25
    pulseAnimation.toValue = 0.95
    pulseAnimation.duration = 2.0
    pulseAnimation.repeatCount = Float.infinity
    pulseAnimation.autoreverses = true
    pulseAnimation.timingFunction = CAMediaTimingFunction(
      name: .easeInEaseOut
    )

    glowLayer.removeAnimation(forKey: "pulseAnimation")
    glowLayer.add(pulseAnimation, forKey: "pulseAnimation")
  }

  override func layout() {
    super.layout()
    glowLayer?.frame = self.bounds
  }
}
