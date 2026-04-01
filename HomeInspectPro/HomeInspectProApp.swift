import SwiftUI

@main
struct HomeInspectProApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegateApp

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

struct RootView: View {
    
    @StateObject private var appVM       = AppViewModel()
    @StateObject private var buildingsVM = BuildingsViewModel()
    @StateObject private var inspVM      = InspectionsViewModel()
    @StateObject private var issuesVM    = IssuesViewModel()
    @StateObject private var repairsVM   = RepairsViewModel()
    @StateObject private var materialsVM = MaterialsViewModel()
    @StateObject private var activityVM  = ActivityViewModel()

    var body: some View {
        ZStack {
            if !appVM.hasOnboarded {
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
        .animation(.hpSpring, value: appVM.hasOnboarded)
        .animation(.hpSpring, value: appVM.isLoggedIn)
        .preferredColorScheme(appVM.preferredColorScheme)
        .environmentObject(appVM)
        .environmentObject(buildingsVM)
        .environmentObject(inspVM)
        .environmentObject(issuesVM)
        .environmentObject(repairsVM)
        .environmentObject(materialsVM)
        .environmentObject(activityVM)
    }
}
