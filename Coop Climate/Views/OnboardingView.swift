import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardPage1().tag(0)
                OnboardPage2().tag(1)
                OnboardPage3().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 20) {
                PageDots(total: 3, current: currentPage)

                HStack(spacing: 16) {
                    if currentPage < 2 {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                onComplete()
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.appTextInactive)
                        .frame(maxWidth: .infinity)

                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(LinearGradient(colors: [Color.appPrimary, Color.appPrimaryActive], startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                onComplete()
                            }
                        }) {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(LinearGradient(colors: [Color.appPrimary, Color.appPrimaryActive], startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 52)
        }
    }
}

// MARK: - Page 1: Manage bird groups (tap-to-burst)
private struct OnboardPage1: View {
    @State private var burst = false
    @State private var iconScale: CGFloat = 1.0
    @State private var particles: [BurstParticle] = []
    @State private var isVisible = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "F0FDF4"), Color(hex: "DCFCE7")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                ZStack {
                    ForEach(particles) { p in
                        Circle()
                            .fill(Color.appPrimary.opacity(0.6))
                            .frame(width: p.size, height: p.size)
                            .offset(x: burst ? p.targetX : 0, y: burst ? p.targetY : 0)
                            .opacity(burst ? 0 : 1)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(p.delay), value: burst)
                    }

                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.12))
                            .frame(width: 140, height: 140)
                        Image(systemName: "house.and.flag.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(LinearGradient(colors: [Color.appPrimary, Color.appPrimaryActive], startPoint: .top, endPoint: .bottom))
                    }
                    .scaleEffect(iconScale)
                    .onTapGesture {
                        triggerBurst()
                    }
                }
                .frame(height: 200)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    Text("Manage Bird Groups")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Keep every group organized.\nTrack type, count, age and location.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Tap the icon")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.appPrimaryActive)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear {
            isVisible = true
            particles = (0..<12).map { _ in
                BurstParticle(
                    id: UUID(),
                    targetX: CGFloat.random(in: -100...100),
                    targetY: CGFloat.random(in: -120...(-20)),
                    size: CGFloat.random(in: 6...14),
                    delay: Double.random(in: 0...0.1)
                )
            }
        }
        .onDisappear { isVisible = false }
    }

    private func triggerBurst() {
        burst = false
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { iconScale = 0.85 }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) { iconScale = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard isVisible else { return }
            burst = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                guard isVisible else { return }
                burst = false
            }
        }
    }
}

// MARK: - Page 2: Track daily care (drag gesture)
private struct OnboardPage2: View {
    @State private var dragOffset: CGSize = .zero
    @State private var thermometerAngle: Double = 0
    @State private var isVisible = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "EFF6FF"), Color(hex: "DBEAFE")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                ZStack {
                    Circle()
                        .fill(Color.appBlue.opacity(0.10))
                        .frame(width: 140, height: 140)

                    Image(systemName: "thermometer.sun.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(LinearGradient(colors: [Color.appOrange, Color.appBlue], startPoint: .top, endPoint: .bottom))
                        .rotationEffect(.degrees(thermometerAngle))
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = CGSize(
                                        width: max(-50, min(50, value.translation.width)),
                                        height: max(-50, min(50, value.translation.height))
                                    )
                                    thermometerAngle = Double(value.translation.width) * 0.6
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                        dragOffset = .zero
                                        thermometerAngle = 0
                                    }
                                }
                        )
                }
                .frame(height: 200)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    Text("Track Daily Care")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Too hot or too cold?\nLog climate readings and spot risks before they affect your flock.")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Drag the thermometer")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.appBlue)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false; dragOffset = .zero; thermometerAngle = 0 }
    }
}

// MARK: - Page 3: Insights (scroll-driven parallax)
private struct OnboardPage3: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var pulse = false
    @State private var isVisible = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "F0FDF4"), Color(hex: "ECFDF5")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                ZStack {
                    Circle()
                        .fill(Color.appCyan.opacity(0.10))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulse ? 1.08 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)

                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 58, weight: .medium))
                        .foregroundStyle(LinearGradient(colors: [Color.appBlue, Color.appCyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .offset(y: scrollOffset * 0.2)
                }
                .frame(height: 200)
                .gesture(
                    DragGesture()
                        .onChanged { value in scrollOffset = value.translation.height }
                        .onEnded { _ in withAnimation(.spring()) { scrollOffset = 0 } }
                )

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    Text("See Useful Insights")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Make better decisions every day.\nReports, trends and risk levels at a glance.")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear { isVisible = true; pulse = true }
        .onDisappear { isVisible = false; pulse = false; scrollOffset = 0 }
    }
}

// MARK: - Burst particle model
private struct BurstParticle: Identifiable {
    let id: UUID
    let targetX: CGFloat
    let targetY: CGFloat
    let size: CGFloat
    let delay: Double
}
