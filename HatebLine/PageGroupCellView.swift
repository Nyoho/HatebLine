//
//  PageGroupCellView.swift
//  HatebLine
//

import Cocoa

class PageGroupCellView: NSTableCellView {
    @IBOutlet var titleTextField: NSTextField!
    @IBOutlet var countTextField: NSTextField!
    @IBOutlet var faviconImageView: NSImageView!
    @IBOutlet var entryImageView: NSImageView!
    @IBOutlet var usersStackView: NSStackView!

    private var faviconObservation: NSKeyValueObservation?
    private var entryImageObservation: NSKeyValueObservation?
    private var userObservations: [NSKeyValueObservation] = []
    private weak var currentPage: Page?

    override func prepareForReuse() {
        super.prepareForReuse()
        faviconObservation = nil
        entryImageObservation = nil
        userObservations.removeAll()
        currentPage = nil
        usersStackView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureTitleTextField()
    }

    private func configureTitleTextField() {
        titleTextField?.maximumNumberOfLines = 3
        titleTextField?.cell?.wraps = true
        titleTextField?.cell?.truncatesLastVisibleLine = true
    }

    func configure(with page: Page, bookmarks: [Bookmark]) {
        currentPage = page

        titleTextField?.stringValue = page.title ?? ""
        countTextField?.stringValue = page.countString ?? ""
        faviconImageView?.image = page.favicon
        entryImageView?.image = page.entryImage
        entryImageView?.isHidden = page.entryImage == nil

        if let count = page.count, count.intValue > 5 {
            countTextField?.font = NSFont.boldSystemFont(ofSize: countTextField.font?.pointSize ?? 12)
            countTextField?.textColor = NSColor.systemRed
        } else {
            countTextField?.font = NSFont.systemFont(ofSize: countTextField.font?.pointSize ?? 12)
            countTextField?.textColor = NSColor.secondaryLabelColor
        }

        faviconObservation = page.observe(\.favicon, options: [.new]) { [weak self] page, _ in
            DispatchQueue.main.async {
                self?.faviconImageView?.image = page.favicon
            }
        }

        entryImageObservation = page.observe(\.entryImage, options: [.new]) { [weak self] page, _ in
            DispatchQueue.main.async {
                self?.entryImageView?.image = page.entryImage
                self?.entryImageView?.isHidden = page.entryImage == nil
            }
        }

        configureUsersStack(with: bookmarks)
    }

    private func configureUsersStack(with bookmarks: [Bookmark]) {
        for subview in usersStackView?.arrangedSubviews ?? [] {
            usersStackView?.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        userObservations.removeAll()

        for bookmark in bookmarks {
            let userView = createUserView(for: bookmark)
            usersStackView?.addArrangedSubview(userView)

            if let user = bookmark.user {
                let observation = user.observe(\.profileImage, options: [.new]) { [weak userView] user, _ in
                    DispatchQueue.main.async {
                        if let imageView = userView?.subviews.first as? NSImageView {
                            imageView.image = user.profileImage
                        }
                    }
                }
                userObservations.append(observation)
            }
        }

        usersStackView?.needsLayout = true
        usersStackView?.layoutSubtreeIfNeeded()
        self.needsLayout = true
        self.invalidateIntrinsicContentSize()
    }

    private func createUserView(for bookmark: Bookmark) -> NSView {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let profileImageView = NSImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.image = bookmark.user?.profileImage
        profileImageView.wantsLayer = true
        profileImageView.layer?.cornerRadius = 12
        profileImageView.layer?.masksToBounds = true
        containerView.addSubview(profileImageView)

        let nameLabel = NSTextField(labelWithString: bookmark.user?.name ?? "")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        nameLabel.textColor = NSColor.labelColor
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        containerView.addSubview(nameLabel)

        let dateLabel = NSTextField(labelWithString: bookmark.timeAgo ?? "")
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = NSFont.systemFont(ofSize: 10)
        dateLabel.textColor = NSColor.secondaryLabelColor
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        containerView.addSubview(dateLabel)

        let commentLabel = NSTextField(wrappingLabelWithString: bookmark.comment ?? "")
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.font = NSFont.systemFont(ofSize: 12)
        commentLabel.textColor = NSColor.labelColor
        commentLabel.isHidden = bookmark.isCommentEmpty
        containerView.addSubview(commentLabel)

        let leftMargin: CGFloat = 32

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leftMargin),
            profileImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            profileImageView.widthAnchor.constraint(equalToConstant: 24),
            profileImageView.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),

            dateLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            dateLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8),

            commentLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            commentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            commentLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8),
            commentLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])

        containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true

        return containerView
    }
}
