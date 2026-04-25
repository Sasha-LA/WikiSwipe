import Foundation

class APIClient {
    static let shared = APIClient()
    let baseURL = "http://localhost:8000"
    
    func onboarding(userId: UUID, interests: [String]) async throws {
        let url = URL(string: "\(baseURL)/onboarding")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["user_id": userId.uuidString, "interests": interests]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchFeed(userId: UUID) async throws -> [Article] {
        let url = URL(string: "\(baseURL)/feed?user_id=\(userId.uuidString)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([Article].self, from: data)
    }
    
    func swipe(userId: UUID, articleId: Int, swipedRight: Bool) async throws {
        let url = URL(string: "\(baseURL)/swipe")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["user_id": userId.uuidString, "article_id": articleId, "swiped_right": swipedRight]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let _ = try await URLSession.shared.data(for: request)
    }
}
