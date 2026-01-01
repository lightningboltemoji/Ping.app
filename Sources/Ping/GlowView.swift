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

    override init(frame frameRect: NSRect) {
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

    private func setupGlowEffect() {
        self.wantsLayer = true

        // Create a radial gradient effect using CALayer with a custom drawing
        glowLayer = CAGradientLayer()
        glowLayer.frame = self.bounds
        glowLayer.type = .radial

        // Golden glow colors - adjust these for different effects
        let goldColor = NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9)
            .cgColor
        let transparentGold = NSColor(
            red: 1.0,
            green: 0.8,
            blue: 0.2,
            alpha: 0.15
        ).cgColor
        let transparentGold2 = NSColor(
            red: 1.0,
            green: 0.8,
            blue: 0.2,
            alpha: 0.0
        ).cgColor

        glowLayer.colors = [goldColor, transparentGold, transparentGold2]
        glowLayer.locations = [0.0, 0.9, 1.0]

        // Position the center of the radial gradient at the bottom center
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

        glowLayer.add(pulseAnimation, forKey: "pulseAnimation")
    }

    override func layout() {
        super.layout()
        glowLayer?.frame = self.bounds
    }

    func setGlowColor(_ color: NSColor) {
        let glowColor = color.cgColor
        let transparentColor = color.withAlphaComponent(0.0).cgColor
        glowLayer.colors = [transparentColor, glowColor, transparentColor]
    }

    func setGlowIntensity(_ intensity: Double) {
        pulseAnimation.fromValue = max(0.1, intensity - 0.3)
        pulseAnimation.toValue = min(1.0, intensity + 0.3)
        glowLayer.removeAnimation(forKey: "pulseAnimation")
        glowLayer.add(pulseAnimation, forKey: "pulseAnimation")
    }
}
