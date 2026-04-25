import SwiftUI

struct FeedView: View {
    @EnvironmentObject var appState: AppState
    @State private var articles: [Article] = []
    @State private var isLoading = true
    @State private var showSettings = false
    @State private var selectedArticle: Article?
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && articles.isEmpty {
                    VStack {
                        ProgressView("Loading articles...")
                            .padding()
                    }
                } else if articles.isEmpty {
                    VStack(spacing: 20) {
                        Text("No more articles right now.")
                            .font(.headline)
                        Button(action: { loadFeed() }) {
                            Text("Refresh")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    ZStack {
                        ForEach(articles.indices.reversed(), id: \.self) { index in
                            CardView(article: articles[index], onRemove: { swipedRight in
                                handleSwipe(article: articles[index], swipedRight: swipedRight)
                            }, onOpenDetail: {
                                selectedArticle = articles[index]
                            })
                            .padding()
                            .zIndex(Double(articles.count - index))
                        }
                    }
                }
            }
            .navigationBarItems(trailing: Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gearshape")
                    .imageScale(.large)
            })
            .navigationBarTitle("WikiSwipe", displayMode: .inline)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .sheet(item: $selectedArticle) { article in
                NavigationView {
                    DetailView(article: article)
                }
            }
        }
        .onAppear {
            if articles.isEmpty {
                loadFeed()
            }
        }
    }
    
    func loadFeed() {
        guard let userId = appState.userId else { return }
        isLoading = true
        Task {
            do {
                let fetched = try await APIClient.shared.fetchFeed(userId: userId)
                await MainActor.run {
                    // avoid duplicates
                    let newArticles = fetched.filter { newArt in
                        !self.articles.contains(where: { $0.id == newArt.id })
                    }
                    self.articles.append(contentsOf: newArticles)
                    self.isLoading = false
                }
            } catch {
                print("Error loading feed: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    func handleSwipe(article: Article, swipedRight: Bool) {
        guard let userId = appState.userId else { return }
        
        // Remove article from array
        withAnimation {
            articles.removeAll { $0.id == article.id }
        }
        
        // Record swipe in background
        Task {
            do {
                try await APIClient.shared.swipe(userId: userId, articleId: article.id, swipedRight: swipedRight)
            } catch {
                print("Error recording swipe: \(error)")
            }
        }
        
        // Load more if getting empty
        if articles.count < 3 {
            loadFeed()
        }
    }
}
