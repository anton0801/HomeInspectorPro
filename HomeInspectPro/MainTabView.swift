import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    @State private var tabBarOffset: CGFloat = 0

    enum Tab: Int, CaseIterable {
        case dashboard, buildings, inspections, repairs, settings

        var title: String {
            switch self {
            case .dashboard:   return "Dashboard"
            case .buildings:   return "Buildings"
            case .inspections: return "Inspections"
            case .repairs:     return "Repairs"
            case .settings:    return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard:   return "square.grid.2x2.fill"
            case .buildings:   return "building.2.fill"
            case .inspections: return "magnifyingglass.circle.fill"
            case .repairs:     return "wrench.and.screwdriver.fill"
            case .settings:    return "gearshape.fill"
            }
        }

        var activeColor: Color {
            switch self {
            case .dashboard:   return .hpBlue
            case .buildings:   return .hpNavy
            case .inspections: return Color(hex: "#AF52DE")
            case .repairs:     return .hpAccent
            case .settings:    return .hpTextSecondary
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .dashboard:   DashboardView()
                case .buildings:   BuildingsView()
                case .inspections: InspectionsView()
                case .repairs:     RepairsView()
                case .settings:    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            HPTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar
struct HPTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @EnvironmentObject private var activityVM: ActivityViewModel
    @State private var scaleValues: [CGFloat] = Array(repeating: 1, count: 5)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.rawValue) { tab in
                Spacer()
                Button(action: { selectTab(tab) }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab ? .bold : .regular))
                                .foregroundColor(selectedTab == tab ? tab.activeColor : Color.hpTextSecondary)
                                .frame(width: 28, height: 28)

                            // Notification badge for dashboard
                            if tab == .dashboard && activityVM.unreadCount > 0 {
                                ZStack {
                                    Circle().fill(Color.hpDanger).frame(width: 14, height: 14)
                                    Text(activityVM.unreadCount > 9 ? "9+" : "\(activityVM.unreadCount)")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 8, y: -6)
                            }
                        }

                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular, design: .rounded))
                            .foregroundColor(selectedTab == tab ? tab.activeColor : Color.hpTextSecondary)
                    }
                    .scaleEffect(scaleValues[tab.rawValue])
                }
                Spacer()
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(
            Color.hpCard
                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func selectTab(_ tab: MainTabView.Tab) {
        withAnimation(.hpSpring) {
            scaleValues[tab.rawValue] = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.hpSpring) {
                scaleValues[tab.rawValue] = 1.0
                selectedTab = tab
            }
        }
    }
}
