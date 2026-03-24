import SwiftUI
import UIKit

// MARK: - Color Palette
extension Color {
    static let hpNavy       = Color(hex: "#1B3A6B")
    static let hpBlue       = Color(hex: "#2D6A9F")
    static let hpLightBlue  = Color(hex: "#4A90D9")
    static let hpAccent     = Color(hex: "#F4A340")
    static let hpAccentDark = Color(hex: "#D4831A")
    static let hpSuccess    = Color(hex: "#34C759")
    static let hpWarning    = Color(hex: "#FF9F0A")
    static let hpDanger     = Color(hex: "#FF3B30")
    static let hpBackground = Color(hex: "#F2F5FA")
    static let hpSurface    = Color.white
    static let hpTextPrimary    = Color(hex: "#1C1C1E")
    static let hpTextSecondary  = Color(hex: "#6B7280")
    static let hpBorder     = Color(hex: "#E5E7EB")
    static let hpCard       = Color.white

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default: (a,r,g,b) = (255,1,1,1)
        }
        self.init(.sRGB,
                  red:     Double(r)/255,
                  green:   Double(g)/255,
                  blue:    Double(b)/255,
                  opacity: Double(a)/255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let hpPrimary = LinearGradient(
        colors: [Color.hpNavy, Color.hpBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let hpAccentGrad = LinearGradient(
        colors: [Color(hex: "#F4A340"), Color(hex: "#F4C340")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let hpBgGrad = LinearGradient(
        colors: [Color.hpBackground, Color.white],
        startPoint: .top, endPoint: .bottom)

    static let hpSuccessGrad = LinearGradient(
        colors: [Color(hex: "#34C759"), Color(hex: "#30D158")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let hpDangerGrad = LinearGradient(
        colors: [Color(hex: "#FF3B30"), Color(hex: "#FF6B35")],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Typography
extension Font {
    static func hpLargeTitle() -> Font { .system(size: 34, weight: .bold,     design: .rounded) }
    static func hpTitle()      -> Font { .system(size: 28, weight: .bold,     design: .rounded) }
    static func hpTitle2()     -> Font { .system(size: 22, weight: .bold,     design: .rounded) }
    static func hpTitle3()     -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func hpHeadline()   -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func hpBody()       -> Font { .system(size: 15, weight: .regular,  design: .rounded) }
    static func hpBodySemi()   -> Font { .system(size: 15, weight: .semibold, design: .rounded) }
    static func hpCaption()    -> Font { .system(size: 12, weight: .medium,   design: .rounded) }
    static func hpCaption2()   -> Font { .system(size: 11, weight: .regular,  design: .rounded) }
    static func hpNumeric()    -> Font { .system(size: 36, weight: .bold,     design: .rounded) }
}

// MARK: - Animations
extension Animation {
    static let hpSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let hpFast   = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let hpSlow   = Animation.spring(response: 0.6, dampingFraction: 0.75)
}

// MARK: - Card Modifier
struct HPCardModifier: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.hpCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 3)
    }
}

extension View {
    func hpCard(_ padding: CGFloat = 16) -> some View {
        modifier(HPCardModifier(padding: padding))
    }
}

// MARK: - Partial Rounded Corner Shape
struct HPRoundedCorner: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect,
                          byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

extension View {
    func hpCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(HPRoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Shimmer
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.5), .clear],
                        startPoint: .init(x: phase - 0.3, y: 0),
                        endPoint: .init(x: phase + 0.3, y: 0))
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Press Scale Effect
struct PressScaleEffect: ViewModifier {
    @State private var pressed = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(.hpFast, value: pressed)
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false })
    }
}

extension View {
    func pressScale() -> some View { modifier(PressScaleEffect()) }
}

// MARK: - Condition Score Color
extension Double {
    var conditionColor: Color {
        switch self {
        case 80...100: return .hpSuccess
        case 60..<80:  return Color(hex: "#A8D96A")
        case 40..<60:  return .hpWarning
        case 20..<40:  return Color(hex: "#FF6B35")
        default:       return .hpDanger
        }
    }
}
