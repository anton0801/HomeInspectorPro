import Foundation
import SwiftUI
import UserNotifications

// MARK: - Persistence Key Constants
private enum Keys {
    static let user         = "hp_user"
    static let buildings    = "hp_buildings"
    static let inspections  = "hp_inspections"
    static let issues       = "hp_issues"
    static let repairs      = "hp_repairs"
    static let materials    = "hp_materials"
    static let photos       = "hp_photos"
    static let activities   = "hp_activities"
    static let notifications = "hp_notifications"
}

// MARK: - AppViewModel
final class AppViewModel: ObservableObject {
    @AppStorage("hp_isLoggedIn")            var isLoggedIn: Bool = false
    @AppStorage("hp_hasOnboarded")          var hasOnboarded: Bool = false
    @AppStorage("hp_themeMode")             var themeMode: String = "system"
    @AppStorage("hp_unitSystem")            var unitSystem: String = "metric"
    @AppStorage("hp_notificationsEnabled")  var notificationsEnabled: Bool = true
    @AppStorage("hp_inspectionReminders")   var inspectionReminders: Bool = true
    @AppStorage("hp_repairReminders")       var repairReminders: Bool = true
    @AppStorage("hp_reminderDaysBefore")    var reminderDaysBefore: Int = 3

    @Published var currentUser: AppUser? = nil
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastIsError: Bool = false

    var preferredColorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    init() {
        loadUser()
    }

    // MARK: - Auth
    func signUp(name: String, email: String, password: String) -> Bool {
        guard !name.isEmpty, !email.isEmpty, password.count >= 6 else { return false }
        let user = AppUser(name: name, email: email, password: password)
        saveUser(user)
        currentUser = user
        isLoggedIn = true
        return true
    }

    func logIn(email: String, password: String) -> Bool {
        guard let user = currentUser else {
            // Demo: allow any non-empty credentials
            if !email.isEmpty && !password.isEmpty {
                let demoUser = AppUser(name: "Inspector", email: email, password: password)
                saveUser(demoUser)
                currentUser = demoUser
                isLoggedIn = true
                return true
            }
            return false
        }
        if user.email == email && user.password == password {
            isLoggedIn = true
            return true
        }
        return false
    }

    func logOut() {
        isLoggedIn = false
    }

    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
            }
        }
    }

    func scheduleInspectionReminder(for building: Building, date: Date) {
        guard notificationsEnabled && inspectionReminders else { return }
        let content = UNMutableNotificationContent()
        content.title = "Inspection Due"
        content.body = "Scheduled inspection for \(building.name) is coming up."
        content.sound = .default
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "inspection-\(building.id.uuidString)",
            content: content,
            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleRepairReminder(for repair: Repair) {
        guard notificationsEnabled && repairReminders else { return }
        let content = UNMutableNotificationContent()
        content.title = "Repair Scheduled"
        content.body = "\(repair.type.rawValue) repair for \(repair.buildingName) is scheduled."
        content.sound = .default
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: repair.scheduledDate)
        comp.day = (comp.day ?? 0) - reminderDaysBefore
        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
        let request = UNNotificationRequest(
            identifier: "repair-\(repair.id.uuidString)",
            content: content,
            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Toast
    func showSuccessToast(_ message: String) {
        toastMessage = message
        toastIsError = false
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { self.showToast = false }
        }
    }

    func showErrorToast(_ message: String) {
        toastMessage = message
        toastIsError = true
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { self.showToast = false }
        }
    }

    // MARK: - Persistence
    private func saveUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Keys.user)
        }
    }

    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: Keys.user),
           let user = try? JSONDecoder().decode(AppUser.self, from: data) {
            currentUser = user
        }
    }
}

// MARK: - BuildingsViewModel
final class BuildingsViewModel: ObservableObject {
    @Published var buildings: [Building] = []

    init() { load() }

    func add(name: String, address: String, floorsCount: Int, notes: String = "") {
        let b = Building(name: name, address: address, floorsCount: floorsCount, notes: notes)
        buildings.insert(b, at: 0)
        save()
    }

    func update(_ building: Building) {
        if let idx = buildings.firstIndex(where: { $0.id == building.id }) {
            buildings[idx] = building
            save()
        }
    }

    func delete(_ building: Building) {
        buildings.removeAll { $0.id == building.id }
        save()
    }

    func addFloor(to building: Building, name: String, level: Int) {
        guard let idx = buildings.firstIndex(where: { $0.id == building.id }) else { return }
        let floor = Floor(name: name, level: level, buildingId: building.id)
        buildings[idx].floors.append(floor)
        buildings[idx].floors.sort { $0.level < $1.level }
        save()
    }

