import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var topics = ["History", "Space", "Psychology", "Business", "Science", "Technology", "Cars", "Health", "Art", "Geography"]
    @State private var selectedTopics: Set<String> = []
    @State private var isLoading = false
    @State private var newTopic = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("WikiSwipe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                Text("Select topics you're interested in:")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                HStack {
                    TextField("Or type a custom topic...", text: $newTopic)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        let trimmed = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !topics.contains(trimmed) {
                            topics.append(trimmed)
                            selectedTopics.insert(trimmed)
                            newTopic = ""
                        }
                    }) {
                        Text("Add")
                            .fontWeight(.bold)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 15) {
                        ForEach(topics, id: \.self) { topic in
                            Button(action: {
                                if selectedTopics.contains(topic) {
                                    selectedTopics.remove(topic)
                                } else {
                                    selectedTopics.insert(topic)
                                }
                            }) {
                                Text(topic)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedTopics.contains(topic) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTopics.contains(topic) ? .white : .primary)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(action: {
                    submit()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    } else {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTopics.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
                .disabled(selectedTopics.isEmpty || isLoading)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    func submit() {
        guard let userId = appState.userId else { return }
        isLoading = true
        Task {
            do {
                try await APIClient.shared.onboarding(userId: userId, interests: Array(selectedTopics))
                await MainActor.run {
                    appState.hasFinishedOnboarding = true
                    isLoading = false
                }
            } catch {
                print("Onboarding error: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}
