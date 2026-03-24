import SwiftUI

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var inspVM:      InspectionsViewModel
    @EnvironmentObject private var repairsVM:   RepairsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel

    @State private var selectedBuilding: Building? = nil
    @State private var showActivityHistory = false

    var avgCondition: Double {
        guard !buildingsVM.buildings.isEmpty else { return 0 }
        return buildingsVM.buildings.map(\.conditionScore).reduce(0, +) / Double(buildingsVM.buildings.count)
    }

    var issuesByType: [(type: IssueType, count: Int)] {
        IssueType.allCases.compactMap { type in
            let count = issuesVM.issues.filter { $0.type == type }.count
            return count > 0 ? (type, count) : nil
        }.sorted { $0.count > $1.count }
    }

    var issuesBySeverity: [(severity: IssueSeverity, count: Int)] {
        IssueSeverity.allCases.map { severity in
            (severity, issuesVM.issues.filter { $0.severity == severity }.count)
        }
    }

    var repairsByStatus: [(status: RepairStatus, count: Int)] {
        RepairStatus.allCases.map { status in
            (status, repairsVM.repairs.filter { $0.status == status }.count)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reports").font(.hpTitle()).foregroundColor(.hpTextPrimary)
                                Text("Analytics & Insights").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                            }
                            Spacer()
                            Button(action: { showActivityHistory = true }) {
                                ZStack {
                                    Circle().fill(Color.hpCard).frame(width: 42, height: 42)
                                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 17)).foregroundColor(.hpBlue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Portfolio overview
                        PortfolioOverviewCard(
                            buildingCount: buildingsVM.buildings.count,
                            avgCondition: avgCondition,
                            openIssues: issuesVM.openIssues.count,
                            totalInspections: inspVM.inspections.count,
                            completedRepairs: repairsVM.repairs.filter { $0.status == .completed }.count,
                            totalCost: repairsVM.totalCost
                        )
                        .padding(.horizontal, 20)

                        // Condition by building
                        if !buildingsVM.buildings.isEmpty {
                            VStack(spacing: 12) {
                                HPSectionHeader(title: "Building Conditions")
                                    .padding(.horizontal, 20)
                                ForEach(buildingsVM.buildings) { building in
                                    BuildingConditionRow(building: building,
                                        issueCount: issuesVM.issues(for: building.id).filter { $0.status != .resolved }.count)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Issues breakdown
                        if !issuesVM.issues.isEmpty {
                            VStack(spacing: 12) {
                                HPSectionHeader(title: "Issues Breakdown")
                                    .padding(.horizontal, 20)

                                // By severity
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("By Severity").font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                                    ForEach(issuesBySeverity, id: \.severity) { item in
                                        IssueBreakdownRow(
                                            label: item.severity.rawValue,
                                            count: item.count,
                                            total: issuesVM.issues.count,
                                            color: item.severity.color
                                        )
                                    }
                                }
                                .hpCard()
                                .padding(.horizontal, 20)

                                // By type
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("By Type").font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                                    ForEach(issuesByType.prefix(5), id: \.type) { item in
                                        IssueBreakdownRow(
                                            label: item.type.rawValue,
                                            count: item.count,
                                            total: issuesVM.issues.count,
                                            color: .hpBlue
                                        )
                                    }
                                }
                                .hpCard()
                                .padding(.horizontal, 20)
                            }
                        }

                        // Repairs cost overview
                        if !repairsVM.repairs.isEmpty {
                            VStack(spacing: 12) {
                                HPSectionHeader(title: "Repair Costs")
                                    .padding(.horizontal, 20)
                                RepairCostCard(
                                    planned: repairsVM.plannedCost,
                                    completed: repairsVM.totalCost,
                                    inProgress: repairsVM.repairs.filter { $0.status == .inProgress }.map(\.cost).reduce(0, +)
                                )
                                .padding(.horizontal, 20)
                            }
                        }

                        // Inspection history chart
                        if !inspVM.inspections.isEmpty {
                            VStack(spacing: 12) {
                                HPSectionHeader(title: "Inspection Results")
                                    .padding(.horizontal, 20)
                                InspectionResultsCard(inspections: inspVM.inspections)
                                    .padding(.horizontal, 20)
                            }
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showActivityHistory) { ActivityHistoryView() }
        }
    }
}

// MARK: - Portfolio Overview Card
struct PortfolioOverviewCard: View {
    let buildingCount: Int
    let avgCondition: Double
    let openIssues: Int
    let totalInspections: Int
    let completedRepairs: Int
    let totalCost: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(LinearGradient.hpPrimary).frame(width: 72, height: 72)
                    VStack(spacing: 2) {
                        Text("\(Int(avgCondition))")
                            .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Text("Score").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.8))
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Portfolio Health").font(.hpTitle3()).foregroundColor(.hpTextPrimary)
                    HPProgressBar(value: avgCondition / 100, color: avgCondition.conditionColor, height: 8)
                    Text("\(buildingCount) building\(buildingCount == 1 ? "" : "s") monitored")
                        .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                }
            }

            HPDivider()

            HStack {
                ReportStat(value: "\(openIssues)",       label: "Open Issues",   color: openIssues > 0 ? .hpDanger : .hpSuccess)
                Divider().frame(height: 30)
                ReportStat(value: "\(totalInspections)", label: "Inspections",   color: .hpBlue)
                Divider().frame(height: 30)
                ReportStat(value: "\(completedRepairs)", label: "Repairs Done",  color: .hpSuccess)
                Divider().frame(height: 30)
                ReportStat(value: "$\(Int(totalCost))",  label: "Spent",         color: .hpAccent)
            }
        }
        .hpCard()
    }
}

