import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appVM:       AppViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var inspVM:      InspectionsViewModel
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var repairsVM:   RepairsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel

    @State private var showNotifications = false
    @State private var showProfile = false
    @State private var appear = false
    @State private var selectedQuickAction: QuickAction? = nil

    enum QuickAction: Identifiable {
        case addBuilding, addInspection, addIssue, addRepair
        var id: Self { self }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        DashboardHeader(
                            userName: appVM.currentUser?.name ?? "Inspector",
                            unreadCount: activityVM.unreadCount,
                            onNotification: { showNotifications = true },
                            onProfile: { showProfile = true }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Stat cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            HPStatCard(
                                title: "Buildings", value: "\(buildingsVM.buildings.count)",
                                subtitle: "Monitored", icon: "building.2.fill", color: .hpNavy
                            )
                            HPStatCard(
                                title: "Open Issues", value: "\(issuesVM.openIssues.count)",
                                subtitle: issuesVM.criticalIssues.isEmpty ? "All clear" : "\(issuesVM.criticalIssues.count) critical",
                                icon: "exclamationmark.triangle.fill",
                                color: issuesVM.openIssues.isEmpty ? .hpSuccess : .hpDanger
                            )
                            HPStatCard(
                                title: "Inspections", value: "\(inspVM.inspections.count)",
                                subtitle: "Total logged", icon: "magnifyingglass", color: Color(hex: "#AF52DE")
                            )
                            HPStatCard(
                                title: "Upcoming", value: "\(repairsVM.upcoming.count)",
                                subtitle: repairsVM.upcoming.isEmpty ? "No repairs" : "Repairs",
                                icon: "wrench.fill",
                                color: repairsVM.upcoming.isEmpty ? .hpSuccess : .hpAccent
                            )
                        }
                        .padding(.horizontal, 20)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                        // Condition overview (if buildings exist)
                        if !buildingsVM.buildings.isEmpty {
                            DashboardConditionSection(buildings: buildingsVM.buildings)
                                .padding(.horizontal, 20)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 20)
                        }

                        // Quick actions
                        VStack(spacing: 12) {
                            HPSectionHeader(title: "Quick Actions")
                                .padding(.horizontal, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(quickActions, id: \.title) { qa in
                                        QuickActionCard(item: qa) {
                                            selectedQuickAction = qa.action
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                        // Recent inspections
                        if !inspVM.recent.isEmpty {
                            VStack(spacing: 12) {
                                HPSectionHeader(title: "Recent Inspections")
                                    .padding(.horizontal, 20)
                                ForEach(inspVM.recent) { insp in
                                    DashboardInspectionRow(inspection: insp)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                        }

                        // Critical issues
                        if !issuesVM.criticalIssues.isEmpty {
                            VStack(spacing: 12) {
                                HPSectionHeader(title: "Critical Issues",
                                                actionTitle: "View All",
                                                action: {})
                                    .padding(.horizontal, 20)
                                ForEach(issuesVM.criticalIssues.prefix(3)) { issue in
                                    DashboardIssueRow(issue: issue)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .opacity(appear ? 1 : 0)
                        }

                        // Upcoming repairs
                        if !repairsVM.upcoming.isEmpty {
                            VStack(spacing: 12) {
                                HPSectionHeader(title: "Upcoming Repairs")
                                    .padding(.horizontal, 20)
                                ForEach(repairsVM.upcoming.prefix(3)) { repair in
                                    DashboardRepairRow(repair: repair)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .opacity(appear ? 1 : 0)
                        }

                        // Empty state
                        if buildingsVM.buildings.isEmpty {
                            DashboardEmptyState { selectedQuickAction = .addBuilding }
                                .padding(.horizontal, 20)
                        }

                        // Activity feed
                        if !activityVM.activities.isEmpty {
                            VStack(spacing: 12) {
                                HPSectionHeader(title: "Recent Activity")
                                    .padding(.horizontal, 20)
                                ForEach(activityVM.activities.prefix(5)) { activity in
                                    DashboardActivityRow(activity: activity)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .opacity(appear ? 1 : 0)
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotifications) { NotificationsView() }
            .sheet(isPresented: $showProfile)       { ProfileView() }
            .sheet(item: $selectedQuickAction) { action in
                switch action {
                case .addBuilding:   AddBuildingView()
                case .addInspection: AddInspectionView()
                case .addIssue:      AddIssueView()
                case .addRepair:     AddRepairView()
                }
            }
        }
        .onAppear {
            withAnimation(.hpSpring.delay(0.1)) { appear = true }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var quickActions: [(title: String, icon: String, color: Color, action: QuickAction)] {
        [
            ("Add Building",    "building.2.fill",              .hpNavy,   .addBuilding),
            ("Inspect",         "magnifyingglass.circle.fill",  Color(hex: "#AF52DE"), .addInspection),
            ("Log Issue",       "exclamationmark.triangle.fill", .hpDanger, .addIssue),
            ("Plan Repair",     "wrench.fill",                  .hpAccent, .addRepair)
        ]
    }
}

// MARK: - Dashboard Header
struct DashboardHeader: View {
    let userName: String
    let unreadCount: Int
    let onNotification: () -> Void
    let onProfile: () -> Void

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.hpBody())
                    .foregroundColor(.hpTextSecondary)
                Text(userName)
                    .font(.hpTitle2())
                    .foregroundColor(.hpTextPrimary)
            }
            Spacer()
            HStack(spacing: 10) {
                Button(action: onNotification) {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.hpCard)
                            .frame(width: 42, height: 42)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 17))
                            .foregroundColor(.hpTextPrimary)
                        if unreadCount > 0 {
                            Circle()
                                .fill(Color.hpDanger)
                                .frame(width: 10, height: 10)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                Button(action: onProfile) {
                    Circle()
                        .fill(LinearGradient.hpPrimary)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.hpBodySemi())
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.hpNavy.opacity(0.25), radius: 6, x: 0, y: 2)
                }
            }
        }
    }
}

// MARK: - Condition Section
struct DashboardConditionSection: View {
    let buildings: [Building]

    var avgCondition: Double {
        guard !buildings.isEmpty else { return 0 }
        return buildings.map(\.conditionScore).reduce(0, +) / Double(buildings.count)
    }

    var body: some View {
        VStack(spacing: 14) {
            HPSectionHeader(title: "Overall Condition")
            HStack(spacing: 16) {
                ConditionRing(score: avgCondition, size: 72)
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Portfolio Health")
                            .font(.hpCaption())
                            .foregroundColor(.hpTextSecondary)
                        Text(conditionLabel)
                            .font(.hpBodySemi())
                            .foregroundColor(avgCondition.conditionColor)
                    }
                    HPProgressBar(value: avgCondition / 100, color: avgCondition.conditionColor)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.hpCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    private var conditionLabel: String {
        switch avgCondition {
        case 80...100: return "Excellent"
        case 60..<80:  return "Good"
        case 40..<60:  return "Fair"
        case 20..<40:  return "Poor"
        default:       return "Critical"
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let item: (title: String, icon: String, color: Color, action: DashboardView.QuickAction)
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(item.color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(item.color)
                }
                Text(item.title)
                    .font(.hpCaption())
                    .foregroundColor(.hpTextPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color.hpCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .pressScale()
    }
}

// MARK: - Dashboard Rows
struct DashboardInspectionRow: View {
    let inspection: Inspection
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(inspection.result.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: inspection.result.icon)
                    .font(.system(size: 16))
                    .foregroundColor(inspection.result.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(inspection.buildingName)
                    .font(.hpBodySemi())
                    .foregroundColor(.hpTextPrimary)
                Text("Inspector: \(inspection.inspector)")
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(inspection.date.dayMonthFormatted)
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
                HPBadge(text: inspection.result.rawValue, color: inspection.result.color)
            }
        }
        .padding(14)
        .background(Color.hpCard)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct DashboardIssueRow: View {
    let issue: Issue
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(issue.severity.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: issue.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(issue.severity.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(issue.type.rawValue)
                    .font(.hpBodySemi())
                    .foregroundColor(.hpTextPrimary)
                Text(issue.location)
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
            }
            Spacer()
            HPSeverityBadge(severity: issue.severity)
        }
        .padding(14)
        .background(Color.hpCard)
        .cornerRadius(14)
        .shadow(color: issue.severity.color.opacity(0.12), radius: 6, x: 0, y: 2)
    }
}

struct DashboardRepairRow: View {
    let repair: Repair
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(repair.status.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: repair.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(repair.status.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(repair.type.rawValue)
                    .font(.hpBodySemi())
                    .foregroundColor(.hpTextPrimary)
                Text(repair.buildingName)
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(repair.scheduledDate.dayMonthFormatted)
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
                HPBadge(text: repair.status.rawValue, color: repair.status.color)
            }
        }
        .padding(14)
        .background(Color.hpCard)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct DashboardActivityRow: View {
    let activity: Activity
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: activity.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(activity.type.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.hpBody())
                    .foregroundColor(.hpTextPrimary)
                    .lineLimit(1)
                Text(activity.timestamp.relativeFormatted)
                    .font(.hpCaption2())
                    .foregroundColor(.hpTextSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State
struct DashboardEmptyState: View {
    let onAdd: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient.hpPrimary)
                    .frame(width: 100, height: 100)
                    .opacity(0.1)
                VStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.hpNavy.opacity(0.4))
                }
            }
            VStack(spacing: 8) {
                Text("No Buildings Yet")
                    .font(.hpTitle3())
                    .foregroundColor(.hpTextPrimary)
                Text("Add your first building to start monitoring its condition and tracking issues.")
                    .font(.hpBody())
                    .foregroundColor(.hpTextSecondary)
                    .multilineTextAlignment(.center)
            }
            HPButton(title: "Add Building", icon: "plus", style: .primary,
                     isFullWidth: false, action: onAdd)
        }
        .padding(32)
        .background(Color.hpCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
    }
}
