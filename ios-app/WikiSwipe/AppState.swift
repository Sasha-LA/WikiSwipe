import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var userId: UUID? {
        didSet {
            UserDefaults.standard.set(userId?.uuidString, forKey: "userId")
        }
    }
    @Published var hasFinishedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasFinishedOnboarding, forKey: "hasFinishedOnboarding")
        }
    }
    
    init() {
        if let uuidStr = UserDefaults.standard.string(forKey: "userId"), let uuid = UUID(uuidString: uuidStr) {
            self.userId = uuid
        } else {
            let newUUID = UUID()
            self.userId = newUUID
        }
        self.hasFinishedOnboarding = UserDefaults.standard.bool(forKey: "hasFinishedOnboarding")
    }
}
