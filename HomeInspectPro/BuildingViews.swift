import SwiftUI

// MARK: - Buildings List View
struct BuildingsView: View {
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel

    @State private var showAdd = false
    @State private var searchText = ""
    @State private var selectedBuilding: Building? = nil
    @State private var appear = false

    var filtered: [Building] {
        searchText.isEmpty ? buildingsVM.buildings
            : buildingsVM.buildings.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.address.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Buildings")
                                    .font(.hpTitle())
                                    .foregroundColor(.hpTextPrimary)
                                Text("\(buildingsVM.buildings.count) properties monitored")
                                    .font(.hpCaption())
                                    .foregroundColor(.hpTextSecondary)
                            }
                            Spacer()
                            Button(action: { showAdd = true }) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.hpPrimary)
                                        .frame(width: 42, height: 42)
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .pressScale()
                        }
                        HPSearchBar(text: $searchText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    if filtered.isEmpty {
                        HPEmptyState(
                            icon: "building.2",
                            title: searchText.isEmpty ? "No Buildings" : "No Results",
                            message: searchText.isEmpty ? "Add your first building to start monitoring its condition." : "Try a different search term.",
                            actionTitle: searchText.isEmpty ? "Add Building" : nil,
                            action: searchText.isEmpty ? { showAdd = true } : nil
                        )
                        .padding(.top, 40)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(filtered) { building in
                                    BuildingCard(building: building,
                                                 issueCount: issuesVM.issues(for: building.id).filter { $0.status != .resolved }.count)
                                        .onTapGesture { selectedBuilding = building }
                                        .pressScale()
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                buildingsVM.delete(building)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) {
                AddBuildingView()
            }
            .background(
                NavigationLink(
                    destination: selectedBuilding.map { BuildingOverviewView(building: $0) },
                    isActive: Binding(
                        get: { selectedBuilding != nil },
                        set: { if !$0 { selectedBuilding = nil } }
                    )
                ) { EmptyView() }
            )
        }
        .onAppear { withAnimation(.hpSpring.delay(0.1)) { appear = true } }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Building Card
struct BuildingCard: View {
    let building: Building
    let issueCount: Int
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient.hpPrimary)
                        .frame(width: 52, height: 52)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.hpHeadline())
                        .foregroundColor(.hpTextPrimary)
                    if !building.address.isEmpty {
                        Text(building.address)
                            .font(.hpCaption())
                            .foregroundColor(.hpTextSecondary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 10) {
                        Label("\(building.floorsCount) Floors", systemImage: "square.stack.3d.up.fill")
                        if issueCount > 0 {
                            Label("\(issueCount) Issues", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.hpDanger)
                        }
                    }
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
                }
                Spacer()
                ConditionRing(score: building.conditionScore, size: 52)
            }

            // Condition bar
            VStack(spacing: 6) {
                HStack {
                    Text("Condition Score")
                        .font(.hpCaption())
                        .foregroundColor(.hpTextSecondary)
                    Spacer()
                    Text("\(Int(building.conditionScore))%")
                        .font(.hpCaption())
                        .foregroundColor(building.conditionScore.conditionColor)
                }
                HPProgressBar(value: building.conditionScore / 100,
                              color: building.conditionScore.conditionColor)
            }
        }
        .hpCard()
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.hpSpring.delay(0.05)) { appear = true }
        }
    }
}

