import SwiftUI
import WebKit

// MARK: - Photos View
struct PhotosView: View {
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel

    @State private var showAdd = false
    @State private var selectedPhoto: IssuePhoto? = nil
    @State private var searchText = ""

    var filtered: [IssuePhoto] {
        searchText.isEmpty ? issuesVM.photos
            : issuesVM.photos.filter {
                $0.location.localizedCaseInsensitiveContains(searchText)
                || $0.note.localizedCaseInsensitiveContains(searchText)
            }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Photos").font(.hpTitle()).foregroundColor(.hpTextPrimary)
                                Text("\(issuesVM.photos.count) images documented").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                            }
                            Spacer()
                            Button(action: { showAdd = true }) {
                                ZStack {
                                    Circle().fill(Color(hex: "#AF52DE")).frame(width: 42, height: 42)
                                    Image(systemName: "camera.fill").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                                }
                            }
                            .pressScale()
                        }
                        HPSearchBar(text: $searchText)
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                    if filtered.isEmpty {
                        HPEmptyState(
                            icon: "camera", title: "No Photos",
                            message: "Document issues and defects with photos for visual reference.",
                            actionTitle: "Add Photo", action: { showAdd = true }
                        )
                        .padding(.top, 40)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(filtered) { photo in
                                    PhotoGridCell(photo: photo)
                                        .onTapGesture { selectedPhoto = photo }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                issuesVM.deletePhoto(photo)
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
            .sheet(isPresented: $showAdd) { AddPhotoView(issue: nil, buildingId: nil) }
            .sheet(item: $selectedPhoto) { photo in PhotoDetailView(photo: photo) }
        }
    }
}

struct PhotoGridCell: View {
    let photo: IssuePhoto
    @EnvironmentObject private var issuesVM: IssuesViewModel
    @State private var image: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.hpBackground)
                .aspectRatio(1, contentMode: .fit)
            if let img = image {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
                    .cornerRadius(10)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "photo").font(.system(size: 24)).foregroundColor(.hpBorder)
                    Text(photo.location).font(.hpCaption2()).foregroundColor(.hpTextSecondary).lineLimit(1)
                }
            }
        }
        .onAppear {
            if let data = issuesVM.loadImageData(filename: photo.filename) {
                image = UIImage(data: data)
            }
        }
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let view = pan.view else { return false }
        
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

struct AddPhotoView: View {
    var issue: Issue?
    var buildingId: UUID?
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var location = ""
    @State private var note = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var locationError: String? = nil
    @State private var selectedBuilding: Building? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo selector
                    Button(action: { showImagePicker = true }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.hpBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.hpBorder, style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                                )
                                .frame(height: 200)
                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(height: 200).clipped().cornerRadius(16)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 36)).foregroundColor(.hpTextSecondary)
                                    Text("Tap to select photo").font(.hpBody()).foregroundColor(.hpTextSecondary)
                                    Text("from Library or Camera").font(.hpCaption()).foregroundColor(.hpTextSecondary.opacity(0.7))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .pressScale()

                    // Camera / Library buttons
                    HStack(spacing: 12) {
                        Button(action: { showImagePicker = true }) {
                            Label("Library", systemImage: "photo.on.rectangle")
                                .font(.hpBodySemi())
                                .foregroundColor(.hpBlue)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.hpBlue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        Button(action: { showCamera = true }) {
                            Label("Camera", systemImage: "camera.fill")
                                .font(.hpBodySemi())
                                .foregroundColor(Color(hex: "#AF52DE"))
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "#AF52DE").opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 16) {
                        // Building picker (if no issue given)
                        if issue == nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("BUILDING (OPTIONAL)").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                                Menu {
                                    Button("None") { selectedBuilding = nil }
                                    ForEach(buildingsVM.buildings) { b in
                                        Button(b.name) { selectedBuilding = b }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "building.2").foregroundColor(.hpBlue)
                                        Text(selectedBuilding?.name ?? "Select Building (Optional)")
                                            .font(.hpBody())
                                            .foregroundColor(selectedBuilding == nil ? .hpTextSecondary : .hpTextPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down").font(.system(size: 13)).foregroundColor(.hpTextSecondary)
                                    }
                                    .padding(14).background(Color.hpBackground).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.hpBorder, lineWidth: 1))
                                }
                            }
                        }

                        HPTextField(title: "Location / Description", text: $location,
                                    placeholder: "e.g. North wall crack, Basement floor",
                                    icon: "mappin.circle", errorMessage: locationError)
                            .onChange(of: location) { _ in locationError = nil }

                        HPTextField(title: "Notes (optional)", text: $note,
                                    placeholder: "Additional notes...", icon: "note.text")
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Save Photo", icon: "camera.fill", style: .primary, isLoading: isLoading) { save() }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Photo", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
    }

    private func save() {
        guard !location.trimmingCharacters(in: .whitespaces).isEmpty else {
            locationError = "Location is required"; return
        }
        isLoading = true

        var filename = UUID().uuidString + ".jpg"
        if let img = selectedImage, let data = img.jpegData(compressionQuality: 0.7) {
            filename = issuesVM.saveImageData(data) ?? filename
        }

        let bId = buildingId ?? selectedBuilding?.id

        if let iss = issue {
            issuesVM.addPhoto(to: iss, filename: filename, location: location, note: note,
                              buildingId: iss.buildingId)
        } else {
            issuesVM.addStandalonePhoto(filename: filename, location: location, note: note,
                                        buildingId: bId ?? UUID())
        }
        activityVM.log(type: .photoAdded, description: "Photo added: \(location)")
        appVM.showSuccessToast("Photo saved!")
        isLoading = false
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photo: IssuePhoto
    @EnvironmentObject private var issuesVM: IssuesViewModel
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var image: UIImage? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ZStack {
                            Color.black
                            VStack(spacing: 12) {
                                Image(systemName: "photo").font(.system(size: 60)).foregroundColor(.white.opacity(0.4))
                                Text("Photo not available").font(.hpBody()).foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(photo.location).font(.hpHeadline()).foregroundColor(.white)
                        if !photo.note.isEmpty { Text(photo.note).font(.hpBody()).foregroundColor(.white.opacity(0.7)) }
                        Text(photo.createdAt.shortFormatted).font(.hpCaption()).foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.black.opacity(0.6))
                }
            }
            .navigationBarTitle("Photo", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.white),
                trailing: Button(action: {
                    issuesVM.deletePhoto(photo)
                    appVM.showSuccessToast("Photo deleted")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "trash").foregroundColor(.hpDanger)
                }
            )
        }
        .onAppear {
            if let data = issuesVM.loadImageData(filename: photo.filename) {
                image = UIImage(data: data)
            }
        }
    }
}

