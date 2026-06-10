import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void

    // Phase flags
    @State private var isVisible = false
    @State private var bgShift = false
    @State private var particlesVisible = false
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    // Particle animation
    @State private var particleRotation: Double = 0
    @State private var particlePulse = false

    private let particles: [(angle: Double, radius: CGFloat, size: CGFloat, speed: Double)] = (0..<8).map { i in
        (angle: Double(i) * 45.0, radius: CGFloat.random(in: 60...100), size: CGFloat.random(in: 5...12), speed: Double.random(in: 1.5...3.0))
    }

    var body: some View {
        ZStack {
            // Layer 1: Animated background gradient
            LinearGradient(
                colors: bgShift
                    ? [Color(hex: "064E3B"), Color(hex: "065F46"), Color(hex: "16A34A")]
                    : [Color(hex: "022C22"), Color(hex: "064E3B"), Color(hex: "065F46")],
                startPoint: bgShift ? .topLeading : .bottomTrailing,
                endPoint: bgShift ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(Animation.linear(duration: 3.0).repeatForever(autoreverses: true), value: bgShift)

            // Layer 2: Floating particles (barn environment)
            if isVisible {
                ForEach(0..<particles.count, id: \.self) { i in
                    let p = particles[i]
                    FloatingParticle(
                        baseAngle: p.angle,
                        radius: p.radius,
                        size: p.size,
                        rotation: particleRotation,
                        pulse: particlePulse
                    )
                }
                .opacity(particlesVisible ? 0.7 : 0)
                .animation(.easeInOut(duration: 0.8), value: particlesVisible)
            }

            // Decorative rings
            if isVisible {
                Circle()
                    .stroke(Color.white.opacity(particlePulse ? 0.08 : 0.04), lineWidth: 1)
                    .frame(width: 280, height: 280)
                    .scaleEffect(particlePulse ? 1.05 : 1.0)
                    .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: particlePulse)

                Circle()
                    .stroke(Color.appPrimary.opacity(particlePulse ? 0.15 : 0.07), lineWidth: 1.5)
                    .frame(width: 200, height: 200)
                    .scaleEffect(particlePulse ? 0.97 : 1.03)
                    .animation(Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.3), value: particlePulse)
            }

            // Layer 3: Logo + title
            VStack(spacing: 0) {
                // Icon assembly
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .scaleEffect(particlePulse ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: particlePulse)

                    Image(systemName: "thermometer.sun.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(hex: "4ADE80"), Color(hex: "22C55E")], startPoint: .top, endPoint: .bottom)
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 28)

                Text("Coop Climate")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                Spacer().frame(height: 10)

                Text("Care for your birds smarter")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
                    .opacity(subtitleOpacity)
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .onAppear {
            guard !isVisible else { return }
            isVisible = true

            // Phase 1 (0–0.6s): bg builds
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) { bgShift = true }

            // Phase 2 (0.6–1.4s): particles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard isVisible else { return }
                particlesVisible = true
                withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
                    particleRotation = 360
                }
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    particlePulse = true
                }
            }

            // Phase 3 (1.4s): logo entrance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                guard isVisible else { return }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                    titleOffset = 0
                    titleOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
                    subtitleOpacity = 1.0
                }
            }

            // Phase 4 (2.6s): hold then exit
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                guard isVisible else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    exitScale = 1.18
                    exitOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    onComplete()
                }
            }
        }
        .onDisappear {
            isVisible = false
            bgShift = false
            particlesVisible = false
            particleRotation = 0
            particlePulse = false
            logoScale = 0.4
            logoOpacity = 0
            titleOffset = 30
            titleOpacity = 0
            subtitleOpacity = 0
        }
    }
}

private struct FloatingParticle: View {
    let baseAngle: Double
    let radius: CGFloat
    let size: CGFloat
    let rotation: Double
    let pulse: Bool

    private var angle: Double { baseAngle + rotation }
    private var x: CGFloat { cos(angle * .pi / 180) * radius }
    private var y: CGFloat { sin(angle * .pi / 180) * radius }

    var body: some View {
        Circle()
            .fill(Color.appPrimary.opacity(pulse ? 0.5 : 0.3))
            .frame(width: size, height: size)
            .offset(x: x, y: y)
            .blur(radius: size > 9 ? 1 : 0)
    }
}
