import Foundation
import SwiftUI

// MARK: - User
struct AppUser: Codable, Equatable {
    var name: String
    var email: String
    var password: String
}

// MARK: - Building
struct Building: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var address: String
    var floorsCount: Int
    var conditionScore: Double = 80
    var createdAt: Date = Date()
    var floors: [Floor] = []
    var notes: String = ""
}

// MARK: - Floor
struct Floor: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var level: Int
    var buildingId: UUID
    var rooms: [Room] = []
}

// MARK: - Room
struct Room: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var area: Double
    var floorId: UUID
    var structures: [Structure] = []
}

// MARK: - Structure
enum StructureType: String, Codable, CaseIterable {
    case wall       = "Wall"
    case ceiling    = "Ceiling"
    case floor      = "Floor"
    case roof       = "Roof"
    case foundation = "Foundation"
    case window     = "Window"
    case door       = "Door"

    var icon: String {
        switch self {
        case .wall:       return "square.split.2x1"
        case .ceiling:    return "square.topthird.inset.filled"
        case .floor:      return "square.bottomthird.inset.filled"
        case .roof:       return "house.fill"
        case .foundation: return "building.columns.fill"
        case .window:     return "rectangle.split.2x1"
        case .door:       return "door.left.hand.closed"
        }
    }
}

enum ConditionState: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good      = "Good"
    case fair      = "Fair"
    case poor      = "Poor"
    case critical  = "Critical"

    var score: Double {
        switch self {
        case .excellent: return 95
        case .good:      return 75
        case .fair:      return 55
        case .poor:      return 30
        case .critical:  return 12
        }
    }

    var colorHex: String {
        switch self {
        case .excellent: return "#34C759"
        case .good:      return "#A8D96A"
        case .fair:      return "#FF9F0A"
        case .poor:      return "#FF6B35"
        case .critical:  return "#FF3B30"
        }
    }

    var color: Color { Color(hex: colorHex) }
}

struct Structure: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var type: StructureType
    var material: String
    var condition: ConditionState
    var thickness: String = ""
    var notes: String = ""
    var roomId: UUID
}

// MARK: - Inspection
struct Inspection: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var inspector: String
    var notes: String
    var buildingId: UUID
    var buildingName: String
    var result: InspectionResult = .passed
    var createdAt: Date = Date()
}

enum InspectionResult: String, Codable, CaseIterable {
    case passed  = "Passed"
    case warning = "Warning"
    case failed  = "Failed"

    var color: Color {
        switch self {
        case .passed:  return .hpSuccess
        case .warning: return .hpWarning
        case .failed:  return .hpDanger
        }
    }

    var icon: String {
        switch self {
        case .passed:  return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failed:  return "xmark.seal.fill"
        }
    }
}

// MARK: - Issue
enum IssueType: String, Codable, CaseIterable {
    case crack       = "Crack"
    case leak        = "Leak"
    case humidity    = "Humidity"
    case deformation = "Deformation"
    case corrosion   = "Corrosion"
    case settlement  = "Settlement"
    case mold        = "Mold"
    case other       = "Other"

    var icon: String {
        switch self {
        case .crack:       return "exclamationmark.triangle.fill"
        case .leak:        return "drop.fill"
        case .humidity:    return "humidity.fill"
        case .deformation: return "waveform.path"
        case .corrosion:   return "bolt.slash.fill"
        case .settlement:  return "arrow.down.to.line"
        case .mold:        return "allergens"
        case .other:       return "questionmark.circle.fill"
        }
    }
}

enum IssueSeverity: String, Codable, CaseIterable {
    case low      = "Low"
    case medium   = "Medium"
    case high     = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low:      return .hpSuccess
        case .medium:   return .hpWarning
        case .high:     return Color(hex: "#FF6B35")
        case .critical: return .hpDanger
        }
    }

    var priority: Int {
        switch self {
        case .low: return 0; case .medium: return 1; case .high: return 2; case .critical: return 3
        }
    }
}

enum IssueStatus: String, Codable, CaseIterable {
    case open       = "Open"
    case inProgress = "In Progress"
    case resolved   = "Resolved"

    var color: Color {
        switch self {
        case .open:       return .hpDanger
        case .inProgress: return .hpWarning
        case .resolved:   return .hpSuccess
        }
    }
}

struct Issue: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var type: IssueType
    var location: String
    var severity: IssueSeverity
    var status: IssueStatus = .open
    var description: String = ""
    var createdAt: Date = Date()
    var buildingId: UUID
    var buildingName: String
    var photoFilenames: [String] = []
    var measurements: [IssueMeasurement] = []
}

// MARK: - Photo
struct IssuePhoto: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var filename: String
    var location: String
    var note: String = ""
    var createdAt: Date = Date()
    var issueId: UUID?
    var buildingId: UUID?
}

// MARK: - Measurement
struct IssueMeasurement: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var label: String
    var value: Double
    var unit: MeasurementUnit
    var issueId: UUID
    var createdAt: Date = Date()
}

enum MeasurementUnit: String, Codable, CaseIterable {
    case mm  = "mm"
    case cm  = "cm"
    case m   = "m"
    case inch = "in"
    case ft  = "ft"
    case kg  = "kg"
    case percent = "%"
}

// MARK: - Material
struct Material: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: MaterialType
    var quantity: Double
    var unit: String
    var supplier: String = ""
    var notes: String = ""
    var buildingId: UUID?
}

