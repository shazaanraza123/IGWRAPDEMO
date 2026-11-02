import SwiftUI

struct FeedColorCard: View {
    var card: RunCard
    var onShare: () -> Void

    @State private var expanded: ColorSwatch?

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.paper.ignoresSafeArea().allowsHitTesting(false)
            copy.allowsHitTesting(false)
            mosaic.allowsHitTesting(false)
            sticker.allowsHitTesting(false)
            swatches
            if let expanded {
                expansion(expanded)
            }
            footnote
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: CardSpace.blockGap) {
            CardText(
                text: "YOUR HABITS",
                size: WrappedTextStyle.eyebrow.size,
                weight: WrappedTextStyle.eyebrow.weight,
                width: WrappedTextStyle.eyebrow.width,
                tracking: WrappedTextStyle.eyebrow.tracking,
                color: WrappedColor.paletteEyebrow
            )
            DisplayHeadline(
                copy: card.headline,
                size: CardSpace.feedHeadline,
                lineHeight: CardSpace.openingHeadlineLine,
                tracking: CardSpace.feedHeadlineTracking,
                color: WrappedColor.ink
            )
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.yearCopyTop)
    }

    private var mosaic: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: WrappedSpace.gridGap), count: 3)
        return LazyVGrid(columns: columns, spacing: WrappedSpace.gridGap) {
            ForEach(FeedMosaic.fills.indices, id: \.self) { index in
                FeedMosaic.gradient(index)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.feedGridTop)
    }

    private var sticker: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardText(
                text: "YOUR PALETTE",
                size: CardSpace.kicker,
                weight: CardSpace.strong,
                width: CardSpace.regular,
                tracking: CardSpace.kickerTracking,
                color: WrappedColor.igYellow
            )
            CardText(
                text: card.payload.paletteName ?? "",
                size: CardSpace.stickerName,
                lineHeight: 1,
                color: WrappedColor.igWhite,
                uppercase: true
            )
        }
        .padding(.vertical, CardSpace.stickerPadV)
        .padding(.horizontal, CardSpace.stickerPadH)
        .background(RoundedRectangle(cornerRadius: CardSpace.stickerRadius).fill(WrappedColor.ink))
        .shadow(color: WrappedColor.ink.opacity(CardSpace.stickerShadow), radius: CardSpace.stickerRadius, y: CardSpace.openingBadgePad)
        .rotationEffect(.degrees(CardSpace.stickerTilt))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, CardSpace.feedStickerTop)
        .padding(.trailing, CardSpace.feedStickerTrailing)
    }

    private var swatches: some View {
        HStack(alignment: .top, spacing: CardSpace.swatchGap) {
            ForEach(Array((card.payload.swatches ?? []).enumerated()), id: \.element.id) { index, swatch in
                Button {
                    expanded = expanded == swatch ? nil : swatch
                } label: {
                    VStack(alignment: .leading, spacing: CardSpace.chipPadV) {
                        RoundedRectangle(cornerRadius: CardSpace.swatchRadius)
                            .fill(PaletteInk.colors[index])
                            .frame(height: CardSpace.swatchHeight)
                            .overlay {
                                RoundedRectangle(cornerRadius: CardSpace.swatchRadius)
                                    .strokeBorder(WrappedColor.ink.opacity(CardSpace.hairlineOpacity), lineWidth: CardSpace.hairline)
                            }
                        CardText(
                            text: "\(swatch.pct)%",
                            size: CardSpace.swatchShare,
                            width: CardSpace.titleWidth,
                            color: WrappedColor.ink
                        )
                        Text(swatch.hex)
                            .font(.system(size: CardSpace.hexSize, design: .monospaced))
                            .foregroundStyle(WrappedColor.ink)
                    }
                    .frame(maxWidth: .infinity, minHeight: WrappedSpace.minHit, alignment: .top)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("swatch-\(index)")
                .accessibilityLabel("\(swatch.pct)%, \(swatch.hex)")
            }
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.feedSwatchTop)
    }

    private func expansion(_ swatch: ColorSwatch) -> some View {
        VStack(alignment: .leading, spacing: CardSpace.chipGap) {
            CardText(text: swatch.hex, size: CardSpace.swatchShare, width: CardSpace.regular, color: WrappedColor.igWhite)
            CardText(text: "\(swatch.pct)%", size: CardSpace.stickerName, color: WrappedColor.igYellow)
            CardText(
                text: "of liked posts where this color dominates",
                size: WrappedTextStyle.caption.size,
                weight: WrappedTextStyle.caption.weight,
                width: WrappedTextStyle.caption.width,
                color: WrappedColor.igWhite
            )
        }
        .padding(CardSpace.stickerPadH)
        .background(RoundedRectangle(cornerRadius: CardSpace.stickerRadius).fill(WrappedColor.ink))
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.feedSwatchTop - WrappedSpace.minHit)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("swatch-detail")
        .accessibilityLabel("of liked posts where this color dominates")
    }

    private var footnote: some View {
        VStack {
            Spacer(minLength: 0).allowsHitTesting(false)
            HStack(alignment: .center, spacing: CardSpace.blockGap) {
                Text(card.payload.copy?.footnote ?? "")
                    .wrappedType(.caption)
                    .foregroundStyle(WrappedColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .allowsHitTesting(false)
                SharePill(action: onShare)
            }
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.bottom, WrappedSpace.pillBottomInset)
            .frame(maxWidth: .infinity)
        }
    }
}
