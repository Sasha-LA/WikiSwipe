import SwiftUI

struct DetailView: View {
    let article: Article
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = article.imageUrl {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .overlay(ProgressView())
                            .frame(height: 300)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(article.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let tags = article.topics {
                        HStack {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    
                    if let summary = article.summary {
                        Text(summary)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source: Wikipedia")
                            .font(.headline)
                        Text("Content based on Wikipedia (CC BY-SA 4.0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let wikiUrl = article.wikiUrl {
                            Link("Open Original Article in Safari", destination: wikiUrl)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.top, 10)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