    func deleteFloor(_ floor: Floor, from building: Building) {
        guard let bIdx = buildings.firstIndex(where: { $0.id == building.id }) else { return }
        buildings[bIdx].floors.removeAll { $0.id == floor.id }
        save()
    }

    func addRoom(to floor: Floor, in building: Building, name: String, area: Double) {
        guard let bIdx = buildings.firstIndex(where: { $0.id == building.id }),
              let fIdx = buildings[bIdx].floors.firstIndex(where: { $0.id == floor.id }) else { return }
        let room = Room(name: name, area: area, floorId: floor.id)
        buildings[bIdx].floors[fIdx].rooms.append(room)
        save()
    }

    func deleteRoom(_ room: Room, from floor: Floor, in building: Building) {
        guard let bIdx = buildings.firstIndex(where: { $0.id == building.id }),
              let fIdx = buildings[bIdx].floors.firstIndex(where: { $0.id == floor.id }) else { return }
        buildings[bIdx].floors[fIdx].rooms.removeAll { $0.id == room.id }
        save()
    }

    func addStructure(to room: Room, floor: Floor, in building: Building,
                      type: StructureType, material: String, condition: ConditionState,
                      thickness: String, notes: String) {
        guard let bIdx = buildings.firstIndex(where: { $0.id == building.id }),
              let fIdx = buildings[bIdx].floors.firstIndex(where: { $0.id == floor.id }),
              let rIdx = buildings[bIdx].floors[fIdx].rooms.firstIndex(where: { $0.id == room.id }) else { return }
        let s = Structure(type: type, material: material, condition: condition,
                          thickness: thickness, notes: notes, roomId: room.id)
        buildings[bIdx].floors[fIdx].rooms[rIdx].structures.append(s)
        recalculateConditionScore(buildingIdx: bIdx)
        save()
    }

    func deleteStructure(_ structure: Structure, from room: Room, floor: Floor, in building: Building) {
        guard let bIdx = buildings.firstIndex(where: { $0.id == building.id }),
              let fIdx = buildings[bIdx].floors.firstIndex(where: { $0.id == floor.id }),
              let rIdx = buildings[bIdx].floors[fIdx].rooms.firstIndex(where: { $0.id == room.id }) else { return }
        buildings[bIdx].floors[fIdx].rooms[rIdx].structures.removeAll { $0.id == structure.id }
        recalculateConditionScore(buildingIdx: bIdx)
        save()
    }

    private func recalculateConditionScore(buildingIdx: Int) {
        let allStructures = buildings[buildingIdx].floors.flatMap { $0.rooms }.flatMap { $0.structures }
        if allStructures.isEmpty { return }
        let avg = allStructures.map { $0.condition.score }.reduce(0, +) / Double(allStructures.count)
        buildings[buildingIdx].conditionScore = avg
    }

    func building(withId id: UUID) -> Building? {
        buildings.first { $0.id == id }
    }

    var totalOpenIssueCount: Int { 0 } // computed from IssuesViewModel externally

    private func save() {
        if let data = try? JSONEncoder().encode(buildings) {
            UserDefaults.standard.set(data, forKey: Keys.buildings)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Keys.buildings),
           let decoded = try? JSONDecoder().decode([Building].self, from: data) {
            buildings = decoded
        }
    }
}

// MARK: - InspectionsViewModel
final class InspectionsViewModel: ObservableObject {
    @Published var inspections: [Inspection] = []

    init() { load() }

    func add(date: Date, inspector: String, notes: String,
             buildingId: UUID, buildingName: String, result: InspectionResult) {
        let i = Inspection(date: date, inspector: inspector, notes: notes,
                           buildingId: buildingId, buildingName: buildingName, result: result)
        inspections.insert(i, at: 0)
        save()
    }

    func update(_ inspection: Inspection) {
        if let idx = inspections.firstIndex(where: { $0.id == inspection.id }) {
            inspections[idx] = inspection
            save()
        }
    }

    func delete(_ inspection: Inspection) {
        inspections.removeAll { $0.id == inspection.id }
        save()
    }

    func inspections(for buildingId: UUID) -> [Inspection] {
        inspections.filter { $0.buildingId == buildingId }
    }

    var recent: [Inspection] { Array(inspections.prefix(5)) }

    private func save() {
        if let data = try? JSONEncoder().encode(inspections) {
            UserDefaults.standard.set(data, forKey: Keys.inspections)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Keys.inspections),
           let decoded = try? JSONDecoder().decode([Inspection].self, from: data) {
            inspections = decoded
        }
    }
}

