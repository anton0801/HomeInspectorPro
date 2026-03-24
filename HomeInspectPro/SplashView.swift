import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var shieldOffset: CGFloat = -20
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var particlesVisible = false
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient.hpPrimary
                .ignoresSafeArea()

            // Decorative rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.white.opacity(0.06 - Double(i) * 0.015), lineWidth: 1.5)
                    .frame(width: CGFloat(180 + i * 80), height: CGFloat(180 + i * 80))
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                    .animation(.hpSlow.delay(Double(i) * 0.15), value: ringScale)
            }

            // Particles
            if particlesVisible {
                ForEach(0..<12) { i in
                    SplashParticle(index: i)
                }
            }

            VStack(spacing: 28) {
                Spacer()

                // Logo
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    // Shield background
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 110, height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                        )

                    // Icon layers
                    VStack(spacing: 4) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .offset(y: shieldOffset)

                        Image(systemName: "house.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color.hpAccent)
                            .offset(y: -shieldOffset * 0.3)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                VStack(spacing: 6) {
                    Text("HomeInspect Pro")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.5)

                    Text("Monitor your building condition.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                        .tracking(0.3)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)

                Spacer()

                // Bottom loader dots
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        LoadingDot(index: i)
                    }
                }
                .opacity(textOpacity)
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            // Stage 1: Ring expand
            withAnimation(.hpSlow) {
                ringScale = 1
                ringOpacity = 1
            }
            // Stage 2: Logo appear
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
                logoScale = 1
                logoOpacity = 1
                shieldOffset = 0
            }
            // Stage 3: Text slide up
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
                textOpacity = 1
                textOffset = 0
            }
            // Stage 4: Particles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation { particlesVisible = true }
            }
        }
    }
}

struct SplashParticle: View {
    let index: Int
    @State private var animate = false

    private var angle: Double { Double(index) * (360 / 12) }
    private var radius: CGFloat { CGFloat.random(in: 80...160) }
    private var size: CGFloat { CGFloat.random(in: 3...7) }
    private var delay: Double { Double(index) * 0.06 }

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.4))
            .frame(width: size, height: size)
            .offset(
                x: cos(angle * .pi / 180) * radius * (animate ? 1.2 : 0.6),
                y: sin(angle * .pi / 180) * radius * (animate ? 1.2 : 0.6)
            )
            .opacity(animate ? 0.6 : 0)
            .animation(.easeInOut(duration: 1.5 + Double.random(in: 0...0.5))
                        .delay(delay).repeatForever(autoreverses: true), value: animate)
            .onAppear { animate = true }
    }
}

struct LoadingDot: View {
    let index: Int
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.4

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 7, height: 7)
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(
                .easeInOut(duration: 0.6)
                .delay(Double(index) * 0.2)
                .repeatForever(autoreverses: true),
                value: scale
            )
            .onAppear {
                scale = 1.0
                opacity = 1.0
            }
    }
}