enum MaterialType: String, Codable, CaseIterable {
    case concrete   = "Concrete"
    case brick      = "Brick"
    case wood       = "Wood"
    case steel      = "Steel"
    case glass      = "Glass"
    case insulation = "Insulation"
    case plaster    = "Plaster"
    case tile       = "Tile"
    case other      = "Other"

    var icon: String {
        switch self {
        case .concrete:   return "square.fill"
        case .brick:      return "rectangle.grid.2x2.fill"
        case .wood:       return "leaf.fill"
        case .steel:      return "bolt.fill"
        case .glass:      return "square.on.square.fill"
        case .insulation: return "thermometer"
        case .plaster:    return "paintbrush.fill"
        case .tile:       return "rectangle.split.3x1.fill"
        case .other:      return "cube.fill"
        }
    }
}

// MARK: - Repair
enum RepairType: String, Codable, CaseIterable {
    case structural     = "Structural"
    case waterproofing  = "Waterproofing"
    case electrical     = "Electrical"
    case plumbing       = "Plumbing"
    case painting       = "Painting"
    case insulation     = "Insulation"
    case roofing        = "Roofing"
    case foundation     = "Foundation"
    case other          = "Other"

    var icon: String {
        switch self {
        case .structural:    return "wrench.and.screwdriver.fill"
        case .waterproofing: return "drop.fill"
        case .electrical:    return "bolt.fill"
        case .plumbing:      return "pipe.and.drop"
        case .painting:      return "paintbrush.fill"
        case .insulation:    return "thermometer"
        case .roofing:       return "house.fill"
        case .foundation:    return "building.columns.fill"
        case .other:         return "hammer.fill"
        }
    }
}

enum RepairStatus: String, Codable, CaseIterable {
    case planned    = "Planned"
    case inProgress = "In Progress"
    case completed  = "Completed"
    case cancelled  = "Cancelled"

    var color: Color {
        switch self {
        case .planned:    return .hpBlue
        case .inProgress: return .hpWarning
        case .completed:  return .hpSuccess
        case .cancelled:  return Color(hex: "#8E8E93")
        }
    }
}

struct Repair: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var type: RepairType
    var description: String
    var cost: Double
    var status: RepairStatus = .planned
    var scheduledDate: Date = Date()
    var completedDate: Date?
    var buildingId: UUID
    var buildingName: String
    var tasks: [RepairTask] = []
    var createdAt: Date = Date()
    var contractor: String = ""
}

struct RepairTask: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date?
    var repairId: UUID
    var priority: TaskPriority = .medium
}

enum TaskPriority: String, Codable, CaseIterable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"

    var color: Color {
        switch self {
        case .low:    return .hpSuccess
        case .medium: return .hpWarning
        case .high:   return .hpDanger
        }
    }
}

// MARK: - Activity
struct Activity: Codable, Identifiable {
    var id: UUID = UUID()
    var type: ActivityType
    var description: String
    var timestamp: Date = Date()
    var relatedId: UUID?
}

enum ActivityType: String, Codable {
    case buildingAdded   = "Building Added"
    case floorAdded      = "Floor Added"
    case roomAdded       = "Room Added"
    case inspectionAdded = "Inspection Added"
    case issueAdded      = "Issue Added"
    case issueResolved   = "Issue Resolved"
    case repairAdded     = "Repair Added"
    case repairCompleted = "Repair Completed"
    case photoAdded      = "Photo Added"
    case measurementAdded = "Measurement Added"
    case materialAdded   = "Material Added"

    var icon: String {
        switch self {
        case .buildingAdded:    return "building.2.fill"
        case .floorAdded:       return "square.stack.3d.up.fill"
        case .roomAdded:        return "door.left.hand.open"
        case .inspectionAdded:  return "magnifyingglass"
        case .issueAdded:       return "exclamationmark.triangle.fill"
        case .issueResolved:    return "checkmark.circle.fill"
        case .repairAdded:      return "wrench.fill"
        case .repairCompleted:  return "checkmark.seal.fill"
        case .photoAdded:       return "camera.fill"
        case .measurementAdded: return "ruler.fill"
        case .materialAdded:    return "cube.box.fill"
        }
    }

    var color: Color {
        switch self {
        case .buildingAdded, .floorAdded, .roomAdded: return .hpBlue
        case .inspectionAdded:  return .hpLightBlue
        case .issueAdded:       return .hpDanger
        case .issueResolved:    return .hpSuccess
        case .repairAdded:      return .hpWarning
        case .repairCompleted:  return .hpSuccess
        case .photoAdded:       return Color(hex: "#AF52DE")
        case .measurementAdded: return .hpAccent
        case .materialAdded:    return Color(hex: "#5AC8FA")
        }
    }
}

// MARK: - Notification Item
struct NotificationItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var type: NotificationItemType
    var isRead: Bool = false
    var createdAt: Date = Date()
    var relatedId: UUID?
}

enum NotificationItemType: String, Codable {
    case inspectionDue  = "Inspection Due"
    case repairNeeded   = "Repair Needed"
    case issueDetected  = "Issue Detected"
    case repairComplete = "Repair Complete"

    var icon: String {
        switch self {
        case .inspectionDue:  return "calendar.badge.exclamationmark"
        case .repairNeeded:   return "wrench.and.screwdriver.fill"
        case .issueDetected:  return "exclamationmark.triangle.fill"
        case .repairComplete: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Date Helpers
extension Date {
    var shortFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: self)
    }

    var timeFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: self)
    }

    var relativeFormatted: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: self, relativeTo: Date())
    }

    var dayMonthFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: self)
    }
}