// MARK: - Measurements View (standalone list)
struct MeasurementsView: View {
    @EnvironmentObject private var issuesVM: IssuesViewModel

    var allMeasurements: [IssueMeasurement] { issuesVM.issues.flatMap(\.measurements) }

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Measurements").font(.hpTitle()).foregroundColor(.hpTextPrimary)
                            Text("\(allMeasurements.count) recorded").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                    if allMeasurements.isEmpty {
                        HPEmptyState(
                            icon: "ruler", title: "No Measurements",
                            message: "Measurements are logged inside individual issue details."
                        )
                        .padding(.top, 40)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(allMeasurements) { m in
                                    MeasurementCard(measurement: m)
                                }
                            }
                            .padding(.horizontal, 20).padding(.bottom, 100).padding(.top, 4)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct MeasurementCard: View {
    let measurement: IssueMeasurement
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.hpAccent.opacity(0.1)).frame(width: 50, height: 50)
                Image(systemName: "ruler.fill").font(.system(size: 20)).foregroundColor(.hpAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(measurement.label).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Text(measurement.createdAt.shortFormatted).font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            Spacer()
            Text("\(String(format: "%.2f", measurement.value)) \(measurement.unit.rawValue)")
                .font(.hpHeadline()).foregroundColor(.hpAccent)
        }
        .hpCard(14)
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [HomeInspect] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Materials View
struct MaterialsView: View {
    @EnvironmentObject private var materialsVM: MaterialsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel

    @State private var showAdd = false
    @State private var searchText = ""
    @State private var filterType: MaterialType? = nil

