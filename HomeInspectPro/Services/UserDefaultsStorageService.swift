import Foundation

final class UserDefaultsStorageService: StorageService {
    private let store = UserDefaults(suiteName: "group.homeinspect.storage")!
    private let cache = UserDefaults.standard
    
    private enum Key {
        static let tracking = "hi_tracking_payload"
        static let navigation = "hi_navigation_payload"
        static let endpoint = "hi_endpoint_target"
        static let mode = "hi_mode_active"
        static let firstLaunch = "hi_first_launch_flag"
        static let permGranted = "hi_perm_granted"
        static let permDenied = "hi_perm_denied"
        static let permDate = "hi_perm_date"
    }
    
    func saveTracking(_ data: [String: String]) {
        if let json = toJSON(data) {
            store.set(json, forKey: Key.tracking)
        }
    }
    
    func saveNavigation(_ data: [String: String]) {
        if let json = toJSON(data) {
            let encoded = encode(json)
            store.set(encoded, forKey: Key.navigation)
        }
    }
    
    func saveEndpoint(_ url: String) {
        store.set(url, forKey: Key.endpoint)
        cache.set(url, forKey: Key.endpoint)
    }
    
    func saveMode(_ mode: String) {
        store.set(mode, forKey: Key.mode)
    }
    
    func savePermissions(_ permission: RequestContext.PermissionData) {
        store.set(permission.isGranted, forKey: Key.permGranted)
        store.set(permission.isDenied, forKey: Key.permDenied)
        if let date = permission.lastAsked {
            store.set(date.timeIntervalSince1970 * 1000, forKey: Key.permDate)
        }
    }
    
    func markLaunched() {
        store.set(true, forKey: Key.firstLaunch)
    }
    
    func loadState() -> StoredState {
        var tracking: [String: String] = [:]
        if let json = store.string(forKey: Key.tracking),
           let dict = fromJSON(json) {
            tracking = dict
        }
        
        var navigation: [String: String] = [:]
        if let encoded = store.string(forKey: Key.navigation),
           let json = decode(encoded),
           let dict = fromJSON(json) {
            navigation = dict
        }
        
        let endpoint = store.string(forKey: Key.endpoint)
        let mode = store.string(forKey: Key.mode)
        let isFirstLaunch = !store.bool(forKey: Key.firstLaunch)
        
        let granted = store.bool(forKey: Key.permGranted)
        let denied = store.bool(forKey: Key.permDenied)
        let ts = store.double(forKey: Key.permDate)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        return StoredState(
            tracking: tracking,
            navigation: navigation,
            endpoint: endpoint,
            mode: mode,
            isFirstLaunch: isFirstLaunch,
            permission: StoredState.PermissionData(
                isGranted: granted,
                isDenied: denied,
                lastAsked: date
            )
        )
    }
    
    private func toJSON(_ dict: [String: String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict.mapValues { $0 as Any }),
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }
    
    private func fromJSON(_ string: String) -> [String: String]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dict.mapValues { "\($0)" }
    }
    
    private func encode(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "<")
            .replacingOccurrences(of: "+", with: ">")
    }
    
    private func decode(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: "<", with: "=")
            .replacingOccurrences(of: ">", with: "+")
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}
