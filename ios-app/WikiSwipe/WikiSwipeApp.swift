import SwiftUI

@main
struct WikiSwipeApp: App {
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.hasFinishedOnboarding {
                FeedView()
                    .environmentObject(appState)
            } else {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
    }
}