// MARK: - IssuesViewModel
final class IssuesViewModel: ObservableObject {
    @Published var issues: [Issue] = []
    @Published var photos: [IssuePhoto] = []

    init() { load() }

    func add(type: IssueType, location: String, severity: IssueSeverity,
             description: String, buildingId: UUID, buildingName: String) {
        let i = Issue(type: type, location: location, severity: severity,
                      description: description, buildingId: buildingId, buildingName: buildingName)
        issues.insert(i, at: 0)
        save()
    }

    func update(_ issue: Issue) {
        if let idx = issues.firstIndex(where: { $0.id == issue.id }) {
            issues[idx] = issue
            save()
        }
    }

    func resolve(_ issue: Issue) {
        if let idx = issues.firstIndex(where: { $0.id == issue.id }) {
            issues[idx].status = .resolved
            save()
        }
    }

    func delete(_ issue: Issue) {
        issues.removeAll { $0.id == issue.id }
        save()
    }

    func addMeasurement(to issue: Issue, label: String, value: Double, unit: MeasurementUnit) {
        guard let idx = issues.firstIndex(where: { $0.id == issue.id }) else { return }
        let m = IssueMeasurement(label: label, value: value, unit: unit, issueId: issue.id)
        issues[idx].measurements.append(m)
        save()
    }

    func deleteMeasurement(_ measurement: IssueMeasurement, from issue: Issue) {
        guard let idx = issues.firstIndex(where: { $0.id == issue.id }) else { return }
        issues[idx].measurements.removeAll { $0.id == measurement.id }
        save()
    }

    func addPhoto(to issue: Issue, filename: String, location: String, note: String, buildingId: UUID) {
        let photo = IssuePhoto(filename: filename, location: location, note: note,
                               issueId: issue.id, buildingId: buildingId)
        guard let idx = issues.firstIndex(where: { $0.id == issue.id }) else { return }
        issues[idx].photoFilenames.append(filename)
        photos.append(photo)
        savePhotos()
        save()
    }

    func addStandalonePhoto(filename: String, location: String, note: String, buildingId: UUID) {
        let photo = IssuePhoto(filename: filename, location: location, note: note,
                               issueId: nil, buildingId: buildingId)
        photos.append(photo)
        savePhotos()
    }

    func deletePhoto(_ photo: IssuePhoto) {
        photos.removeAll { $0.id == photo.id }
        // Remove from issues
        for idx in issues.indices {
            issues[idx].photoFilenames.removeAll { $0 == photo.filename }
        }
        // Delete file
        if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = docsURL.appendingPathComponent(photo.filename)
            try? FileManager.default.removeItem(at: fileURL)
        }
        savePhotos()
        save()
    }

    func issues(for buildingId: UUID) -> [Issue] {
        issues.filter { $0.buildingId == buildingId }
    }

    var openIssues: [Issue] { issues.filter { $0.status == .open } }
    var criticalIssues: [Issue] { issues.filter { $0.severity == .critical && $0.status != .resolved } }

    func saveImageData(_ data: Data) -> String? {
        let filename = UUID().uuidString + ".jpg"
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = docsURL.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            return nil
        }
    }

    func loadImageData(filename: String) -> Data? {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = docsURL.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(issues) {
            UserDefaults.standard.set(data, forKey: Keys.issues)
        }
    }

    private func savePhotos() {
        if let data = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(data, forKey: Keys.photos)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Keys.issues),
           let decoded = try? JSONDecoder().decode([Issue].self, from: data) {
            issues = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Keys.photos),
           let decoded = try? JSONDecoder().decode([IssuePhoto].self, from: data) {
            photos = decoded
        }
    }
}

// MARK: - RepairsViewModel
final class RepairsViewModel: ObservableObject {
    @Published var repairs: [Repair] = []

    init() { load() }

    func add(type: RepairType, description: String, cost: Double,
             scheduledDate: Date, buildingId: UUID, buildingName: String, contractor: String) {
        let r = Repair(type: type, description: description, cost: cost,
                       scheduledDate: scheduledDate, buildingId: buildingId,
                       buildingName: buildingName, contractor: contractor)
        repairs.insert(r, at: 0)
        save()
    }

    func update(_ repair: Repair) {
        if let idx = repairs.firstIndex(where: { $0.id == repair.id }) {
            repairs[idx] = repair
            save()
        }
    }

    func complete(_ repair: Repair) {
        if let idx = repairs.firstIndex(where: { $0.id == repair.id }) {
            repairs[idx].status = .completed
            repairs[idx].completedDate = Date()
            save()
        }
    }

