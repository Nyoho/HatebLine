import Cocoa
import QuartzCore

class SkeletonCommentView: NSView {
    override var isFlipped: Bool { true }

    private var boxes: [NSBox] = []
    private let shimmerLayer = CAGradientLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupBoxes()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBoxes()
    }

    private func skeletonColor() -> NSColor {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? NSColor(white: 0.35, alpha: 1) : NSColor(white: 0.75, alpha: 1)
    }

    private func shimmerHighlight() -> CGColor {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark
            ? NSColor(white: 0.55, alpha: 0.4).cgColor
            : NSColor(white: 1.0,  alpha: 0.55).cgColor
    }

    private func makeBox(cornerRadius: CGFloat = 4) -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.borderWidth = 0
        box.cornerRadius = cornerRadius
        box.fillColor = skeletonColor()
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }

    private func setupBoxes() {
        let avatar = makeBox(cornerRadius: 21)
        let name   = makeBox()
        let date   = makeBox()
        let line1  = makeBox()
        let line2  = makeBox()

        boxes = [avatar, name, date, line1, line2]
        boxes.forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 72),

            avatar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            avatar.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 42),
            avatar.heightAnchor.constraint(equalToConstant: 42),

            name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            name.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            name.widthAnchor.constraint(equalToConstant: 100),
            name.heightAnchor.constraint(equalToConstant: 12),

            date.leadingAnchor.constraint(equalTo: name.trailingAnchor, constant: 8),
            date.centerYAnchor.constraint(equalTo: name.centerYAnchor),
            date.widthAnchor.constraint(equalToConstant: 64),
            date.heightAnchor.constraint(equalToConstant: 10),

            line1.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            line1.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 10),
            line1.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            line1.heightAnchor.constraint(equalToConstant: 10),

            line2.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            line2.topAnchor.constraint(equalTo: line1.bottomAnchor, constant: 6),
            line2.widthAnchor.constraint(equalTo: line1.widthAnchor, multiplier: 0.6),
            line2.heightAnchor.constraint(equalToConstant: 10),
        ])
    }

    // MARK: - Shimmer

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            if shimmerLayer.superlayer == nil {
                shimmerLayer.colors = [NSColor.clear.cgColor, shimmerHighlight(), NSColor.clear.cgColor]
                shimmerLayer.locations = [-1.0, -0.5, 0.0]
                shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
                shimmerLayer.endPoint   = CGPoint(x: 1, y: 0.5)
                shimmerLayer.zPosition  = 1000
                shimmerLayer.frame = bounds
                layer?.addSublayer(shimmerLayer)
            }
            let anim = CABasicAnimation(keyPath: "locations")
            anim.fromValue   = [-1.0, -0.5, 0.0]
            anim.toValue     = [1.0,   1.5,  2.0]
            anim.duration    = 1.4
            anim.repeatCount = .infinity
            shimmerLayer.add(anim, forKey: "shimmer")
        } else {
            shimmerLayer.removeAnimation(forKey: "shimmer")
        }
    }

    override func layout() {
        super.layout()
        shimmerLayer.frame = bounds
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        let color = skeletonColor()
        boxes.forEach { $0.fillColor = color }
        shimmerLayer.colors = [NSColor.clear.cgColor, shimmerHighlight(), NSColor.clear.cgColor]
    }
}
