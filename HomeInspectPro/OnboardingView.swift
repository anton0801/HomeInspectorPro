import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            index: 0,
            title: "Inspect Your\nHome Structure",
            subtitle: "Document every floor, room, wall, ceiling, and foundation with detailed condition tracking.",
            icon: "building.2.fill",
            accentIcon: "magnifyingglass",
            gradient: [Color(hex: "#1B3A6B"), Color(hex: "#2D6A9F")],
            features: ["Track structural conditions", "Monitor walls & foundations", "Multi-building support"]
        ),
        OnboardingPage(
            index: 1,
            title: "Track Defects\nand Repairs",
            subtitle: "Log cracks, leaks, and humidity. Assign severity, track repair progress, and control costs.",
            icon: "wrench.and.screwdriver.fill",
            accentIcon: "exclamationmark.triangle.fill",
            gradient: [Color(hex: "#2D6A9F"), Color(hex: "#4A90D9")],
            features: ["Log defects with photos", "Track repair costs", "Severity scoring system"]
        ),
        OnboardingPage(
            index: 2,
            title: "Keep History\nof Inspections",
            subtitle: "Every inspection, measurement, and photo is saved. Generate reports and never miss a detail.",
            icon: "chart.bar.doc.horizontal.fill",
            accentIcon: "clock.fill",
            gradient: [Color(hex: "#1B3A6B"), Color(hex: "#F4A340")],
            features: ["Full inspection history", "Photo documentation", "Condition score analytics"]
        )
    ]

    var body: some View {
        ZStack {
            // Background
            Color.hpBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: { appVM.hasOnboarded = true }) {
                            Text("Skip")
                                .font(.hpBodySemi())
                                .foregroundColor(.hpTextSecondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else {
                        Color.clear.frame(height: 44).padding(.top, 16)
                    }
                }

                // Page content with drag
                ZStack {
                    ForEach(pages.indices, id: \.self) { i in
                        OnboardingPageView(page: pages[i])
                            .offset(x: CGFloat(i - currentPage) * UIScreen.main.bounds.width + dragOffset)
                            .animation(.hpSpring, value: currentPage)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation.width }
                        .onEnded { value in
                            withAnimation(.hpSpring) {
                                dragOffset = 0
                                if value.translation.width < -60 && currentPage < pages.count - 1 {
                                    currentPage += 1
                                } else if value.translation.width > 60 && currentPage > 0 {
                                    currentPage -= 1
                                }
                            }
                        }
                )
                .frame(maxHeight: .infinity)

                // Bottom controls
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.hpBlue : Color.hpBorder)
                                .frame(width: i == currentPage ? 28 : 8, height: 8)
                                .animation(.hpSpring, value: currentPage)
                                .onTapGesture { withAnimation(.hpSpring) { currentPage = i } }
                        }
                    }

                    // Action button
                    if currentPage == pages.count - 1 {
                        HPButton(title: "Get Started", icon: "arrow.right", style: .primary) {
                            withAnimation(.hpSpring) { appVM.hasOnboarded = true }
                        }
                        .padding(.horizontal, 24)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity))
                    } else {
                        HPButton(title: "Continue", icon: "arrow.right", style: .primary) {
                            withAnimation(.hpSpring) { currentPage += 1 }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let index: Int
    let title: String
    let subtitle: String
    let icon: String
    let accentIcon: String
    let gradient: [Color]
    let features: [String]
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var illustrationScale: CGFloat = 0.7
    @State private var illustrationOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    @State private var floatOffset: CGFloat = 0
    @State private var orbitAngle: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            // Illustration
            ZStack {
                // Gradient circle bg
                Circle()
                    .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 180, height: 180)
                    .shadow(color: page.gradient.first?.opacity(0.35) ?? .clear, radius: 24, x: 0, y: 8)

                // Floating accent ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 220, height: 220)

                // Main icon
                Image(systemName: page.icon)
                    .font(.system(size: 62, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: floatOffset)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floatOffset)

                // Orbiting accent icon
                Image(systemName: page.accentIcon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle().fill(Color.hpAccent)
                              .shadow(color: Color.hpAccent.opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                    .offset(
                        x: cos(orbitAngle * .pi / 180) * 100,
                        y: sin(orbitAngle * .pi / 180) * 100
                    )
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: orbitAngle)
            }
            .scaleEffect(illustrationScale)
            .opacity(illustrationOpacity)
            .padding(.top, 20)

            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.hpTitle())
                    .foregroundColor(.hpTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(page.subtitle)
                    .font(.hpBody())
                    .foregroundColor(.hpTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
            .offset(y: textOffset)
            .opacity(textOpacity)
            .padding(.horizontal, 24)

            // Features list
            VStack(spacing: 10) {
                ForEach(page.features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.hpSuccess.opacity(0.12))
                                .frame(width: 26, height: 26)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.hpSuccess)
                        }
                        Text(feature)
                            .font(.hpBody())
                            .foregroundColor(.hpTextPrimary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 32)
            .offset(y: textOffset)
            .opacity(textOpacity)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.05)) {
                illustrationScale = 1
                illustrationOpacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                textOffset = 0
                textOpacity = 1
            }
            floatOffset = -8
            orbitAngle = 360
        }
    }
}