    func delete(_ repair: Repair) {
        repairs.removeAll { $0.id == repair.id }
        save()
    }

    func addTask(to repair: Repair, title: String, dueDate: Date?, priority: TaskPriority) {
        guard let idx = repairs.firstIndex(where: { $0.id == repair.id }) else { return }
        let task = RepairTask(title: title, dueDate: dueDate, repairId: repair.id, priority: priority)
        repairs[idx].tasks.append(task)
        save()
    }

    func toggleTask(_ task: RepairTask, in repair: Repair) {
        guard let rIdx = repairs.firstIndex(where: { $0.id == repair.id }),
              let tIdx = repairs[rIdx].tasks.firstIndex(where: { $0.id == task.id }) else { return }
        repairs[rIdx].tasks[tIdx].isCompleted.toggle()
        save()
    }

    func deleteTask(_ task: RepairTask, from repair: Repair) {
        guard let rIdx = repairs.firstIndex(where: { $0.id == repair.id }) else { return }
        repairs[rIdx].tasks.removeAll { $0.id == task.id }
        save()
    }

    func repairs(for buildingId: UUID) -> [Repair] {
        repairs.filter { $0.buildingId == buildingId }
    }

    var upcoming: [Repair] {
        repairs.filter { $0.status == .planned || $0.status == .inProgress }
               .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    var totalCost: Double { repairs.filter { $0.status == .completed }.map(\.cost).reduce(0,+) }
    var plannedCost: Double { repairs.filter { $0.status == .planned }.map(\.cost).reduce(0,+) }

    var allTasks: [RepairTask] { repairs.flatMap(\.tasks) }
    var pendingTasks: [RepairTask] { allTasks.filter { !$0.isCompleted } }

    private func save() {
        if let data = try? JSONEncoder().encode(repairs) {
            UserDefaults.standard.set(data, forKey: Keys.repairs)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Keys.repairs),
           let decoded = try? JSONDecoder().decode([Repair].self, from: data) {
            repairs = decoded
        }
    }
}

// MARK: - MaterialsViewModel
final class MaterialsViewModel: ObservableObject {
    @Published var materials: [Material] = []

    init() { load() }

    func add(name: String, type: MaterialType, quantity: Double, unit: String,
             supplier: String, notes: String, buildingId: UUID?) {
        let m = Material(name: name, type: type, quantity: quantity, unit: unit,
                         supplier: supplier, notes: notes, buildingId: buildingId)
        materials.insert(m, at: 0)
        save()
    }

    func update(_ material: Material) {
        if let idx = materials.firstIndex(where: { $0.id == material.id }) {
            materials[idx] = material
            save()
        }
    }

    func delete(_ material: Material) {
        materials.removeAll { $0.id == material.id }
        save()
    }

    func materials(for buildingId: UUID) -> [Material] {
        materials.filter { $0.buildingId == buildingId }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(materials) {
            UserDefaults.standard.set(data, forKey: Keys.materials)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Keys.materials),
           let decoded = try? JSONDecoder().decode([Material].self, from: data) {
            materials = decoded
        }
    }
}

// MARK: - ActivityViewModel
final class ActivityViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var notifications: [NotificationItem] = []

    init() { load() }

    func log(type: ActivityType, description: String, relatedId: UUID? = nil) {
        let activity = Activity(type: type, description: description, relatedId: relatedId)
        activities.insert(activity, at: 0)
        if activities.count > 200 { activities = Array(activities.prefix(200)) }
        save()
    }

    func addNotification(title: String, body: String, type: NotificationItemType, relatedId: UUID? = nil) {
        let n = NotificationItem(title: title, body: body, type: type, relatedId: relatedId)
        notifications.insert(n, at: 0)
        saveNotifications()
    }

    func markRead(_ notification: NotificationItem) {
        if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[idx].isRead = true
            saveNotifications()
        }
    }

    func markAllRead() {
        notifications = notifications.map { var n = $0; n.isRead = true; return n }
        saveNotifications()
    }

    func deleteNotification(_ notification: NotificationItem) {
        notifications.removeAll { $0.id == notification.id }
        saveNotifications()
    }

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    private func save() {
        if let data = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(data, forKey: Keys.activities)
        }
    }

    private func saveNotifications() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: Keys.notifications)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Keys.activities),
           let decoded = try? JSONDecoder().decode([Activity].self, from: data) {
            activities = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Keys.notifications),
           let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data) {
            notifications = decoded
        }
    }
}
