import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    let topics = ["History", "Space", "Psychology", "Business", "Science", "Technology", "Cars", "Health", "Art", "Geography"]
    @State private var selectedTopics: Set<String> = []
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Manage your interests")) {
                    ForEach(topics, id: \.self) { topic in
                        Button(action: {
                            if selectedTopics.contains(topic) {
                                selectedTopics.remove(topic)
                            } else {
                                selectedTopics.insert(topic)
                            }
                        }) {
                            HStack {
                                Text(topic)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedTopics.contains(topic) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: saveChanges) {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(selectedTopics.isEmpty || isSaving)
                    
                    Button(action: resetOnboarding) {
                        Text("Reset App (Logout)")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func saveChanges() {
        guard let userId = appState.userId else { return }
        isSaving = true
        Task {
            do {
                try await APIClient.shared.onboarding(userId: userId, interests: Array(selectedTopics))
                await MainActor.run {
                    isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Error saving settings: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
    
    func resetOnboarding() {
        appState.hasFinishedOnboarding = false
        presentationMode.wrappedValue.dismiss()
    }
}
