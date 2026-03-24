import SwiftUI

@main
struct HomeInspectProApp: App {
    @StateObject private var appVM       = AppViewModel()
    @StateObject private var buildingsVM = BuildingsViewModel()
    @StateObject private var inspVM      = InspectionsViewModel()
    @StateObject private var issuesVM    = IssuesViewModel()
    @StateObject private var repairsVM   = RepairsViewModel()
    @StateObject private var materialsVM = MaterialsViewModel()
    @StateObject private var activityVM  = ActivityViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appVM)
                .environmentObject(buildingsVM)
                .environmentObject(inspVM)
                .environmentObject(issuesVM)
                .environmentObject(repairsVM)
                .environmentObject(materialsVM)
                .environmentObject(activityVM)
                .preferredColorScheme(appVM.preferredColorScheme)
        }
    }
}

// MARK: - Root Routing View
struct RootView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !appVM.hasOnboarded {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)))
            } else if !appVM.isLoggedIn {
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)))
            } else {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity))
            }

            // Toast overlay
            if appVM.showToast {
                VStack {
                    Spacer()
                    HPToast(message: appVM.toastMessage, isError: appVM.toastIsError)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 90)
                }
                .animation(.hpSpring, value: appVM.showToast)
                .allowsHitTesting(false)
            }
        }
        .animation(.hpSpring, value: showSplash)
        .animation(.hpSpring, value: appVM.hasOnboarded)
        .animation(.hpSpring, value: appVM.isLoggedIn)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation { showSplash = false }
            }
        }
    }
}