// MARK: - Add Building View
struct AddBuildingView: View {
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var address = ""
    @State private var floorsCount = 1
    @State private var notes = ""
    @State private var nameError: String? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Illustration
                    ZStack {
                        Circle()
                            .fill(LinearGradient.hpPrimary)
                            .frame(width: 80, height: 80)
                            .opacity(0.15)
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.hpNavy)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 16) {
                        HPTextField(title: "Building Name", text: $name,
                                    placeholder: "e.g. Main Office Building",
                                    icon: "building.2",
                                    errorMessage: nameError)
                            .onChange(of: name) { _ in nameError = nil }

                        HPTextField(title: "Address", text: $address,
                                    placeholder: "e.g. 123 Main Street",
                                    icon: "mappin.circle")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NUMBER OF FLOORS")
                                .font(.hpCaption())
                                .foregroundColor(.hpTextSecondary)
                                .tracking(0.5)

                            HStack(spacing: 16) {
                                Button(action: { if floorsCount > 1 { floorsCount -= 1 } }) {
                                    ZStack {
                                        Circle().fill(Color.hpBackground).frame(width: 40, height: 40)
                                        Image(systemName: "minus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(floorsCount > 1 ? .hpNavy : .hpBorder)
                                    }
                                }
                                .disabled(floorsCount <= 1)

                                Text("\(floorsCount)")
                                    .font(.hpNumeric())
                                    .foregroundColor(.hpTextPrimary)
                                    .frame(minWidth: 40)

                                Button(action: { if floorsCount < 50 { floorsCount += 1 } }) {
                                    ZStack {
                                        Circle().fill(LinearGradient.hpPrimary).frame(width: 40, height: 40)
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                Spacer()

                                Stepper("", value: $floorsCount, in: 1...50)
                                    .labelsHidden()
                            }
                            .padding(14)
                            .background(Color.hpBackground)
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES (OPTIONAL)")
                                .font(.hpCaption())
                                .foregroundColor(.hpTextSecondary)
                                .tracking(0.5)
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.hpBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.hpBorder, lineWidth: 1)
                                    )
                                TextEditor(text: $notes)
                                    .font(.hpBody())
                                    .foregroundColor(.hpTextPrimary)
                                    .padding(12)
                                    .frame(minHeight: 80)
                                if notes.isEmpty {
                                    Text("Add any notes about this building...")
                                        .font(.hpBody())
                                        .foregroundColor(.hpTextSecondary.opacity(0.6))
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Add Building", icon: "plus.circle.fill", style: .primary,
                             isLoading: isLoading) {
                        save()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Building", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            nameError = "Building name is required"; return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            buildingsVM.add(name: name, address: address, floorsCount: floorsCount, notes: notes)
            activityVM.log(type: .buildingAdded, description: "Added building: \(name)")
            activityVM.addNotification(title: "Building Added",
                                       body: "\(name) has been added to your portfolio.",
                                       type: .inspectionDue)
            appVM.showSuccessToast("Building added!")
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Building Overview
struct BuildingOverviewView: View {
    let building: Building
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var inspVM:      InspectionsViewModel
    @EnvironmentObject private var repairsVM:   RepairsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel

    @State private var showAddFloor = false
    @State private var selectedFloor: Floor? = nil
    @State private var tab: OverviewTab = .floors

    enum OverviewTab: String, CaseIterable {
        case floors = "Floors"
        case issues = "Issues"
        case inspections = "Inspections"
        case repairs = "Repairs"
    }

    var currentBuilding: Building {
        buildingsVM.buildings.first { $0.id == building.id } ?? building
    }

    var body: some View {
        ZStack {
            Color.hpBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header card
                    BuildingHeaderCard(building: currentBuilding,
                                       issueCount: issuesVM.issues(for: building.id).filter { $0.status != .resolved }.count,
                                       inspCount: inspVM.inspections(for: building.id).count)
                        .padding(.horizontal, 20)

                    // Tab selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(OverviewTab.allCases, id: \.self) { t in
                                Button(action: { withAnimation(.hpFast) { tab = t } }) {
                                    Text(t.rawValue)
                                        .font(.hpBodySemi())
                                        .foregroundColor(tab == t ? .white : .hpTextSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(tab == t ? Color.hpBlue : Color.hpCard)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Tab content
                    switch tab {
                    case .floors:
                        FloorsTabContent(building: currentBuilding,
                                         onAddFloor: { showAddFloor = true },
                                         onSelectFloor: { selectedFloor = $0 })
                    case .issues:
                        IssuesTabContent(issues: issuesVM.issues(for: building.id))
                    case .inspections:
                        InspectionsTabContent(inspections: inspVM.inspections(for: building.id))
                    case .repairs:
                        RepairsTabContent(repairs: repairsVM.repairs(for: building.id))
                    }

                    Color.clear.frame(height: 100)
                }
                .padding(.top, 8)
            }
        }
        .navigationBarTitle(building.name, displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: { showAddFloor = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.hpBlue)
            }
        )
        .sheet(isPresented: $showAddFloor) {
            AddFloorView(building: currentBuilding)
        }
        .background(
            NavigationLink(
                destination: selectedFloor.map { FloorDetailView(floor: $0, building: currentBuilding) },
                isActive: Binding(get: { selectedFloor != nil }, set: { if !$0 { selectedFloor = nil } })
            ) { EmptyView() }
        )
    }
}

struct BuildingHeaderCard: View {
    let building: Building
    let issueCount: Int
    let inspCount: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient.hpPrimary)
                        .frame(width: 64, height: 64)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.hpTitle3())
                        .foregroundColor(.hpTextPrimary)
                    if !building.address.isEmpty {
                        Text(building.address)
                            .font(.hpCaption())
                            .foregroundColor(.hpTextSecondary)
                    }
                    HStack(spacing: 4) {
                        Text("Added \(building.createdAt.dayMonthFormatted)")
                            .font(.hpCaption2())
                            .foregroundColor(.hpTextSecondary)
                    }
                }
                Spacer()
                ConditionRing(score: building.conditionScore, size: 60)
            }
            HPDivider()
            HStack {
                OverviewStat(value: "\(building.floorsCount)", label: "Floors", icon: "square.stack.3d.up")
                Divider().frame(height: 30)
                OverviewStat(value: "\(building.floors.flatMap(\.rooms).count)", label: "Rooms", icon: "door.left.hand.open")
                Divider().frame(height: 30)
                OverviewStat(value: "\(issueCount)", label: "Issues", icon: "exclamationmark.triangle",
                             color: issueCount > 0 ? .hpDanger : .hpSuccess)
                Divider().frame(height: 30)
                OverviewStat(value: "\(inspCount)", label: "Inspections", icon: "magnifyingglass")
            }
        }
        .hpCard()
    }
}

