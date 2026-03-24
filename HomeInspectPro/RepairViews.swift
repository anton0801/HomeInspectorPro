import SwiftUI

// MARK: - Repairs List View
struct RepairsView: View {
    @EnvironmentObject private var repairsVM:   RepairsViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel

    @State private var showAdd = false
    @State private var searchText = ""
    @State private var filterStatus: RepairStatus? = nil
    @State private var selectedRepair: Repair? = nil
    @State private var selectedTab: RepairsTab = .repairs

    enum RepairsTab: String, CaseIterable {
        case repairs  = "Repairs"
        case schedule = "Schedule"
        case tasks    = "Tasks"
    }

    var filtered: [Repair] {
        var list = repairsVM.repairs
        if !searchText.isEmpty {
            list = list.filter {
                $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
                || $0.buildingName.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let s = filterStatus { list = list.filter { $0.status == s } }
        return list
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Repairs").font(.hpTitle()).foregroundColor(.hpTextPrimary)
                                Text("\(repairsVM.repairs.count) total · \(repairsVM.upcoming.count) upcoming")
                                    .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                            }
                            Spacer()
                            Button(action: { showAdd = true }) {
                                ZStack {
                                    Circle().fill(LinearGradient.hpAccentGrad).frame(width: 42, height: 42)
                                    Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                }
                            }
                            .pressScale()
                        }

                        // Tab selector
                        HStack(spacing: 8) {
                            ForEach(RepairsTab.allCases, id: \.self) { tab in
                                Button(action: { withAnimation(.hpFast) { selectedTab = tab } }) {
                                    Text(tab.rawValue)
                                        .font(.hpBodySemi())
                                        .foregroundColor(selectedTab == tab ? .white : .hpTextSecondary)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(selectedTab == tab ? Color.hpAccent : Color.hpCard)
                                        .cornerRadius(20)
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                    switch selectedTab {
                    case .repairs:  RepairsListTab(filtered: filtered, filterStatus: $filterStatus,
                                                   searchText: $searchText, selectedRepair: $selectedRepair)
                    case .schedule: ScheduleTabView()
                    case .tasks:    TasksTabView()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddRepairView() }
            .sheet(item: $selectedRepair) { repair in RepairDetailView(repair: repair) }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Repairs List Tab
struct RepairsListTab: View {
    let filtered: [Repair]
    @Binding var filterStatus: RepairStatus?
    @Binding var searchText: String
    @Binding var selectedRepair: Repair?
    @EnvironmentObject private var repairsVM: RepairsViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM: AppViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Cost summary
            HStack(spacing: 10) {
                CostBadge(label: "Completed", value: repairsVM.totalCost, color: .hpSuccess)
                CostBadge(label: "Planned", value: repairsVM.plannedCost, color: .hpBlue)
            }
            .padding(.horizontal, 20)

            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: filterStatus == nil) { filterStatus = nil }
                    ForEach(RepairStatus.allCases, id: \.self) { s in
                        FilterChip(title: s.rawValue, color: s.color, isSelected: filterStatus == s) {
                            filterStatus = filterStatus == s ? nil : s
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            HPSearchBar(text: $searchText).padding(.horizontal, 20)
        }

        if filtered.isEmpty {
            HPEmptyState(icon: "wrench.and.screwdriver", title: "No Repairs",
                         message: "Plan and track all your building repairs here.",
                         actionTitle: "Add Repair", action: {})
            .padding(.top, 20)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(filtered) { repair in
                        RepairCard(repair: repair)
                            .onTapGesture { selectedRepair = repair }
                            .contextMenu {
                                if repair.status != .completed {
                                    Button {
                                        repairsVM.complete(repair)
                                        activityVM.log(type: .repairCompleted,
                                                       description: "Completed \(repair.type.rawValue) at \(repair.buildingName)")
                                        appVM.showSuccessToast("Repair marked complete!")
                                    } label: { Label("Mark Complete", systemImage: "checkmark.circle") }
                                }
                                Button(role: .destructive) {
                                    repairsVM.delete(repair)
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 100).padding(.top, 4)
            }
        }
    }
}

struct CostBadge: View {
    let label: String
    let value: Double
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text("$\(Int(value))")
                .font(.hpBodySemi()).foregroundColor(color)
            Text(label).font(.hpCaption2()).foregroundColor(.hpTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Repair Card
struct RepairCard: View {
    let repair: Repair
    var completedTasks: Int { repair.tasks.filter(\.isCompleted).count }
    var progress: Double { repair.tasks.isEmpty ? 0 : Double(completedTasks) / Double(repair.tasks.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(repair.status.color.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: repair.type.icon)
                        .font(.system(size: 22)).foregroundColor(repair.status.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(repair.type.rawValue).font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                    Text(repair.buildingName).font(.hpCaption()).foregroundColor(.hpTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Int(repair.cost))")
                        .font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                    HPBadge(text: repair.status.rawValue, color: repair.status.color)
                }
            }

            if !repair.tasks.isEmpty {
                VStack(spacing: 6) {
                    HStack {
                        Text("Progress").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                        Spacer()
                        Text("\(completedTasks)/\(repair.tasks.count) tasks")
                            .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                    }
                    HPProgressBar(value: progress, color: repair.status.color)
                }
            }

            HStack {
                Label(repair.scheduledDate.dayMonthFormatted, systemImage: "calendar")
                    .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                Spacer()
                if !repair.contractor.isEmpty {
                    Label(repair.contractor, systemImage: "person.fill")
                        .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                }
            }
        }
        .hpCard()
    }
}

// MARK: - Schedule Tab
struct ScheduleTabView: View {
    @EnvironmentObject private var repairsVM: RepairsViewModel
    @State private var selectedMonth = Date()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Month picker
                HStack {
                    Button(action: { selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth }) {
                        Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).foregroundColor(.hpBlue)
                    }
                    Spacer()
                    Text(monthYearString(selectedMonth))
                        .font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                    Spacer()
                    Button(action: { selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth }) {
                        Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundColor(.hpBlue)
                    }
                }
                .hpCard(16)

                // Calendar grid
                CalendarGrid(month: selectedMonth, repairs: repairsVM.repairs)

                // Upcoming list for this month
                let monthRepairs = repairsVM.repairs.filter { Calendar.current.isDate($0.scheduledDate, equalTo: selectedMonth, toGranularity: .month) }
                if !monthRepairs.isEmpty {
                    HPSectionHeader(title: "This Month (\(monthRepairs.count))")
                    ForEach(monthRepairs) { repair in
                        ScheduleRepairRow(repair: repair)
                    }
                } else {
                    HPEmptyState(icon: "calendar", title: "No Repairs This Month",
                                 message: "No repairs scheduled for this month.")
                }
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
}

struct CalendarGrid: View {
    let month: Date
    let repairs: [Repair]

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var daysInMonth: [Date?] {
        var days: [Date?] = []
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: month)
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDay) else { return [] }
        let weekday = cal.component(.weekday, from: firstDay)
        for _ in 1..<weekday { days.append(nil) }
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        return days
    }

    func hasRepair(on date: Date) -> Bool {
        repairs.contains { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.hpCaption()).foregroundColor(.hpTextSecondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        let day = Calendar.current.component(.day, from: date)
                        let isToday = Calendar.current.isDateInToday(date)
                        let hasR = hasRepair(on: date)
                        ZStack {
                            Circle()
                                .fill(isToday ? Color.hpBlue : (hasR ? Color.hpAccent.opacity(0.2) : Color.clear))
                                .frame(width: 32, height: 32)
                            Text("\(day)")
                                .font(.system(size: 13, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundColor(isToday ? .white : (hasR ? .hpAccent : .hpTextPrimary))
                            if hasR && !isToday {
                                Circle().fill(Color.hpAccent).frame(width: 4, height: 4)
                                    .offset(y: 10)
                            }
                        }
                        .frame(height: 36)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .hpCard()
    }
}

struct ScheduleRepairRow: View {
    let repair: Repair
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(repair.scheduledDate.dayMonthFormatted.split(separator: " ").first.map(String.init) ?? "")
                    .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                Text(repair.scheduledDate.dayMonthFormatted.split(separator: " ").last.map(String.init) ?? "")
                    .font(.hpHeadline()).foregroundColor(.hpTextPrimary)
            }
            .frame(width: 44)

            Rectangle().fill(repair.status.color).frame(width: 3).cornerRadius(2)

            VStack(alignment: .leading, spacing: 3) {
                Text(repair.type.rawValue).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Text(repair.buildingName).font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            Spacer()
            HPBadge(text: repair.status.rawValue, color: repair.status.color)
        }
        .hpCard(14)
    }
}

// MARK: - Tasks Tab
struct TasksTabView: View {
    @EnvironmentObject private var repairsVM: RepairsViewModel
    @EnvironmentObject private var appVM: AppViewModel
    @State private var showAddTask = false
    @State private var selectedRepairForTask: Repair? = nil
    @State private var filterCompleted = false

    var displayedTasks: [(repair: Repair, task: RepairTask)] {
        repairsVM.repairs.flatMap { repair in
            repair.tasks
                .filter { filterCompleted ? true : !$0.isCompleted }
                .map { (repair: repair, task: $0) }
        }
        .sorted { $0.task.priority.rawValue > $1.task.priority.rawValue }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tasks (\(displayedTasks.count))")
                    .font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                Spacer()
                Toggle("Show Completed", isOn: $filterCompleted)
                    .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                    .toggleStyle(SwitchToggleStyle(tint: .hpBlue))
                    .labelsHidden()
                Text(filterCompleted ? "All" : "Pending")
                    .font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            .padding(.horizontal, 20)
        }

        if displayedTasks.isEmpty {
            HPEmptyState(icon: "checkmark.square", title: "No Tasks",
                         message: filterCompleted ? "No tasks found." : "All tasks are completed!")
            .padding(.top, 20)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(displayedTasks, id: \.task.id) { item in
                        TaskRow(task: item.task, repair: item.repair) {
                            repairsVM.toggleTask(item.task, in: item.repair)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 100).padding(.top, 8)
            }
        }
    }
}

struct TaskRow: View {
    let task: RepairTask
    let repair: Repair
    let onToggle: () -> Void
    @EnvironmentObject private var repairsVM: RepairsViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.hpSuccess : Color.hpBorder, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if task.isCompleted {
                        Circle().fill(Color.hpSuccess).frame(width: 20, height: 20)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.hpBodySemi())
                    .foregroundColor(task.isCompleted ? .hpTextSecondary : .hpTextPrimary)
                    .strikethrough(task.isCompleted)
                HStack(spacing: 6) {
                    Text(repair.buildingName).font(.hpCaption()).foregroundColor(.hpTextSecondary)
                    if let due = task.dueDate {
                        Text("·").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                        Text(due.dayMonthFormatted).font(.hpCaption()).foregroundColor(.hpAccent)
                    }
                }
            }
            Spacer()
            Circle().fill(task.priority.color).frame(width: 8, height: 8)
        }
        .hpCard(14)
        .contextMenu {
            Button(role: .destructive) {
                repairsVM.deleteTask(task, from: repair)
            } label: { Label("Delete Task", systemImage: "trash") }
        }
    }
}

