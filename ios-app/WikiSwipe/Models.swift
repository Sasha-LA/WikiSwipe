import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
    }
}

struct Article: Codable, Identifiable {
    let id: Int
    let title: String
    let summary: String?
    let wikiUrl: URL?
    let imageUrl: URL?
    let topics: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case wikiUrl = "wiki_url"
        case imageUrl = "image_url"
        case topics
    }
}
