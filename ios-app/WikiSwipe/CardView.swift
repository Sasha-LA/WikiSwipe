import SwiftUI

struct CardView: View {
    let article: Article
    var onRemove: (Bool) -> Void
    var onOpenDetail: (() -> Void)?
    
    @State private var translation: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                if let imageUrl = article.imageUrl {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .overlay(ProgressView())
                    }
                    .frame(height: geometry.size.height * 0.45)
                    .clipped()
                } else {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                        .frame(height: geometry.size.height * 0.45)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let tags = article.topics {
                        HStack {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    if let summary = article.summary {
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(5)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Divider()
                        HStack {
                            Text("Source: Wikipedia")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                            if let wikiUrl = article.wikiUrl {
                                Button(action: {
                                    onOpenDetail?()
                                }) {
                                    Text("Read more")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .offset(x: translation.width, y: translation.height)
            .rotationEffect(.degrees(Double(translation.width / geometry.size.width) * 25), anchor: .bottom)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        translation = value.translation
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        if value.translation.width > threshold {
                            onRemove(true)
                        } else if value.translation.width < -threshold {
                            onRemove(false)
                        } else {
                            withAnimation(.interactiveSpring()) {
                                translation = .zero
                            }
                        }
                    }
            )
        }
    }
}
