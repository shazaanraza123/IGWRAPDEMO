import SwiftUI

struct OpeningCard: View {
    var card: RunCard
    var year: Int
    var onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hintScale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.igPink.ignoresSafeArea().allowsHitTesting(false)
            rings.allowsHitTesting(false)
            grid.allowsHitTesting(false)
            badge.allowsHitTesting(false)
            copy.allowsHitTesting(false)
            VStack {
                Spacer(minLength: 0).allowsHitTesting(false)
                HStack {
                    start
                    Spacer(minLength: 0).allowsHitTesting(false)
                }
            }
            .padding(.leading, WrappedSpace.gutter)
            .padding(.bottom, CardSpace.openingHintBottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var rings: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [WrappedColor.igYellow, WrappedColor.igOrange, WrappedColor.igViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: CardSpace.openingOuterStroke
                )
                .frame(width: CardSpace.openingOuterRadius * 2, height: CardSpace.openingOuterRadius * 2)
            Circle()
                .stroke(WrappedColor.ink, lineWidth: CardSpace.openingMidStroke)
                .frame(width: CardSpace.openingMidRadius * 2, height: CardSpace.openingMidRadius * 2)
            Circle()
                .stroke(
                    WrappedColor.ink,
                    style: StrokeStyle(
                        lineWidth: CardSpace.openingInnerStroke,
                        dash: [CardSpace.openingDash, CardSpace.openingDashGap]
                    )
                )
                .frame(width: CardSpace.openingInnerRadius * 2, height: CardSpace.openingInnerRadius * 2)
        }
        .position(x: CardSpace.openingRingCenterX, y: CardSpace.openingRingCenterY)
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: WrappedSpace.gridGap), count: 3)
        return LazyVGrid(columns: columns, spacing: WrappedSpace.gridGap) {
            tile(photo(0))
            WrappedColor.ink
            tile(photo(1))
            tile(photo(2))
            tile(photo(3))
            tile(photo(4))
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.openingGridTop)
    }

    private func photo(_ index: Int) -> String {
        let photos = card.payload.photos ?? []
        return photos.indices.contains(index) ? photos[index] : ""
    }

    private func tile(_ name: String) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image = BundlePhoto.image(named: name) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    MonthTone.gradient(0)
                }
            }
            .clipped()
    }

    private var badge: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardText(
                text: "YOUR YEAR",
                size: CardSpace.kicker,
                weight: CardSpace.medium,
                width: CardSpace.regular,
                tracking: CardSpace.kickerTracking,
                color: WrappedColor.igWhite
            )
            Spacer(minLength: 0)
            CardText(
                text: "\(year)",
                size: CardSpace.openingYearSize,
                tracking: CardSpace.openingYearTracking,
                lineHeight: CardSpace.openingYearLine,
                color: WrappedColor.igPink
            )
        }
        .padding(CardSpace.openingBadgePad)
        .frame(width: CardSpace.openingBadge, height: CardSpace.openingBadge, alignment: .leading)
        .background(WrappedColor.ink)
        .overlay {
            Rectangle().strokeBorder(WrappedColor.ink, lineWidth: CardSpace.openingBadgeBorder)
        }
        .offset(x: CardSpace.openingBadgeLeft, y: CardSpace.openingBadgeTop)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: CardSpace.openingCopyGap) {
            CardText(
                text: "@\(card.payload.handle ?? "")",
                size: CardSpace.openingHandleSize,
                width: CardSpace.regular,
                color: WrappedColor.ink
            )
            DisplayHeadline(
                copy: card.headline,
                size: CardSpace.openingHeadline,
                lineHeight: CardSpace.openingHeadlineLine,
                tracking: CardSpace.openingHeadlineTracking,
                color: WrappedColor.ink
            )
            CardText(
                text: card.support,
                size: CardSpace.openingSupport,
                weight: CardSpace.support,
                width: CardSpace.regular,
                lineHeight: CardSpace.openingSupportLine,
                color: WrappedColor.ink
            )
            .frame(maxWidth: CardSpace.openingSupportWidth, alignment: .leading)
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.openingCopyTop)
    }

    private var start: some View {
        Button(action: onStart) {
            HStack(spacing: CardSpace.chipGap) {
                CardText(
                    text: "Tap to start",
                    size: CardSpace.openingHint,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.ink
                )
                Image(systemName: "arrow.right")
                    .font(.system(size: CardSpace.hintIcon, weight: .semibold))
                    .foregroundStyle(WrappedColor.ink)
            }
            .scaleEffect(hintScale)
            .frame(minHeight: WrappedSpace.minHit, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("opening-start")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: WrappedMotion.cardEnterResponse).repeatCount(1, autoreverses: true)) {
                hintScale = CardSpace.hintPulse
            }
        }
    }
}
