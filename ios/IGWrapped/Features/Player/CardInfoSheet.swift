import SwiftUI

/// Opened by a swipe up. Provenance, method, and hide land in the card-info step.
struct CardInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            WrappedColor.sheet
                .accessibilityIdentifier("card-info")
                .accessibilityLabel("Card info")
            VStack {
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
                Spacer()
            }
            .padding(WrappedSpace.gutter)
        }
        .presentationBackground(WrappedColor.sheet)
    }
}
