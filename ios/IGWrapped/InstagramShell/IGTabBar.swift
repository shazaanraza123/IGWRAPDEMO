import SwiftUI

enum IGTab: String, CaseIterable, Identifiable {
    case home
    case reels
    case dms
    case search
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .reels: "Reels"
        case .dms: "Messages"
        case .search: "Search"
        case .profile: "Profile"
        }
    }

    var identifier: String { "tab-\(rawValue)" }

    func symbol(selected: Bool) -> String {
        switch self {
        case .home: selected ? "house.fill" : "house"
        case .reels: selected ? "play.square.fill" : "play.square"
        case .dms: selected ? "paperplane.fill" : "paperplane"
        case .search: "magnifyingglass"
        case .profile: "circle.fill"
        }
    }
}

struct IGTabBar: View {
    @Binding var selection: IGTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(IGTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .frame(width: IGSpace.tabBarWidth, height: IGSpace.tabBarHeight)
        .background(Capsule().fill(WrappedColor.igTabBar))
    }

    private func tabButton(_ tab: IGTab) -> some View {
        let selected = selection == tab
        return Button {
            selection = tab
        } label: {
            ZStack {
                if selected {
                    RoundedRectangle(cornerRadius: IGSpace.tabChipRadius, style: .continuous)
                        .fill(WrappedColor.igTabChip)
                        .frame(width: IGSpace.tabChipWidth, height: IGSpace.tabChipHeight)
                }
                if tab == .profile {
                    Circle()
                        .fill(WrappedColor.igRingSeen)
                        .frame(width: IGSpace.profileDot, height: IGSpace.profileDot)
                        .overlay {
                            Circle().stroke(WrappedColor.igWhite, lineWidth: selected ? IGSpace.ringStroke : 0)
                        }
                } else {
                    Image(systemName: tab.symbol(selected: selected))
                        .font(selected ? IGFont.iconSelected : IGFont.icon)
                        .foregroundStyle(selected ? WrappedColor.igWhite : WrappedColor.igIcon)
                }
                if tab == .dms {
                    Circle()
                        .fill(WrappedColor.likeRed)
                        .frame(width: IGSpace.unreadDot, height: IGSpace.unreadDot)
                        .offset(x: IGSpace.unreadDot, y: -IGSpace.unreadDot)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tab.title)
            .accessibilityIdentifier(tab.identifier)
            .accessibilityAddTraits(.isButton)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab.identifier)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
