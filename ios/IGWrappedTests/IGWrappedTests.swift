import Testing
import UIKit
@testable import IGWrapped

@Test func styleguideListsEveryComponent() {
    let required = [
        "StoryProgressBars", "WrappedTopRow", "CardShell", "Eyebrow", "DisplayHeadline",
        "BigNumber", "PhotoTile", "SwatchStrip", "CategoryBar", "StickerChip",
        "LikeBubble", "CommentBubble", "StoryThumb", "ReplyBubbles", "AvatarRing",
        "ClockFace", "MonthBars", "ClueRow", "PersonalityMark", "MatchBar",
        "SharePill", "PrivatePill", "ProvenanceBadge", "SegmentedToggle", "ToggleChip",
        "HubTile", "HighlightTile", "ToolRow", "ShareActionButton"
    ]
    for name in required {
        #expect(StyleguideCatalog.componentNames.contains(name))
    }
    #expect(StyleguideCatalog.componentNames.contains("DesignCanvas"))
    #expect(StyleguideCatalog.componentNames.contains("ReferenceOverlay"))
}

@Test func eightPersonalityMarks() {
    #expect(PersonalityArchetype.allCases.count == 8)
}

@Test func typeStylesUseTheBriefSizes() {
    #expect(WrappedTextStyle.hero.size == 96)
    #expect(WrappedTextStyle.display.size == 46)
    #expect(WrappedTextStyle.display.tracking == -1)
    #expect(WrappedTextStyle.eyebrow.tracking == 1.4)
    #expect(WrappedTextStyle.igChrome.uiFont.pointSize == 12)
    #expect(WrappedTextStyle.igChrome.uiFont.familyName.contains("Archivo") == false)
}

@Test func archivoWidthAxisCondenses() {
    let narrow = ArchivoFont.uiFont(size: 72, weight: 900, width: 62)
    let wide = ArchivoFont.uiFont(size: 72, weight: 900, width: 125)
    let sample = "WRAPPED" as NSString
    let narrowWidth = sample.size(withAttributes: [.font: narrow]).width
    let wideWidth = sample.size(withAttributes: [.font: wide]).width
    #expect(narrowWidth > 0)
    #expect(narrowWidth < wideWidth * 0.8)
}

@Test func designFrameMatchesTheCards() {
    #expect(WrappedSpace.frameWidth == 390)
    #expect(WrappedSpace.frameHeight == 844)
    #expect(WrappedSpace.gutter == 20)
    #expect(WrappedSpace.minHit == 44)
}
