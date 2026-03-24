import SwiftUI

// MARK: - Issues List View
struct IssuesView: View {
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel

    @State private var showAdd = false
    @State private var searchText = ""
    @State private var filterSeverity: IssueSeverity? = nil
    @State private var filterStatus: IssueStatus? = nil
    @State private var selectedIssue: Issue? = nil

    var filtered: [Issue] {
        var list = issuesVM.issues.sorted { $0.severity.priority > $1.severity.priority }
        if !searchText.isEmpty {
            list = list.filter {
                $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
                || $0.location.localizedCaseInsensitiveContains(searchText)
                || $0.buildingName.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let s = filterSeverity { list = list.filter { $0.severity == s } }
        if let st = filterStatus  { list = list.filter { $0.status == st } }
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
                                Text("Issues")
                                    .font(.hpTitle()).foregroundColor(.hpTextPrimary)
                                HStack(spacing: 6) {
                                    Text("\(issuesVM.openIssues.count) open")
                                        .foregroundColor(.hpDanger)
                                    if issuesVM.criticalIssues.count > 0 {
                                        Text("·")
                                        Text("\(issuesVM.criticalIssues.count) critical")
                                            .foregroundColor(.hpDanger)
                                    }
                                }
                                .font(.hpCaption())
                            }
                            Spacer()
                            Button(action: { showAdd = true }) {
                                ZStack {
                                    Circle().fill(LinearGradient.hpDangerGrad).frame(width: 42, height: 42)
                                    Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                }
                            }
                            .pressScale()
                        }
                        HPSearchBar(text: $searchText)
                        // Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(title: "All", isSelected: filterSeverity == nil && filterStatus == nil) {
                                    filterSeverity = nil; filterStatus = nil
                                }
                                ForEach(IssueSeverity.allCases, id: \.self) { sev in
                                    FilterChip(title: sev.rawValue, color: sev.color,
                                               isSelected: filterSeverity == sev) {
                                        filterSeverity = filterSeverity == sev ? nil : sev
                                    }
                                }
                                FilterChip(title: "Open", color: .hpDanger, isSelected: filterStatus == .open) {
                                    filterStatus = filterStatus == .open ? nil : .open
                                }
                                FilterChip(title: "Resolved", color: .hpSuccess, isSelected: filterStatus == .resolved) {
                                    filterStatus = filterStatus == .resolved ? nil : .resolved
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    if filtered.isEmpty {
                        HPEmptyState(
                            icon: "checkmark.shield",
                            title: issuesVM.issues.isEmpty ? "No Issues" : "No Results",
                            message: issuesVM.issues.isEmpty ? "Your buildings are issue-free. Tap + to log a new issue." : "Try adjusting your filters.",
                            actionTitle: issuesVM.issues.isEmpty ? "Log Issue" : nil,
                            action: issuesVM.issues.isEmpty ? { showAdd = true } : nil
                        )
                        .padding(.top, 40)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { issue in
                                    IssueCard(issue: issue)
                                        .onTapGesture { selectedIssue = issue }
                                        .contextMenu {
                                            if issue.status != .resolved {
                                                Button {
                                                    issuesVM.resolve(issue)
                                                    activityVM.log(type: .issueResolved,
                                                                   description: "Resolved \(issue.type.rawValue) at \(issue.location)")
                                                    appVM.showSuccessToast("Issue resolved!")
                                                } label: { Label("Mark Resolved", systemImage: "checkmark.circle") }
                                            }
                                            Button(role: .destructive) {
                                                issuesVM.delete(issue)
                                            } label: { Label("Delete", systemImage: "trash") }
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
            .sheet(isPresented: $showAdd) { AddIssueView() }
            .sheet(item: $selectedIssue) { issue in IssueDetailView(issue: issue) }
        }
    }
}

// MARK: - Issue Card
struct IssueCard: View {
    let issue: Issue
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(issue.severity.color.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: issue.type.icon)
                        .font(.system(size: 22)).foregroundColor(issue.severity.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(issue.type.rawValue).font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                    Text(issue.buildingName).font(.hpCaption()).foregroundColor(.hpTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HPSeverityBadge(severity: issue.severity)
                    HPStatusBadge(status: issue.status)
                }
            }
            HPDivider()
            HStack {
                Label(issue.location, systemImage: "mappin.circle.fill")
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
                Spacer()
                Text(issue.createdAt.relativeFormatted)
                    .font(.hpCaption2())
                    .foregroundColor(.hpTextSecondary)
            }
        }
        .hpCard()
    }
}

