import Firebase
import FirebaseDatabase


final class FirebaseValidationService: ValidationService {
    func validate() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child("users/log/data")
                .observeSingleEvent(of: .value) { snapshot in
                    if let url = snapshot.value as? String, !url.isEmpty, URL(string: url) != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}
