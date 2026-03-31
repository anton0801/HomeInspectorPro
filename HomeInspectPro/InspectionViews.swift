import SwiftUI
import WebKit

// MARK: - Inspections List
struct InspectionsView: View {
    @EnvironmentObject private var inspVM:      InspectionsViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel

    @State private var showAdd = false
    @State private var searchText = ""
    @State private var filterResult: InspectionResult? = nil
    @State private var selectedInspection: Inspection? = nil

    var filtered: [Inspection] {
        var list = inspVM.inspections
        if !searchText.isEmpty {
            list = list.filter {
                $0.buildingName.localizedCaseInsensitiveContains(searchText)
                || $0.inspector.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let f = filterResult { list = list.filter { $0.result == f } }
        return list
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
                                Text("Inspections")
                                    .font(.hpTitle())
                                    .foregroundColor(.hpTextPrimary)
                                Text("\(inspVM.inspections.count) total logged")
                                    .font(.hpCaption())
                                    .foregroundColor(.hpTextSecondary)
                            }
                            Spacer()
                            Button(action: { showAdd = true }) {
                                ZStack {
                                    Circle().fill(Color(hex: "#AF52DE")).frame(width: 42, height: 42)
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .pressScale()
                        }
                        HPSearchBar(text: $searchText)
                        // Result filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(title: "All", isSelected: filterResult == nil) { filterResult = nil }
                                ForEach(InspectionResult.allCases, id: \.self) { result in
                                    FilterChip(title: result.rawValue, color: result.color,
                                               isSelected: filterResult == result) {
                                        filterResult = filterResult == result ? nil : result
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    if filtered.isEmpty {
                        HPEmptyState(
                            icon: "magnifyingglass.circle",
                            title: "No Inspections",
                            message: "Log your first inspection to track building health over time.",
                            actionTitle: "Add Inspection",
                            action: { showAdd = true }
                        )
                        .padding(.top, 40)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { inspection in
                                    InspectionDetailCard(inspection: inspection)
                                        .onTapGesture { selectedInspection = inspection }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                inspVM.delete(inspection)
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
            .sheet(isPresented: $showAdd) { AddInspectionView() }
            .sheet(item: $selectedInspection) { insp in InspectionDetailView(inspection: insp) }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}


struct InspectionDetailCard: View {
    let inspection: Inspection
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(inspection.result.color.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: inspection.result.icon)
                        .font(.system(size: 20)).foregroundColor(inspection.result.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(inspection.buildingName).font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                    Text("Inspector: \(inspection.inspector)").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(inspection.date.dayMonthFormatted).font(.hpCaption()).foregroundColor(.hpTextSecondary)
                    HPBadge(text: inspection.result.rawValue, color: inspection.result.color)
                }
            }
            if !inspection.notes.isEmpty {
                HPDivider()
                Text(inspection.notes).font(.hpCaption()).foregroundColor(.hpTextSecondary).lineLimit(2)
            }
        }
        .hpCard()
    }
}

// MARK: - Add Inspection View
struct AddInspectionView: View {
    @EnvironmentObject private var inspVM:      InspectionsViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var inspector = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var result: InspectionResult = .passed
    @State private var selectedBuilding: Building? = nil
    @State private var inspectorError: String? = nil
    @State private var buildingError: String? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color(hex: "#AF52DE").opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 36)).foregroundColor(Color(hex: "#AF52DE"))
                    }
                    .padding(.top, 10)

                    VStack(spacing: 16) {
                        // Building picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BUILDING")
                                .font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
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
                                .padding(14)
                                .background(Color.hpBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(buildingError != nil ? Color.hpDanger : Color.hpBorder, lineWidth: 1)
                                )
                            }
                            if let e = buildingError {
                                Text(e).font(.hpCaption2()).foregroundColor(.hpDanger)
                            }
                        }

                        HPTextField(title: "Inspector Name", text: $inspector,
                                    placeholder: "e.g. John Smith",
                                    icon: "person.fill",
                                    errorMessage: inspectorError)
                            .onChange(of: inspector) { _ in inspectorError = nil }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATE").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(14)
                                .background(Color.hpBackground)
                                .cornerRadius(12)
                        }

                        HPPickerRow(title: "Result", selection: $result, icon: "checkmark.seal")

                        // Result indicator
                        HStack(spacing: 12) {
                            Image(systemName: result.icon)
                                .font(.system(size: 20))
                                .foregroundColor(result.color)
                            Text(result.rawValue)
                                .font(.hpBodySemi())
                                .foregroundColor(result.color)
                            Spacer()
                        }
                        .padding(14)
                        .background(result.color.opacity(0.08))
                        .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12).fill(Color.hpBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.hpBorder, lineWidth: 1))
                                TextEditor(text: $notes)
                                    .font(.hpBody()).foregroundColor(.hpTextPrimary)
                                    .padding(12).frame(minHeight: 90)
                                if notes.isEmpty {
                                    Text("Inspection notes, findings, recommendations...")
                                        .font(.hpBody()).foregroundColor(.hpTextSecondary.opacity(0.6))
                                        .padding(16).allowsHitTesting(false)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Save Inspection", icon: "checkmark.circle.fill", style: .primary,
                             isLoading: isLoading) { save() }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Inspection", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        var valid = true
        if selectedBuilding == nil { buildingError = "Select a building"; valid = false }
        if inspector.trimmingCharacters(in: .whitespaces).isEmpty { inspectorError = "Inspector name required"; valid = false }
        guard valid, let building = selectedBuilding else { return }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            inspVM.add(date: date, inspector: inspector, notes: notes,
                       buildingId: building.id, buildingName: building.name, result: result)
            activityVM.log(type: .inspectionAdded,
                           description: "Inspection logged for \(building.name) by \(inspector)")
            activityVM.addNotification(title: "Inspection Logged",
                                       body: "New inspection for \(building.name) recorded.",
                                       type: .inspectionDue)
            appVM.showSuccessToast("Inspection saved!")
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Inspection Detail View
struct InspectionDetailView: View {
    let inspection: Inspection
    @EnvironmentObject private var inspVM: InspectionsViewModel
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [inspection.result.color, inspection.result.color.opacity(0.6)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 140)
                        VStack(spacing: 8) {
                            Image(systemName: inspection.result.icon)
                                .font(.system(size: 40, weight: .bold)).foregroundColor(.white)
                            Text(inspection.result.rawValue)
                                .font(.hpTitle3()).foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        DetailRow(label: "Building", value: inspection.buildingName, icon: "building.2.fill")
                        DetailRow(label: "Inspector", value: inspection.inspector, icon: "person.fill")
                        DetailRow(label: "Date", value: inspection.date.shortFormatted, icon: "calendar")
                        DetailRow(label: "Result", value: inspection.result.rawValue,
                                  icon: inspection.result.icon, valueColor: inspection.result.color)
                    }
                    .hpCard()
                    .padding(.horizontal, 20)

                    if !inspection.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                            Text(inspection.notes).font(.hpBody()).foregroundColor(.hpTextSecondary)
                        }
                        .hpCard()
                        .padding(.horizontal, 20)
                    }

                    HPButton(title: "Delete Inspection", icon: "trash", style: .destructive) {
                        inspVM.delete(inspection)
                        presentationMode.wrappedValue.dismiss()
                        appVM.showSuccessToast("Inspection deleted")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 20)
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Inspection Details", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    var color: Color = .hpBlue
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hpCaption())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .hpTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color.hpCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(isSelected ? color : Color.hpBorder, lineWidth: 1)
                )
        }
        .animation(.hpFast, value: isSelected)
    }
}
