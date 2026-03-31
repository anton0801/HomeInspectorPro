import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var shieldOffset: CGFloat = -20
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var particlesVisible = false
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    
    @StateObject private var app: HomeInspectApplication
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = UserDefaultsStorageService()
        let validation = FirebaseValidationService()
        let network = HTTPNetworkService()
        let notification = SystemNotificationService()
        
        _app = StateObject(wrappedValue: HomeInspectApplication(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient.hpPrimary
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    ZStack {
                        Color.black.ignoresSafeArea()
                        Image("home_inspect_build_l_bg")
                            .resizable().scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .ignoresSafeArea()
                            .blur(radius: 5)
                            .opacity(0.4)
                    }
                }
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
//                            Image(systemName: "shield.lefthalf.filled")
//                                .font(.system(size: 36, weight: .bold))
//                                .foregroundColor(.white)
//                                .offset(y: shieldOffset)
                            
                            Image(systemName: "house.fill")
                                .font(.system(size: 52, weight: .semibold))
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
                        
                        Text("Loading...")
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
                    
                    Text("Wait when all app data loads")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                        .tracking(0.3)
                        .padding(.bottom, 52)
                }
                
                NavigationLink(
                    destination: HomeInspectWebView().navigationBarHidden(true),
                    isActive: $app.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $app.navigateToMain
                ) { EmptyView() }
            }
            .onAppear {
                // Stage 1: Ring expand
                setupStreams()
                setupNetworkMonitoring()
                app.initialize()
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
            .fullScreenCover(isPresented: $app.showPermissionPrompt) {
                HomeInspectNotificationView(app: app)
            }
            .fullScreenCover(isPresented: $app.showOfflineView) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                app.handleTracking(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                app.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                app.networkStatusChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
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

struct HomeInspectNotificationView: View {
    let app: HomeInspectApplication
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "home_inspect_build_p_bg_l" : "home_inspect_build_p_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 16, weight: .black))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                app.requestPermission()
            } label: {
                Image("home_inspect_build_p_btn")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                app.deferPermission()
            } label: {
                Image("home_inspect_build_p_btn2")
                    .resizable()
                    .frame(width: 250, height: 35)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image(geometry.size.width > geometry.size.height ? "home_inspect_build_w_bg_l" : "home_inspect_build_w_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 10)
                    .opacity(0.7)
                
                Image("home_inspect_build_w_a")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
