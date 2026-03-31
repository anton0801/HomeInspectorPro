import Foundation
import FirebaseDatabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UserNotifications

protocol StorageService {
    func saveTracking(_ data: [String: String])
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func savePermissions(_ permission: RequestContext.PermissionData)
    func markLaunched()
    func loadState() -> StoredState
}

struct StoredState {
    var tracking: [String: String]
    var navigation: [String: String]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permission: PermissionData
    
    struct PermissionData {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
    }
}

protocol ValidationService {
    func validate() async throws -> Bool
}

protocol NetworkService {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchEndpoint(tracking: [String: Any]) async throws -> String
}

protocol NotificationService {
    func requestPermission(completion: @escaping (Bool) -> Void)
    func registerForPush()
}

final class SystemNotificationService: NotificationService {
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func registerForPush() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}

struct HomeInspectConfig {
    static let appID = "6761063299"
    static let devKey = "gR5gk6q7ZCMfQGgof5M3W4"
}
