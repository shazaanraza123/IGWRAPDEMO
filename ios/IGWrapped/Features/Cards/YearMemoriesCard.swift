import SwiftUI

struct MonthFace: Identifiable, Equatable {
    var month: Int
    var photo: String
    var chip: String
    var id: Int { month }
}

struct YearMemoriesCard: View {
    var card: RunCard
    var onMonth: (MonthFace) -> Void
    var onPlay: () -> Void

    private var months: [MonthFace] {
        (card.payload.months ?? []).map { slot in
            MonthFace(month: slot.month, photo: slot.photo, chip: MonthLabel.chip(month: slot.month, top: card.payload.topMonth))
        }
    }

    private var ready: Bool { MontageGate.ready(card.payload.months ?? []) }

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
                copy: card.headline,
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
        return LazyVGrid(columns: columns, spacing: WrappedSpace.gridGap) {
            ForEach(months) { month in
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
            .accessibilityLabel(ready ? (card.payload.copy?.playLabel ?? "") : MontageGate.unavailable)
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.yearGridTop)
    }

    private func monthTile(_ month: MonthFace) -> some View {
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
                        .fill(month.month == card.payload.topMonth ? WrappedColor.igPink : WrappedColor.igWhite)
                )
                .padding(CardSpace.chipInset)
            }
            .overlay {
                if month.month == card.payload.topMonth {
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
                text: ready ? (card.payload.copy?.playLabel ?? "") : MontageGate.unavailable,
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
            text: card.support,
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

struct MonthCover: View {
    var month: MonthFace
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
    var card: RunCard
    var onFinished: () -> Void

    @State private var index = 0

    private var months: [MonthFace] {
        (card.payload.months ?? []).map { slot in
            MonthFace(month: slot.month, photo: slot.photo, chip: MonthLabel.chip(month: slot.month, top: card.payload.topMonth))
        }
    }

    var body: some View {
        let month = months.indices.contains(index) ? months[index] : MonthFace(month: 1, photo: "", chip: "")
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
        .accessibilityLabel(card.payload.copy?.playLabel ?? "")
        .task {
            let count = max(months.count, 1)
            let slice = Double(card.payload.montageSeconds ?? 0) / Double(count)
            for next in months.indices.dropFirst() {
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
