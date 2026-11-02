import SwiftUI

struct YearMemoriesCard: View {
    var onMonth: (MayaMonth) -> Void
    var onPlay: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.ink.ignoresSafeArea().allowsHitTesting(false)
            copy.allowsHitTesting(false)
            grid
            support.allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
            CardText(
                text: "YOUR YEAR IN MEMORIES",
                size: WrappedTextStyle.eyebrow.size,
                weight: WrappedTextStyle.eyebrow.weight,
                width: WrappedTextStyle.eyebrow.width,
                tracking: WrappedTextStyle.eyebrow.tracking,
                color: WrappedColor.pinkOnDark
            )
            DisplayHeadline(
                copy: MayaYear.headline,
                size: CardSpace.yearHeadline,
                lineHeight: CardSpace.openingHeadlineLine,
                tracking: CardSpace.yearHeadlineTracking,
                color: WrappedColor.igWhite
            )
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.yearCopyTop)
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: WrappedSpace.gridGap), count: 3)
        let ready = MayaYear.montageReady
        return LazyVGrid(columns: columns, spacing: WrappedSpace.gridGap) {
            ForEach(MayaYear.months) { month in
                Button {
                    onMonth(month)
                } label: {
                    monthTile(month)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("year-month-\(month.month)")
                .accessibilityLabel(month.chip)
            }
            Button {
                guard ready else { return }
                onPlay()
            } label: {
                playTile(ready: ready)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("year-play")
            .accessibilityLabel(ready ? MayaYear.playLabel : MayaYear.playUnavailable)
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.yearGridTop)
    }

    private func monthTile(_ month: MayaMonth) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                MonthTone.gradient(month.month - 1)
                if let image = BundlePhoto.image(named: month.photo) {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .overlay(alignment: .topLeading) {
                CardText(
                    text: month.chip,
                    size: CardSpace.kicker,
                    width: CardSpace.regular,
                    tracking: CardSpace.chipTracking,
                    color: WrappedColor.ink
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, CardSpace.chipPadH)
                .padding(.vertical, CardSpace.chipPadV)
                .background(
                    RoundedRectangle(cornerRadius: CardSpace.chipRadius)
                        .fill(month.isTop ? WrappedColor.igPink : WrappedColor.igWhite)
                )
                .padding(CardSpace.chipInset)
            }
            .overlay {
                if month.isTop {
                    Rectangle().strokeBorder(WrappedColor.igPink, lineWidth: CardSpace.topMonthRing)
                }
            }
            .clipped()
    }

    private func playTile(ready: Bool) -> some View {
        VStack(spacing: CardSpace.chipGap) {
            ZStack {
                Circle().fill(WrappedColor.ink)
                Image(systemName: "play.fill")
                    .font(.system(size: CardSpace.playIcon, weight: .bold))
                    .foregroundStyle(WrappedColor.igWhite)
            }
            .frame(width: WrappedSpace.minHit, height: WrappedSpace.minHit)
            CardText(
                text: ready
                    ? MayaYear.playLabel.replacingOccurrences(of: "PLAY YOUR ", with: "PLAY YOUR\n")
                    : MayaYear.playUnavailable,
                size: CardSpace.playLabel,
                width: CardSpace.regular,
                color: WrappedColor.ink,
                alignment: .center
            )
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(WrappedColor.igPink)
        .opacity(ready ? 1 : CardSpace.playUnavailableOpacity)
    }

    private var support: some View {
        CardText(
            text: MayaYear.support,
            size: CardSpace.yearSupportSize,
            weight: WrappedTextStyle.body.weight,
            width: WrappedTextStyle.body.width,
            color: WrappedColor.onInkSecondary
        )
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.yearSupportTop)
    }
}

extension MayaYear {
    /// True only when every month photo from m-01 through m-11 is in the bundle.
    static var montageReady: Bool {
        months.allSatisfy { BundlePhoto.image(named: $0.photo) != nil }
    }
}

struct MonthCover: View {
    var month: MayaMonth
    var onClose: () -> Void

    var body: some View {
        ZStack {
            MonthTone.gradient(month.month - 1).ignoresSafeArea()
            if let image = BundlePhoto.image(named: month.photo) {
                Image(uiImage: image).resizable().scaledToFill().ignoresSafeArea()
            }
            CardText(
                text: month.chip,
                size: CardSpace.yearHeadline,
                tracking: CardSpace.yearHeadlineTracking,
                color: WrappedColor.igWhite,
                alignment: .center
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("month-viewer")
        .accessibilityLabel(month.chip)
        .accessibilityAddTraits(.isButton)
    }
}

struct YearMontage: View {
    var onFinished: () -> Void

    @State private var index = 0

    var body: some View {
        let month = MayaYear.months[index]
        ZStack {
            MonthTone.gradient(month.month - 1).ignoresSafeArea()
            if let image = BundlePhoto.image(named: month.photo) {
                Image(uiImage: image).resizable().scaledToFill().ignoresSafeArea()
            }
            CardText(
                text: month.chip,
                size: CardSpace.yearHeadline,
                tracking: CardSpace.yearHeadlineTracking,
                color: WrappedColor.igWhite,
                alignment: .center
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("year-montage")
        .accessibilityLabel(MayaYear.playLabel)
        .task {
            let slice = Double(MayaYear.montageSeconds) / Double(MayaYear.months.count)
            for next in MayaYear.months.indices.dropFirst() {
                try? await Task.sleep(for: .seconds(slice))
                if Task.isCancelled { return }
                index = next
            }
            try? await Task.sleep(for: .seconds(slice))
            if Task.isCancelled { return }
            onFinished()
        }
    }
}