struct OverviewStat: View {
    let value: String
    let label: String
    let icon: String
    var color: Color = .hpBlue

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.hpTitle3())
                .foregroundColor(.hpTextPrimary)
            Text(label)
                .font(.hpCaption2())
                .foregroundColor(.hpTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Contents inside Overview
struct FloorsTabContent: View {
    let building: Building
    let onAddFloor: () -> Void
    let onSelectFloor: (Floor) -> Void
    @EnvironmentObject private var buildingsVM: BuildingsViewModel

    var body: some View {
        VStack(spacing: 12) {
            HPSectionHeader(title: "Floors", actionTitle: "+ Add Floor", action: onAddFloor)
                .padding(.horizontal, 20)

            if building.floors.isEmpty {
                HPEmptyState(icon: "square.stack.3d.up", title: "No Floors",
                             message: "Add floors to organize rooms and structures.",
                             actionTitle: "Add Floor", action: onAddFloor)
            } else {
                ForEach(building.floors) { floor in
                    FloorRow(floor: floor, roomCount: floor.rooms.count)
                        .padding(.horizontal, 20)
                        .onTapGesture { onSelectFloor(floor) }
                        .contextMenu {
                            Button(role: .destructive) {
                                buildingsVM.deleteFloor(floor, from: building)
                            } label: {
                                Label("Delete Floor", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

struct FloorRow: View {
    let floor: Floor
    let roomCount: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.hpBlue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text("\(floor.level)")
                    .font(.hpHeadline())
                    .foregroundColor(.hpBlue)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(floor.name)
                    .font(.hpBodySemi())
                    .foregroundColor(.hpTextPrimary)
                Text("\(roomCount) room\(roomCount == 1 ? "" : "s")")
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.hpTextSecondary)
        }
        .hpCard(14)
    }
}

struct IssuesTabContent: View {
    let issues: [Issue]
    var body: some View {
        VStack(spacing: 12) {
            HPSectionHeader(title: "Issues (\(issues.count))")
                .padding(.horizontal, 20)
            if issues.isEmpty {
                HPEmptyState(icon: "checkmark.shield", title: "No Issues",
                             message: "No issues recorded for this building.")
            } else {
                ForEach(issues) { issue in
                    IssueRowCard(issue: issue)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct InspectionsTabContent: View {
    let inspections: [Inspection]
    var body: some View {
        VStack(spacing: 12) {
            HPSectionHeader(title: "Inspections (\(inspections.count))")
                .padding(.horizontal, 20)
            if inspections.isEmpty {
                HPEmptyState(icon: "magnifyingglass", title: "No Inspections",
                             message: "No inspections recorded for this building.")
            } else {
                ForEach(inspections) { insp in
                    InspectionRowCard(inspection: insp)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct RepairsTabContent: View {
    let repairs: [Repair]
    var body: some View {
        VStack(spacing: 12) {
            HPSectionHeader(title: "Repairs (\(repairs.count))")
                .padding(.horizontal, 20)
            if repairs.isEmpty {
                HPEmptyState(icon: "wrench.and.screwdriver", title: "No Repairs",
                             message: "No repairs recorded for this building.")
            } else {
                ForEach(repairs) { repair in
                    RepairRowCard(repair: repair)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Add Floor View
struct AddFloorView: View {
    let building: Building
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var level = 1
    @State private var nameError: String? = nil

    private let presets = ["Ground Floor", "Floor 1", "Floor 2", "Floor 3", "Basement", "Roof", "Mezzanine"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color.hpBlue.opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 36)).foregroundColor(.hpBlue)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 16) {
                        HPTextField(title: "Floor Name", text: $name,
                                    placeholder: "e.g. Ground Floor",
                                    icon: "square.stack.3d.up",
                                    errorMessage: nameError)
                            .onChange(of: name) { _ in nameError = nil }

                        // Presets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QUICK SELECT")
                                .font(.hpCaption())
                                .foregroundColor(.hpTextSecondary)
                                .tracking(0.5)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(presets, id: \.self) { preset in
                                        Button(action: { name = preset }) {
                                            Text(preset)
                                                .font(.hpCaption())
                                                .foregroundColor(name == preset ? .white : .hpBlue)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 7)
                                                .background(name == preset ? Color.hpBlue : Color.hpBlue.opacity(0.1))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("LEVEL NUMBER")
                                .font(.hpCaption())
                                .foregroundColor(.hpTextSecondary)
                                .tracking(0.5)
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(level) },
                                    set: { level = Int($0) }
                                ), in: -3...20, step: 1)
                                .accentColor(.hpBlue)
                                Text("\(level)")
                                    .font(.hpBodySemi())
                                    .foregroundColor(.hpBlue)
                                    .frame(width: 30)
                            }
                            .padding(14)
                            .background(Color.hpBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Add Floor", icon: "plus.circle.fill", style: .primary) {
                        save()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Floor", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            nameError = "Floor name is required"; return
        }
        buildingsVM.addFloor(to: building, name: name, level: level)
        activityVM.log(type: .floorAdded, description: "Added \(name) to \(building.name)")
        appVM.showSuccessToast("Floor added!")
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Floor Detail View
struct FloorDetailView: View {
    let floor: Floor
    let building: Building
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM: AppViewModel

    @State private var showAddRoom = false
    @State private var selectedRoom: Room? = nil

    var currentFloor: Floor {
        buildingsVM.buildings
            .first { $0.id == building.id }?
            .floors.first { $0.id == floor.id } ?? floor
    }

    var body: some View {
        ZStack {
            Color.hpBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Floor info
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.hpBlue.opacity(0.1))
                                .frame(width: 52, height: 52)
                            Text("\(currentFloor.level)")
                                .font(.hpTitle2())
                                .foregroundColor(.hpBlue)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(currentFloor.name)
                                .font(.hpTitle3())
                                .foregroundColor(.hpTextPrimary)
                            Text("\(currentFloor.rooms.count) room\(currentFloor.rooms.count == 1 ? "" : "s") · \(building.name)")
                                .font(.hpCaption())
                                .foregroundColor(.hpTextSecondary)
                        }
                        Spacer()
                    }
                    .hpCard()

                    // Rooms section
                    HPSectionHeader(title: "Rooms", actionTitle: "+ Add Room", action: { showAddRoom = true })

                    if currentFloor.rooms.isEmpty {
                        HPEmptyState(icon: "door.left.hand.open", title: "No Rooms",
                                     message: "Add rooms to track structures and conditions.",
                                     actionTitle: "Add Room", action: { showAddRoom = true })
                    } else {
                        ForEach(currentFloor.rooms) { room in
                            RoomCard(room: room)
                                .onTapGesture { selectedRoom = room }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        buildingsVM.deleteRoom(room, from: currentFloor, in: building)
                                    } label: { Label("Delete Room", systemImage: "trash") }
                                }
                        }
                    }

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationBarTitle(floor.name, displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: { showAddRoom = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.hpBlue)
            }
        )
        .sheet(isPresented: $showAddRoom) {
            AddRoomView(floor: currentFloor, building: building)
        }
        .background(
            NavigationLink(
                destination: selectedRoom.map { RoomDetailView(room: $0, floor: currentFloor, building: building) },
                isActive: Binding(get: { selectedRoom != nil }, set: { if !$0 { selectedRoom = nil } })
            ) { EmptyView() }
        )
    }
}

struct RoomCard: View {
    let room: Room
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.hpAccent.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 18))
                    .foregroundColor(.hpAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(room.name)
                    .font(.hpBodySemi())
                    .foregroundColor(.hpTextPrimary)
                HStack(spacing: 8) {
                    Text("\(Int(room.area)) m²")
                    Text("·")
                    Text("\(room.structures.count) structure\(room.structures.count == 1 ? "" : "s")")
                }
                .font(.hpCaption())
                .foregroundColor(.hpTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.hpTextSecondary)
        }
        .hpCard(14)
    }
}

// MARK: - Add Room View
struct AddRoomView: View {
    let floor: Floor
    let building: Building
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var area = ""
    @State private var nameError: String? = nil
    private let presets = ["Living Room", "Kitchen", "Bedroom", "Bathroom", "Hallway", "Office", "Storage", "Garage"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color.hpAccent.opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "door.left.hand.open")
                            .font(.system(size: 36)).foregroundColor(.hpAccent)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 16) {
                        HPTextField(title: "Room Name", text: $name,
                                    placeholder: "e.g. Living Room",
                                    icon: "door.left.hand.open",
                                    errorMessage: nameError)
                            .onChange(of: name) { _ in nameError = nil }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(presets, id: \.self) { preset in
                                    Button(action: { name = preset }) {
                                        Text(preset)
                                            .font(.hpCaption())
                                            .foregroundColor(name == preset ? .white : .hpAccent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(name == preset ? Color.hpAccent : Color.hpAccent.opacity(0.1))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }

                        HPTextField(title: "Area (m²)", text: $area,
                                    placeholder: "e.g. 25",
                                    icon: "ruler",
                                    keyboardType: .decimalPad)
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Add Room", icon: "plus.circle.fill", style: .accent) {
                        save()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Room", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            nameError = "Room name is required"; return
        }
        let areaValue = Double(area) ?? 0
        buildingsVM.addRoom(to: floor, in: building, name: name, area: areaValue)
        activityVM.log(type: .roomAdded, description: "Added \(name) to \(floor.name)")
        appVM.showSuccessToast("Room added!")
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Room Detail / Structures View
struct RoomDetailView: View {
    let room: Room
    let floor: Floor
    let building: Building
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM: AppViewModel

    @State private var showAddStructure = false
    @State private var selectedStructure: Structure? = nil

    var currentRoom: Room {
        buildingsVM.buildings
            .first { $0.id == building.id }?
            .floors.first { $0.id == floor.id }?
            .rooms.first { $0.id == room.id } ?? room
    }

    var body: some View {
        ZStack {
            Color.hpBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Room info card
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.hpAccent.opacity(0.1)).frame(width: 52, height: 52)
                            Image(systemName: "door.left.hand.open").font(.system(size: 22)).foregroundColor(.hpAccent)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(currentRoom.name).font(.hpTitle3()).foregroundColor(.hpTextPrimary)
                            Text("Area: \(Int(currentRoom.area)) m² · \(currentRoom.structures.count) structures")
                                .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                        }
                        Spacer()
                    }
                    .hpCard()

                    // Structures
                    HPSectionHeader(title: "Structures", actionTitle: "+ Add", action: { showAddStructure = true })

                    if currentRoom.structures.isEmpty {
                        HPEmptyState(icon: "square.split.2x1", title: "No Structures",
                                     message: "Add walls, ceiling, floor and other structural elements.",
                                     actionTitle: "Add Structure", action: { showAddStructure = true })
                    } else {
                        ForEach(currentRoom.structures) { structure in
                            StructureCard(structure: structure)
                                .onTapGesture { selectedStructure = structure }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        buildingsVM.deleteStructure(structure, from: currentRoom, floor: floor, in: building)
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                    }
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationBarTitle(room.name, displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: { showAddStructure = true }) {
                Image(systemName: "plus").font(.system(size: 16, weight: .semibold)).foregroundColor(.hpBlue)
            }
        )
        .sheet(isPresented: $showAddStructure) {
            AddStructureView(room: currentRoom, floor: floor, building: building)
        }
        .sheet(item: $selectedStructure) { structure in
            StructureDetailView(structure: structure)
        }
    }
}

struct StructureCard: View {
    let structure: Structure
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(structure.condition.color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: structure.type.icon).font(.system(size: 18)).foregroundColor(structure.condition.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(structure.type.rawValue).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Text(structure.material).font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            Spacer()
            HPBadge(text: structure.condition.rawValue, color: structure.condition.color)
        }
        .hpCard(14)
    }
}

// MARK: - Add Structure View
struct AddStructureView: View {
    let room: Room
    let floor: Floor
    let building: Building
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var type: StructureType = .wall
    @State private var material = ""
    @State private var condition: ConditionState = .good
    @State private var thickness = ""
    @State private var notes = ""
    @State private var materialError: String? = nil
    private let materials = ["Concrete", "Brick", "Wood", "Steel", "Plaster", "Drywall", "Stone", "Glass"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HPPickerRow(title: "Structure Type", selection: $type, icon: "square.split.2x1")
                        HPTextField(title: "Material", text: $material,
                                    placeholder: "e.g. Concrete",
                                    icon: "cube.fill",
                                    errorMessage: materialError)
                            .onChange(of: material) { _ in materialError = nil }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(materials, id: \.self) { m in
                                    Button(action: { material = m }) {
                                        Text(m).font(.hpCaption())
                                            .foregroundColor(material == m ? .white : .hpNavy)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(material == m ? Color.hpNavy : Color.hpNavy.opacity(0.1))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }

                        HPPickerRow(title: "Condition", selection: $condition, icon: "heart.fill")
                        HPTextField(title: "Thickness/Size (optional)", text: $thickness,
                                    placeholder: "e.g. 200mm",
                                    icon: "ruler")
                    }
                    .padding(.horizontal, 20)

                    // Condition preview
                    HStack(spacing: 12) {
                        ConditionRing(score: condition.score, size: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Condition: \(condition.rawValue)")
                                .font(.hpBodySemi())
                                .foregroundColor(condition.color)
                            Text("Score: \(Int(condition.score))%")
                                .font(.hpCaption())
                                .foregroundColor(.hpTextSecondary)
                        }
                        Spacer()
                    }
                    .hpCard()
                    .padding(.horizontal, 20)

                    HPButton(title: "Add Structure", icon: "plus.circle.fill", style: .primary) {
                        save()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Structure", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        guard !material.trimmingCharacters(in: .whitespaces).isEmpty else {
            materialError = "Material is required"; return
        }
        buildingsVM.addStructure(to: room, floor: floor, in: building,
                                  type: type, material: material, condition: condition,
                                  thickness: thickness, notes: notes)
        activityVM.log(type: .buildingAdded, description: "Added \(type.rawValue) to \(room.name)")
        appVM.showSuccessToast("Structure added!")
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Structure Detail View
struct StructureDetailView: View {
    let structure: Structure
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [structure.condition.color, structure.condition.color.opacity(0.6)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 160)
                        VStack(spacing: 12) {
                            Image(systemName: structure.type.icon)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            Text(structure.type.rawValue)
                                .font(.hpTitle2())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        DetailRow(label: "Material", value: structure.material, icon: "cube.fill")
                        DetailRow(label: "Condition", value: structure.condition.rawValue, icon: "heart.fill",
                                  valueColor: structure.condition.color)
                        DetailRow(label: "Score", value: "\(Int(structure.condition.score))%", icon: "chart.bar.fill",
                                  valueColor: structure.condition.color)
                        if !structure.thickness.isEmpty {
                            DetailRow(label: "Thickness", value: structure.thickness, icon: "ruler")
                        }
                        if !structure.notes.isEmpty {
                            DetailRow(label: "Notes", value: structure.notes, icon: "note.text")
                        }
                    }
                    .padding(.horizontal, 20)

                    // Condition bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("Condition Score")
                                .font(.hpBodySemi())
                                .foregroundColor(.hpTextPrimary)
                            Spacer()
                            Text("\(Int(structure.condition.score))%")
                                .font(.hpBodySemi())
                                .foregroundColor(structure.condition.color)
                        }
                        HPProgressBar(value: structure.condition.score / 100, color: structure.condition.color, height: 10)
                    }
                    .hpCard()
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Structure Details", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("Done") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.hpBlue)
            )
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var valueColor: Color = .hpTextPrimary

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.hpBlue)
                    .frame(width: 22)
            }
            Text(label)
                .font(.hpBody())
                .foregroundColor(.hpTextSecondary)
            Spacer()
            Text(value)
                .font(.hpBodySemi())
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shared Row Cards used in multiple places
struct IssueRowCard: View {
    let issue: Issue
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(issue.severity.color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: issue.type.icon).font(.system(size: 18)).foregroundColor(issue.severity.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(issue.type.rawValue).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Text(issue.location).font(.hpCaption()).foregroundColor(.hpTextSecondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HPSeverityBadge(severity: issue.severity)
                HPStatusBadge(status: issue.status)
            }
        }
        .hpCard(14)
    }
}

struct InspectionRowCard: View {
    let inspection: Inspection
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(inspection.result.color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: inspection.result.icon).font(.system(size: 18)).foregroundColor(inspection.result.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(inspection.inspector).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Text(inspection.date.shortFormatted).font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            Spacer()
            HPBadge(text: inspection.result.rawValue, color: inspection.result.color)
        }
        .hpCard(14)
    }
}

struct RepairRowCard: View {
    let repair: Repair
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(repair.status.color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: repair.type.icon).font(.system(size: 18)).foregroundColor(repair.status.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(repair.type.rawValue).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Text("$\(Int(repair.cost))").font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            Spacer()
            HPBadge(text: repair.status.rawValue, color: repair.status.color)
        }
        .hpCard(14)
    }
}
