//
//  BookmarkInfoView.swift
//  HatebLine
//

import SwiftUI

struct BookmarkInfoView: View {
    @ObservedObject var viewModel: BookmarkInfoViewModel

    var body: some View {
        Group {
            if let bookmark = viewModel.bookmark {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Page Header
                        pageHeaderSection(bookmark: bookmark)

                        Divider()

                        // Summary
                        if let summary = bookmark.page?.summary, !summary.isEmpty {
                            summarySection(summary: summary)
                            Divider()
                        }

                        // Bookmark Info
                        bookmarkInfoSection(bookmark: bookmark)

                        Spacer()
                    }
                    .padding()
                }
            } else {
                VStack {
                    Spacer()
                    Text(NSLocalizedString("info.noBookmarkSelected", value: "No bookmark selected", comment: ""))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 380, minHeight: 400)
    }

    // MARK: - Sections

    @ViewBuilder
    private func pageHeaderSection(bookmark: Bookmark) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        if let favicon = bookmark.page?.favicon {
                            Image(nsImage: favicon)
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bookmark.page?.title ?? NSLocalizedString("info.noTitle", value: "No title", comment: ""))
                                .font(.headline)
                                .lineLimit(3)
                            if let count = bookmark.page?.count {
                                Text("\(count) users")
                                    .font(.subheadline)
                                    .foregroundColor(count.intValue > 5 ? .red : .secondary)
                                    .fontWeight(count.intValue > 5 ? .bold : .regular)
                            }
                        }
                    }
                }

                Spacer()
                
                if let entryImage = bookmark.page?.entryImage {
                    Image(nsImage: entryImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipped()
                        .cornerRadius(6)
                }
            }
            
            if let urlString = bookmark.page?.url,
               let url = URL(string: urlString) {
                Link(destination: url) {
                    Text(urlString)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func summarySection(summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("info.summary", value: "Summary", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(summary)
                .font(.body)
        }
    }

    @ViewBuilder
    private func bookmarkInfoSection(bookmark: Bookmark) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("info.bookmarkInfo", value: "Bookmark Info", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)

            // User
            HStack(spacing: 10) {
                if let profileImage = bookmark.user?.profileImage {
                    Image(nsImage: profileImage)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(bookmark.user?.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let date = bookmark.date {
                        (Text(date, style: .date) + Text(" ") + Text(date, style: .time))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Comment
            if let comment = bookmark.comment, !comment.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("info.comment", value: "Comment", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(comment)
                        .font(.body)
                }
            }

            // Tags
            if let tags = bookmark.tags as? Set<Tag>, !tags.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("info.tags", value: "Tags", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TagsView(tags: Array(tags))
                }
            }
        }
    }
}

// MARK: - Simple Tag View (compatible with older macOS)

struct TagsView: View {
    let tags: [Tag]

    var body: some View {
        // シンプルな横並び（折り返しなし）
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag.name ?? "")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                }
            }
        }
    }
}

// MARK: - ViewModel

class BookmarkInfoViewModel: ObservableObject {
    @Published var bookmark: Bookmark?

    private var entryImageObservation: NSKeyValueObservation?
    private var faviconObservation: NSKeyValueObservation?
    private var profileImageObservation: NSKeyValueObservation?

    func update(with bookmark: Bookmark?) {
        entryImageObservation = nil
        faviconObservation = nil
        profileImageObservation = nil

        self.bookmark = bookmark

        guard let bookmark = bookmark else { return }

        entryImageObservation = bookmark.page?.observe(\.entryImage, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }

        faviconObservation = bookmark.page?.observe(\.favicon, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }

        profileImageObservation = bookmark.user?.observe(\.profileImage, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
}