    var filtered: [Material] {
        var list = materialsVM.materials
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let t = filterType { list = list.filter { $0.type == t } }
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
                                Text("Materials").font(.hpTitle()).foregroundColor(.hpTextPrimary)
                                Text("\(materialsVM.materials.count) items").font(.hpCaption()).foregroundColor(.hpTextSecondary)
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
                        HPSearchBar(text: $searchText)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(title: "All", isSelected: filterType == nil) { filterType = nil }
                                ForEach(MaterialType.allCases, id: \.self) { t in
                                    FilterChip(title: t.rawValue, color: .hpAccent, isSelected: filterType == t) {
                                        filterType = filterType == t ? nil : t
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                    if filtered.isEmpty {
                        HPEmptyState(icon: "cube.box.fill", title: "No Materials",
                                     message: "Track building materials used in repairs and construction.",
                                     actionTitle: "Add Material", action: { showAdd = true })
                        .padding(.top, 40)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { mat in
                                    MaterialCard(material: mat)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                materialsVM.delete(mat)
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                            .padding(.horizontal, 20).padding(.bottom, 100).padding(.top, 4)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddMaterialView() }
        }
    }
}

struct MaterialCard: View {
    let material: Material
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.hpAccent.opacity(0.1)).frame(width: 50, height: 50)
                Image(systemName: material.type.icon).font(.system(size: 20)).foregroundColor(.hpAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(material.name).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Text(material.type.rawValue).font(.hpCaption()).foregroundColor(.hpTextSecondary)
                if !material.supplier.isEmpty {
                    Text("Supplier: \(material.supplier)").font(.hpCaption2()).foregroundColor(.hpTextSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.0f", material.quantity))")
                    .font(.hpBodySemi()).foregroundColor(.hpAccent)
                Text(material.unit).font(.hpCaption2()).foregroundColor(.hpTextSecondary)
            }
        }
        .hpCard(14)
    }
}

// MARK: - Add Material View
struct AddMaterialView: View {
    @EnvironmentObject private var materialsVM: MaterialsViewModel
    @EnvironmentObject private var buildingsVM: BuildingsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel
    @EnvironmentObject private var appVM:       AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var type: MaterialType = .concrete
    @State private var quantity = ""
    @State private var unit = "m²"
    @State private var supplier = ""
    @State private var notes = ""
    @State private var selectedBuilding: Building? = nil
    @State private var nameError: String? = nil

    private let units = ["m²", "m³", "kg", "t", "pcs", "L", "m"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color.hpAccent.opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "cube.box.fill").font(.system(size: 34)).foregroundColor(.hpAccent)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 16) {
                        HPTextField(title: "Material Name", text: $name,
                                    placeholder: "e.g. Portland Cement",
                                    icon: "cube.fill", errorMessage: nameError)
                            .onChange(of: name) { _ in nameError = nil }

                        HPPickerRow(title: "Type", selection: $type, icon: "square.fill")

                        HStack(spacing: 12) {
                            HPTextField(title: "Quantity", text: $quantity,
                                        placeholder: "0", icon: "number",
                                        keyboardType: .decimalPad)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("UNIT").font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                                Menu {
                                    ForEach(units, id: \.self) { u in
                                        Button(u) { unit = u }
                                    }
                                } label: {
                                    HStack {
                                        Text(unit).font(.hpBody()).foregroundColor(.hpTextPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down").font(.system(size: 12)).foregroundColor(.hpTextSecondary)
                                    }
                                    .padding(14).background(Color.hpBackground).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.hpBorder, lineWidth: 1))
                                }
                                .frame(width: 90)
                            }
                        }

                        HPTextField(title: "Supplier (optional)", text: $supplier,
                                    placeholder: "e.g. BuildCo Ltd", icon: "building")

                        // Building assignment (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ASSIGN TO BUILDING (OPTIONAL)")
                                .font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                            Menu {
                                Button("None") { selectedBuilding = nil }
                                ForEach(buildingsVM.buildings) { b in Button(b.name) { selectedBuilding = b } }
                            } label: {
                                HStack {
                                    Image(systemName: "building.2").foregroundColor(.hpBlue)
                                    Text(selectedBuilding?.name ?? "No Building Selected")
                                        .font(.hpBody())
                                        .foregroundColor(selectedBuilding == nil ? .hpTextSecondary : .hpTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down").font(.system(size: 13)).foregroundColor(.hpTextSecondary)
                                }
                                .padding(14).background(Color.hpBackground).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.hpBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    HPButton(title: "Add Material", icon: "plus.circle.fill", style: .accent) { save() }
                        .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("Add Material", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { nameError = "Name required"; return }
        materialsVM.add(name: name, type: type, quantity: Double(quantity) ?? 0, unit: unit,
                        supplier: supplier, notes: notes, buildingId: selectedBuilding?.id)
        activityVM.log(type: .materialAdded, description: "Added material: \(name)")
        appVM.showSuccessToast("Material added!")
        presentationMode.wrappedValue.dismiss()
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "homeinspect_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🏠 [HomeInspect] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true
        
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        
        popups.append(popup)
        
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            popup.load(navigationAction.request)
        }
        
        return popup
    }
    
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        
        switch recognizer.state {
        case .changed:
            if translation.x > 0 {
                popupView.transform = CGAffineTransform(translationX: translation.x, y: 0)
            }
            
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            
            if shouldClose {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in
                    self?.dismissTopPopup()
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    popupView.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    private func dismissTopPopup() {
        guard let last = popups.last else { return }
        last.removeFromSuperview()
        popups.removeLast()
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) {
            webView.removeFromSuperview()
            popups.remove(at: index)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
