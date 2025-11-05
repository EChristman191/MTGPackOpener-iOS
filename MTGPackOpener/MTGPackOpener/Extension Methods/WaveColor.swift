//
//  WaveColor.swift
//  MTGPackOpener
//
//  Created by J.E.D.
//

import SwiftUI

// MARK: - Public API
public extension Shape {
    /// Animate the stroke color of this Shape between two colors.
    func waveStroke(
        color1: Color,
        color2: Color,
        lineWidth: CGFloat = 4,
        duration: Double = 2.0
    ) -> some View {
        AnimatedWaveStroke(shape: self,
                           color1: color1,
                           color2: color2,
                           lineWidth: lineWidth,
                           duration: duration)
    }
}

// MARK: - Implementation
private struct AnimatedWaveStroke<S: Shape>: View {
    let shape: S
    let color1: Color
    let color2: Color
    let lineWidth: CGFloat
    let duration: Double

    @State private var toggle = false

    var body: some View {
        shape
            .stroke(toggle ? color1 : color2, lineWidth: lineWidth)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true),
                       value: toggle)
            .onAppear { toggle = true }
    }
}
