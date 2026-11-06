//
//  CanvasConfettiView.swift
//  TestDrive
//

import SwiftUI

/// Confetti drawn with a SwiftUI `Canvas`, where every piece's position is a pure function of time.
///
/// This is the second of the two confetti implementations. The first, ``EmitterConfettiView``, hands the work to Core
/// Animation emitters. This one has no per-particle state, so the show can be replayed or sampled at any moment.
///
/// How it stays fast: pieces are batched into one `Path` per color and facing (front or back), so a frame is at most
/// 18 fills no matter how many pieces are in the air. Tumbling is a vertical squash, and the back of a piece is drawn
/// in a darker shade, which is what makes the confetti flash as it turns.
struct CanvasConfettiView: View {
    private let pieces: [ConfettiPiece]

    @State private var startDate = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates a confetti show.
    /// - Parameter style: How the confetti arrives.
    init(style: ConfettiStyle) {
        pieces = ConfettiPiece.makePieces(for: style)
    }

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                drawPieces(in: &context, size: size, elapsed: elapsed)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Private Helpers

    private func drawPieces(in context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        // Flying paper is exactly the kind of motion Reduce Motion is meant to remove.
        guard !reduceMotion else { return }

        // One path per color and facing: even indexes are the bright front, odd are the shaded back.
        var buckets = [Path](repeating: Path(), count: ConfettiPalette.colors.count * 2)

        for piece in pieces {
            guard let pose = piece.pose(at: elapsed, in: size) else { continue }

            // Off the bottom or sides means the piece is finished.
            guard pose.center.y < size.height + 60, pose.center.x > -60, pose.center.x < size.width + 60 else {
                continue
            }

            let transform = CGAffineTransform(translationX: pose.center.x, y: pose.center.y)
                .rotated(by: pose.rotation)
                .scaledBy(x: 1, y: pose.flip)
            let rect = CGRect(
                x: -piece.size.width / 2,
                y: -piece.size.height / 2,
                width: piece.size.width,
                height: piece.size.height
            )
            let bucket = piece.colorIndex * 2 + (pose.flip >= 0 ? 0 : 1)

            if piece.isCircle {
                buckets[bucket].addEllipse(in: rect, transform: transform)
            } else {
                buckets[bucket].addRect(rect, transform: transform)
            }
        }

        for (index, path) in buckets.enumerated() where !path.isEmpty {
            let isFront = index.isMultiple(of: 2)
            let color = isFront ? ConfettiPalette.colors[index / 2] : ConfettiPalette.shadedColors[index / 2]
            context.fill(path, with: .color(color))
        }
    }
}

#Preview {
    ZStack {
        Color(white: 0.15).ignoresSafeArea()
        CanvasConfettiView(style: .cannonBlast)
    }
}