struct ReportStat: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.hpBodySemi()).foregroundColor(color)
            Text(label).font(.hpCaption2()).foregroundColor(.hpTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Building Condition Row
struct BuildingConditionRow: View {
    let building: Building
    let issueCount: Int

    var body: some View {
        HStack(spacing: 12) {
            ConditionRing(score: building.conditionScore, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(building.name).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                HStack(spacing: 6) {
                    Text("\(building.floorsCount) floors").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                    if issueCount > 0 {
                        Text("·").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                        Text("\(issueCount) issues").font(.hpCaption()).foregroundColor(.hpDanger)
                    }
                }
            }
            Spacer()
            HPProgressBar(value: building.conditionScore / 100, color: building.conditionScore.conditionColor)
                .frame(width: 80)
        }
        .hpCard(14)
    }
}

// MARK: - Issue Breakdown Row
struct IssueBreakdownRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    var fraction: Double { total > 0 ? Double(count) / Double(total) : 0 }

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.hpBody()).foregroundColor(.hpTextPrimary)
                .frame(width: 90, alignment: .leading)
            HPProgressBar(value: fraction, color: color)
            Text("\(count)")
                .font(.hpBodySemi()).foregroundColor(color)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

// MARK: - Repair Cost Card
struct RepairCostCard: View {
    let planned: Double
    let completed: Double
    let inProgress: Double

    var total: Double { planned + completed + inProgress }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Total Repair Spend").font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                    Text("All time").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                }
                Spacer()
                Text("$\(Int(total))")
                    .font(.hpTitle2()).foregroundColor(.hpTextPrimary)
            }
            HPDivider()
            VStack(spacing: 8) {
                CostRow(label: "Completed", value: completed, total: total, color: .hpSuccess)
                CostRow(label: "In Progress", value: inProgress, total: total, color: .hpWarning)
                CostRow(label: "Planned", value: planned, total: total, color: .hpBlue)
            }
        }
        .hpCard()
    }
}

struct CostRow: View {
    let label: String
    let value: Double
    let total: Double
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.hpBody()).foregroundColor(.hpTextPrimary)
            Spacer()
            Text("$\(Int(value))").font(.hpBodySemi()).foregroundColor(color)
            Text("(\(total > 0 ? Int(value/total*100) : 0)%)")
                .font(.hpCaption()).foregroundColor(.hpTextSecondary)
        }
    }
}

// MARK: - Inspection Results Card
struct InspectionResultsCard: View {
    let inspections: [Inspection]

    var passed:  Int { inspections.filter { $0.result == .passed  }.count }
    var warning: Int { inspections.filter { $0.result == .warning }.count }
    var failed:  Int { inspections.filter { $0.result == .failed  }.count }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Total Inspections").font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Spacer()
                Text("\(inspections.count)").font(.hpTitle2()).foregroundColor(.hpTextPrimary)
            }
            HPDivider()

            // Visual bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    let total = Double(inspections.count)
                    if passed > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.hpSuccess)
                            .frame(width: geo.size.width * Double(passed) / total)
                    }
                    if warning > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.hpWarning)
                            .frame(width: geo.size.width * Double(warning) / total)
                    }
                    if failed > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.hpDanger)
                            .frame(width: geo.size.width * Double(failed) / total)
                    }
                }
                .frame(height: 12)
            }
            .frame(height: 12)

            HStack(spacing: 16) {
                InspResultChip(label: "Passed",  count: passed,  color: .hpSuccess)
                InspResultChip(label: "Warning", count: warning, color: .hpWarning)
                InspResultChip(label: "Failed",  count: failed,  color: .hpDanger)
            }
        }
        .hpCard()
    }
}

struct InspResultChip: View {
    let label: String
    let count: Int
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(count) \(label)").font(.hpCaption()).foregroundColor(.hpTextSecondary)
        }
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @EnvironmentObject private var activityVM: ActivityViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""

    var filtered: [Activity] {
        searchText.isEmpty ? activityVM.activities
            : activityVM.activities.filter { $0.description.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    HPSearchBar(text: $searchText).padding(.horizontal, 20).padding(.vertical, 12)

                    if filtered.isEmpty {
                        HPEmptyState(icon: "clock.arrow.circlepath", title: "No Activity",
                                     message: "Actions you take in the app will appear here.")
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, activity in
                                    ActivityHistoryRow(activity: activity, isLast: idx == filtered.count - 1)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarTitle("Activity History", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
    }
}

struct ActivityHistoryRow: View {
    let activity: Activity
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(activity.type.color.opacity(0.12)).frame(width: 36, height: 36)
                    Image(systemName: activity.type.icon).font(.system(size: 14)).foregroundColor(activity.type.color)
                }
                if !isLast {
                    Rectangle().fill(Color.hpBorder).frame(width: 1).frame(minHeight: 20)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(activity.description).font(.hpBody()).foregroundColor(.hpTextPrimary)
                Text(activity.timestamp.relativeFormatted).font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