// MARK: - Add Issue View
struct AddIssueView: View {
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var type: IssueType = .crack
    @State private var location = ""
    @State private var severity: IssueSeverity = .medium
    @State private var description = ""
    @State private var selectedBuilding: Building? = nil
    @State private var locationError: String? = nil
    @State private var buildingError: String? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color.hpDanger.opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 34)).foregroundColor(.hpDanger)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 16) {
                        // Building picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BUILDING").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                            Menu {
                                if buildingsVM.buildings.isEmpty {
                                    Text("No buildings — add one first")
                                } else {
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

                        HPPickerRow(title: "Issue Type", selection: $type, icon: "exclamationmark.triangle")
                        HPTextField(title: "Location", text: $location,
                                    placeholder: "e.g. North wall, Kitchen",
                                    icon: "mappin.circle",
                                    errorMessage: locationError)
                            .onChange(of: location) { _ in locationError = nil }
                        HPPickerRow(title: "Severity", selection: $severity, icon: "thermometer")

                        // Severity preview
                        HStack(spacing: 10) {
                            ForEach(IssueSeverity.allCases, id: \.self) { sev in
                                Button(action: { withAnimation(.hpFast) { severity = sev } }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(sev.color.opacity(severity == sev ? 1 : 0.2))
                                            .frame(width: severity == sev ? 18 : 12, height: severity == sev ? 18 : 12)
                                        Text(sev.rawValue)
                                            .font(.hpCaption2())
                                            .foregroundColor(severity == sev ? sev.color : .hpTextSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(14)
                        .background(severity.color.opacity(0.06))
                        .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12).fill(Color.hpBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.hpBorder, lineWidth: 1))
                                TextEditor(text: $description)
                                    .font(.hpBody()).foregroundColor(.hpTextPrimary)
                                    .padding(12).frame(minHeight: 90)
                                if description.isEmpty {
                                    Text("Describe the issue in detail...")
                                        .font(.hpBody()).foregroundColor(.hpTextSecondary.opacity(0.6))
                                        .padding(16).allowsHitTesting(false)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Log Issue", icon: "exclamationmark.triangle.fill", style: .destructive,
                             isLoading: isLoading) { save() }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Log Issue", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        var valid = true
        if selectedBuilding == nil { buildingError = "Select a building"; valid = false }
        if location.trimmingCharacters(in: .whitespaces).isEmpty { locationError = "Location required"; valid = false }
        guard valid, let building = selectedBuilding else { return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            issuesVM.add(type: type, location: location, severity: severity,
                         description: description, buildingId: building.id, buildingName: building.name)
            activityVM.log(type: .issueAdded,
                           description: "\(severity.rawValue) \(type.rawValue) logged at \(location) — \(building.name)")
            activityVM.addNotification(title: "Issue Logged",
                                       body: "\(severity.rawValue) \(type.rawValue) at \(location).",
                                       type: .issueDetected)
            appVM.showSuccessToast("Issue logged!")
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Issue Detail View
struct IssueDetailView: View {
    @State var issue: Issue
    @EnvironmentObject private var issuesVM:   IssuesViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @EnvironmentObject private var appVM:      AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showAddMeasurement = false
    @State private var showAddPhoto       = false
    @State private var selectedTab: IssueTab = .info

    enum IssueTab: String, CaseIterable {
        case info = "Info"
        case measurements = "Measurements"
        case photos = "Photos"
    }

    var currentIssue: Issue {
        issuesVM.issues.first { $0.id == issue.id } ?? issue
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero banner
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [currentIssue.severity.color, currentIssue.severity.color.opacity(0.6)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 130)
                            HStack(spacing: 16) {
                                Image(systemName: currentIssue.type.icon)
                                    .font(.system(size: 42, weight: .bold)).foregroundColor(.white)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentIssue.type.rawValue)
                                        .font(.hpTitle2()).foregroundColor(.white)
                                    Text(currentIssue.buildingName)
                                        .font(.hpCaption()).foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.horizontal, 20)

                        // Status + Severity row
                        HStack(spacing: 10) {
                            HPSeverityBadge(severity: currentIssue.severity)
                            HPStatusBadge(status: currentIssue.status)
                            Spacer()
                            Text(currentIssue.createdAt.shortFormatted)
                                .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                        }
                        .padding(.horizontal, 20)

                        // Tab bar
                        HStack(spacing: 8) {
                            ForEach(IssueTab.allCases, id: \.self) { t in
                                Button(action: { withAnimation(.hpFast) { selectedTab = t } }) {
                                    Text(t.rawValue)
                                        .font(.hpBodySemi())
                                        .foregroundColor(selectedTab == t ? .white : .hpTextSecondary)
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(selectedTab == t ? Color.hpBlue : Color.hpCard)
                                        .cornerRadius(20)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        // Tab content
                        switch selectedTab {
                        case .info:
                            IssueInfoTab(issue: currentIssue)
                        case .measurements:
                            IssueMeasurementsTab(issue: currentIssue, onAdd: { showAddMeasurement = true })
                        case .photos:
                            IssuePhotosTab(issue: currentIssue, onAdd: { showAddPhoto = true })
                        }

                        // Action buttons
                        if currentIssue.status != .resolved {
                            HPButton(title: "Mark as Resolved", icon: "checkmark.circle.fill", style: .primary) {
                                issuesVM.resolve(currentIssue)
                                activityVM.log(type: .issueResolved,
                                               description: "Resolved \(currentIssue.type.rawValue) at \(currentIssue.location)")
                                appVM.showSuccessToast("Issue resolved!")
                                presentationMode.wrappedValue.dismiss()
                            }
                            .padding(.horizontal, 20)
                        }

                        HPButton(title: "Delete Issue", icon: "trash", style: .destructive) {
                            issuesVM.delete(currentIssue)
                            appVM.showSuccessToast("Issue deleted")
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitle("Issue Details", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
            .sheet(isPresented: $showAddMeasurement) {
                AddMeasurementView(issue: currentIssue)
            }
            .sheet(isPresented: $showAddPhoto) {
                AddPhotoView(issue: currentIssue, buildingId: currentIssue.buildingId)
            }
        }
    }
}

// MARK: - Issue Info Tab
struct IssueInfoTab: View {
    let issue: Issue
    var body: some View {
        VStack(spacing: 12) {
            DetailRow(label: "Type",     value: issue.type.rawValue, icon: issue.type.icon)
            DetailRow(label: "Location", value: issue.location,      icon: "mappin.circle.fill")
            DetailRow(label: "Building", value: issue.buildingName,  icon: "building.2.fill")
            DetailRow(label: "Severity", value: issue.severity.rawValue,
                      icon: "thermometer", valueColor: issue.severity.color)
            DetailRow(label: "Status",   value: issue.status.rawValue,
                      icon: "circle.fill", valueColor: issue.status.color)
        }
        .hpCard()
        .padding(.horizontal, 20)

        if !issue.description.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Description").font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                Text(issue.description).font(.hpBody()).foregroundColor(.hpTextSecondary)
            }
            .hpCard()
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Issue Measurements Tab
struct IssueMeasurementsTab: View {
    let issue: Issue
    let onAdd: () -> Void
    @EnvironmentObject private var issuesVM: IssuesViewModel
    @EnvironmentObject private var appVM: AppViewModel

    var body: some View {
        VStack(spacing: 12) {
            HPSectionHeader(title: "Measurements", actionTitle: "+ Add", action: onAdd)
                .padding(.horizontal, 20)

            if issue.measurements.isEmpty {
                HPEmptyState(icon: "ruler", title: "No Measurements",
                             message: "Record crack widths, deformation sizes, and other measurements.",
                             actionTitle: "Add Measurement", action: onAdd)
            } else {
                ForEach(issue.measurements) { m in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.hpAccent.opacity(0.1)).frame(width: 44, height: 44)
                            Image(systemName: "ruler.fill").font(.system(size: 18)).foregroundColor(.hpAccent)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(m.label).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                            Text(m.createdAt.shortFormatted).font(.hpCaption()).foregroundColor(.hpTextSecondary)
                        }
                        Spacer()
                        Text("\(String(format: "%.1f", m.value)) \(m.unit.rawValue)")
                            .font(.hpBodySemi()).foregroundColor(.hpAccent)
                    }
                    .hpCard(14)
                    .padding(.horizontal, 20)
                    .contextMenu {
                        Button(role: .destructive) {
                            issuesVM.deleteMeasurement(m, from: issue)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }
}

// MARK: - Issue Photos Tab
struct IssuePhotosTab: View {
    let issue: Issue
    let onAdd: () -> Void
    @EnvironmentObject private var issuesVM: IssuesViewModel

    var issuePhotos: [IssuePhoto] {
        issuesVM.photos.filter { $0.issueId == issue.id }
    }

    var body: some View {
        VStack(spacing: 12) {
            HPSectionHeader(title: "Photos (\(issuePhotos.count))", actionTitle: "+ Add", action: onAdd)
                .padding(.horizontal, 20)

            if issuePhotos.isEmpty {
                HPEmptyState(icon: "camera", title: "No Photos",
                             message: "Add photos to document the issue visually.",
                             actionTitle: "Add Photo", action: onAdd)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(issuePhotos) { photo in
                        PhotoThumbnail(photo: photo)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct PhotoThumbnail: View {
    let photo: IssuePhoto
    @EnvironmentObject private var issuesVM: IssuesViewModel
    @State private var image: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.hpBackground)
                    .frame(height: 120)
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.hpBorder)
                }
            }
            Text(photo.location)
                .font(.hpCaption()).foregroundColor(.hpTextSecondary).lineLimit(1)
        }
        .contextMenu {
            Button(role: .destructive) {
                issuesVM.deletePhoto(photo)
            } label: { Label("Delete Photo", systemImage: "trash") }
        }
        .onAppear {
            if let data = issuesVM.loadImageData(filename: photo.filename) {
                image = UIImage(data: data)
            }
        }
    }
}

// MARK: - Add Measurement View
struct AddMeasurementView: View {
    let issue: Issue
    @EnvironmentObject private var issuesVM: IssuesViewModel
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var label = ""
    @State private var value = ""
    @State private var unit: MeasurementUnit = .mm
    @State private var labelError: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color.hpAccent.opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "ruler.fill").font(.system(size: 34)).foregroundColor(.hpAccent)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 16) {
                        HPTextField(title: "Measurement Label", text: $label,
                                    placeholder: "e.g. Crack width, Settlement depth",
                                    icon: "tag.fill", errorMessage: labelError)
                            .onChange(of: label) { _ in labelError = nil }
                        HPTextField(title: "Value", text: $value,
                                    placeholder: "e.g. 5.2",
                                    icon: "number", keyboardType: .decimalPad)
                        HPPickerRow(title: "Unit", selection: $unit, icon: "ruler")
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Add Measurement", icon: "plus.circle.fill", style: .accent) { save() }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Measurement", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        guard !label.trimmingCharacters(in: .whitespaces).isEmpty else {
            labelError = "Label is required"; return
        }
        let numValue = Double(value) ?? 0
        issuesVM.addMeasurement(to: issue, label: label, value: numValue, unit: unit)
        appVM.showSuccessToast("Measurement added!")
        presentationMode.wrappedValue.dismiss()
    }
}