// MARK: - Add Repair View
struct AddRepairView: View {
    @EnvironmentObject private var repairsVM:   RepairsViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var type: RepairType = .structural
    @State private var description = ""
    @State private var cost = ""
    @State private var scheduledDate = Date()
    @State private var contractor = ""
    @State private var selectedBuilding: Building? = nil
    @State private var buildingError: String? = nil
    @State private var descriptionError: String? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color.hpAccent.opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "wrench.and.screwdriver.fill").font(.system(size: 32)).foregroundColor(.hpAccent)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 16) {
                        // Building
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BUILDING").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                            Menu {
                                if buildingsVM.buildings.isEmpty { Text("No buildings") }
                                else {
                                    ForEach(buildingsVM.buildings) { b in
                                        Button(b.name) { selectedBuilding = b; buildingError = nil }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "building.2").foregroundColor(.hpBlue)
                                    Text(selectedBuilding?.name ?? "Select Building")
                                        .font(.hpBody())
                                        .foregroundColor(selectedBuilding == nil ? .hpTextSecondary : .hpTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down").font(.system(size: 13)).foregroundColor(.hpTextSecondary)
                                }
                                .padding(14).background(Color.hpBackground).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(buildingError != nil ? Color.hpDanger : Color.hpBorder, lineWidth: 1))
                            }
                            if let e = buildingError { Text(e).font(.hpCaption2()).foregroundColor(.hpDanger) }
                        }

                        HPPickerRow(title: "Repair Type", selection: $type, icon: "wrench.fill")
                        HPTextField(title: "Description", text: $description,
                                    placeholder: "Describe the repair needed...",
                                    icon: "text.alignleft", errorMessage: descriptionError)
                            .onChange(of: description) { _ in descriptionError = nil }
                        HPTextField(title: "Estimated Cost ($)", text: $cost,
                                    placeholder: "0.00", icon: "dollarsign.circle",
                                    keyboardType: .decimalPad)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("SCHEDULED DATE").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                            DatePicker("", selection: $scheduledDate, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(14).background(Color.hpBackground).cornerRadius(12)
                        }

                        HPTextField(title: "Contractor (optional)", text: $contractor,
                                    placeholder: "e.g. Smith Construction", icon: "person.fill")
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Schedule Repair", icon: "wrench.fill", style: .accent,
                             isLoading: isLoading) { save() }
                        .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Repair", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        var valid = true
        if selectedBuilding == nil { buildingError = "Select a building"; valid = false }
        if description.trimmingCharacters(in: .whitespaces).isEmpty { descriptionError = "Description required"; valid = false }
        guard valid, let building = selectedBuilding else { return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            repairsVM.add(type: type, description: description, cost: Double(cost) ?? 0,
                          scheduledDate: scheduledDate, buildingId: building.id,
                          buildingName: building.name, contractor: contractor)
            activityVM.log(type: .repairAdded, description: "Planned \(type.rawValue) repair for \(building.name)")
            activityVM.addNotification(title: "Repair Scheduled",
                                       body: "\(type.rawValue) repair for \(building.name) on \(scheduledDate.dayMonthFormatted).",
                                       type: .repairNeeded)
            appVM.showSuccessToast("Repair scheduled!")
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Repair Detail View
struct RepairDetailView: View {
    @State var repair: Repair
    @EnvironmentObject private var repairsVM:  RepairsViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM:      AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Date()
    @State private var newTaskPriority: TaskPriority = .medium
    @State private var showTaskForm = false

    var currentRepair: Repair {
        repairsVM.repairs.first { $0.id == repair.id } ?? repair
    }

    var progress: Double {
        let tasks = currentRepair.tasks
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.isCompleted).count) / Double(tasks.count)
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [currentRepair.status.color, currentRepair.status.color.opacity(0.6)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 130)
                        HStack(spacing: 16) {
                            Image(systemName: currentRepair.type.icon).font(.system(size: 42, weight: .bold)).foregroundColor(.white)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentRepair.type.rawValue).font(.hpTitle2()).foregroundColor(.white)
                                HPBadge(text: currentRepair.status.rawValue, color: .white.opacity(0.3))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.horizontal, 20)

                    // Details
                    VStack(spacing: 12) {
                        DetailRow(label: "Building",  value: currentRepair.buildingName, icon: "building.2.fill")
                        DetailRow(label: "Type",      value: currentRepair.type.rawValue, icon: "wrench.fill")
                        DetailRow(label: "Cost",      value: "$\(Int(currentRepair.cost))", icon: "dollarsign.circle.fill")
                        DetailRow(label: "Scheduled", value: currentRepair.scheduledDate.shortFormatted, icon: "calendar")
                        if !currentRepair.contractor.isEmpty {
                            DetailRow(label: "Contractor", value: currentRepair.contractor, icon: "person.fill")
                        }
                        if !currentRepair.description.isEmpty {
                            DetailRow(label: "Description", value: currentRepair.description, icon: "text.alignleft")
                        }
                    }
                    .hpCard()
                    .padding(.horizontal, 20)

                    // Progress
                    if !currentRepair.tasks.isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Progress").font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                                Spacer()
                                Text("\(Int(progress * 100))%").font(.hpBodySemi()).foregroundColor(currentRepair.status.color)
                            }
                            HPProgressBar(value: progress, color: currentRepair.status.color, height: 10)
                        }
                        .hpCard()
                        .padding(.horizontal, 20)
                    }

                    // Tasks section
                    VStack(spacing: 12) {
                        HStack {
                            Text("Tasks (\(currentRepair.tasks.count))")
                                .font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                            Spacer()
                            Button(action: { showTaskForm.toggle() }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.hpAccent)
                            }
                        }
                        .padding(.horizontal, 20)

                        if showTaskForm {
                            AddTaskForm(title: $newTaskTitle, dueDate: $newTaskDueDate,
                                        priority: $newTaskPriority) {
                                if !newTaskTitle.isEmpty {
                                    repairsVM.addTask(to: currentRepair, title: newTaskTitle,
                                                      dueDate: newTaskDueDate, priority: newTaskPriority)
                                    newTaskTitle = ""
                                    showTaskForm = false
                                    appVM.showSuccessToast("Task added!")
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        ForEach(currentRepair.tasks) { task in
                            TaskRow(task: task, repair: currentRepair) {
                                repairsVM.toggleTask(task, in: currentRepair)
                            }
                            .padding(.horizontal, 20)
                        }

                        if currentRepair.tasks.isEmpty {
                            Text("No tasks yet — tap + to add")
                                .font(.hpCaption())
                                .foregroundColor(.hpTextSecondary)
                                .padding(.horizontal, 20)
                        }
                    }

                    // Actions
                    if currentRepair.status != .completed {
                        HPButton(title: "Mark as Completed", icon: "checkmark.seal.fill", style: .primary) {
                            repairsVM.complete(currentRepair)
                            activityVM.log(type: .repairCompleted,
                                           description: "Completed \(currentRepair.type.rawValue) at \(currentRepair.buildingName)")
                            appVM.showSuccessToast("Repair completed!")
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.horizontal, 20)
                    }

                    HPButton(title: "Delete Repair", icon: "trash", style: .destructive) {
                        repairsVM.delete(currentRepair)
                        appVM.showSuccessToast("Repair deleted")
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 20)
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Repair Details", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
    }
}

struct AddTaskForm: View {
    @Binding var title: String
    @Binding var dueDate: Date
    @Binding var priority: TaskPriority
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HPTextField(title: "Task Title", text: $title,
                        placeholder: "e.g. Order materials", icon: "checkmark.square")
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DUE DATE").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                    DatePicker("", selection: $dueDate, displayedComponents: [.date])
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding(12).background(Color.hpBackground).cornerRadius(10)
                }
                HPPickerRow(title: "Priority", selection: $priority, icon: "flag.fill")
            }
            HPButton(title: "Add Task", icon: "plus", style: .accent, isFullWidth: false, action: onSave)
        }
        .hpCard()
    }
}
