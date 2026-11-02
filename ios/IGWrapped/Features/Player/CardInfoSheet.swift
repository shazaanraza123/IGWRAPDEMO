import SwiftUI

struct CardInfoSheet: View {
    var metrics: [RunMetric]
    var onLooksWrong: (String) -> Void
    var onHide: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showsReasons = false
    @State private var confirmsHide = false

    var body: some View {
        ZStack {
            WrappedColor.sheet
                .accessibilityIdentifier("card-info")
                .accessibilityLabel("Card info")
            ScrollView {
                VStack(alignment: .leading, spacing: WrappedSpace.gutter) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .wrappedType(.caption)
                                .foregroundStyle(WrappedColor.igWhite)
                                .frame(minWidth: WrappedSpace.minHit, minHeight: WrappedSpace.minHit)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("card-info-close")
                    }
                    ForEach(Array(metrics.enumerated()), id: \.element.id) { _, metric in
                        metricRow(metric)
                    }
                    Button("This looks wrong") {
                        showsReasons.toggle()
                    }
                    .buttonStyle(.plain)
                    .wrappedType(.body)
                    .foregroundStyle(WrappedColor.igWhite)
                    .frame(maxWidth: .infinity, minHeight: WrappedSpace.minHit, alignment: .leading)
                    .accessibilityIdentifier("looks-wrong")
                    if showsReasons {
                        ForEach(LooksWrongReason.allCases) { reason in
                            Button(reason.label) {
                                onLooksWrong(reason.rawValue)
                            }
                            .buttonStyle(.plain)
                            .wrappedType(.body)
                            .foregroundStyle(WrappedColor.paper)
                            .frame(maxWidth: .infinity, minHeight: WrappedSpace.minHit, alignment: .leading)
                            .accessibilityIdentifier("looks-wrong-\(reason.rawValue)")
                        }
                    }
                    Button("Hide this card") {
                        confirmsHide = true
                    }
                    .buttonStyle(.plain)
                    .wrappedType(.body)
                    .foregroundStyle(WrappedColor.igWhite)
                    .frame(maxWidth: .infinity, minHeight: WrappedSpace.minHit, alignment: .leading)
                    .accessibilityIdentifier("hide-card")
                }
                .padding(WrappedSpace.gutter)
            }
        }
        .presentationBackground(WrappedColor.sheet)
        .presentationCornerRadius(WrappedSpace.sheetRadius)
        .confirmationDialog("Hide this card from your Wrapped?", isPresented: $confirmsHide, titleVisibility: .visible) {
            Button("Hide", role: .destructive) {
                onHide()
            }
            .accessibilityIdentifier("hide-card-confirm")
            Button("Cancel", role: .cancel) {}
        }
    }

    private func metricRow(_ metric: RunMetric) -> some View {
        VStack(alignment: .leading, spacing: CardSpace.chipGap) {
            provenanceBadge(metric.provenance)
            Text(meaning(metric.provenance))
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.paper)
            Text(metric.windowLabel)
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.paper)
            Text(metric.method)
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.igWhite)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("card-info-metric")
        .accessibilityLabel("\(badgeTitle(metric.provenance)). \(meaning(metric.provenance)) \(metric.windowLabel). \(metric.method)")
    }

    private func provenanceBadge(_ provenance: String) -> some View {
        Text(badgeTitle(provenance))
            .wrappedType(.caption)
            .foregroundStyle(provenance == "measured" ? WrappedColor.ink : WrappedColor.igWhite)
            .padding(.horizontal, CardSpace.chipPadH)
            .padding(.vertical, CardSpace.chipPadV)
            .background {
                if provenance == "measured" {
                    Capsule().fill(WrappedColor.igWhite)
                } else if provenance == "estimated" {
                    Capsule().strokeBorder(
                        WrappedColor.igWhite,
                        style: StrokeStyle(lineWidth: CardSpace.dashedStroke, dash: [WrappedSpace.badgeDot, WrappedSpace.badgeGap])
                    )
                } else {
                    Capsule().strokeBorder(
                        WrappedColor.igWhite,
                        style: StrokeStyle(lineWidth: CardSpace.dashedStroke, dash: [WrappedSpace.badgeDash, WrappedSpace.badgeGap])
                    )
                }
            }
    }

    private func meaning(_ provenance: String) -> String {
        switch provenance {
        case "measured": "Counted directly from your activity."
        case "estimated": "Calculated from a sample of your activity."
        case "inferred": "Our best guess from what you engaged with."
        default: ""
        }
    }

    private func badgeTitle(_ provenance: String) -> String {
        switch provenance {
        case "measured": "Measured"
        case "estimated": "Estimated"
        case "inferred": "Inferred"
        default: provenance
        }
    }
}
