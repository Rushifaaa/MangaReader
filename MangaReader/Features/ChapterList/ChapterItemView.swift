import SwiftUI

struct ChapterItemView: View {
    @State private var isHovering = false
    
    @ObservedObject var chapterItem: ChapterListItem
    var expandingChanged: Binding<Bool>
    
    var isFirst = false
    var isLast = false

    var onChapterSelect: ((ChapterListItem) -> Void)?
    
    init(chapterItem: ChapterListItem, expandingChanged: Binding<Bool>, isFirst: Bool = false, isLast: Bool = false, onChapterSelect: ((ChapterListItem) -> Void)? = nil) {
        self.chapterItem = chapterItem
        self.expandingChanged = expandingChanged
        self.isFirst = isFirst
        self.isLast = isLast
        self.onChapterSelect = onChapterSelect
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 40)
                .foregroundColor(isHovering ? Color.black.opacity(0.5) : Color.black.opacity(0.3))
                .clipShape(
                    .rect(cornerRadii: RectangleCornerRadii(topLeading: isFirst ? 10 : 0,
                                                            bottomLeading: isLast || chapterItem.showChildren ? 10 : 0,
                                                            bottomTrailing: isLast || chapterItem.showChildren ? 10 : 0,
                                                            topTrailing: isFirst ? 10 : 0)
                    )
                )
                .overlay {
                    HStack {
                        Text(chapterItem.title)
                        Spacer()
                        if !(chapterItem.children?.isEmpty ?? true) {
                            Image(systemName: "chevron.down")
                                .rotationEffect(chapterItem.showChildren ? Angle(degrees: -180) : Angle(degrees: 0))
                                .animation(.bouncy(duration: 0.25, extraBounce: 0.2), value: chapterItem.showChildren)
                        }
                    }
                    .padding(.horizontal, 16)
                    .zIndex(1)
                }
                .onHover { hover in
                    isHovering = hover
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if (chapterItem.children?.isEmpty ?? true) && chapterItem.parent != nil {
                        onChapterSelect?(chapterItem)
                    }
                    
                    guard !(chapterItem.children?.isEmpty ?? true) else { return }
                    expandingChanged.wrappedValue.toggle()
                    chapterItem.showChildren.toggle()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0) // Visual response on iOS/iPadOS cause there is no hover
                        .onChanged { _ in
                            isHovering = true
                        }
                        .onEnded { _ in
                            isHovering = false
                        }
                )

            if let children = chapterItem.children {
                HStack {
                    if chapterItem.showChildren {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                                ChapterItemView(chapterItem: child,
                                                expandingChanged: expandingChanged,
                                                isLast: index == children.endIndex - 1) { chapterListItem in
                                    onChapterSelect?(chapterListItem)
                                }
                                    .padding(.horizontal, 32)
                            }
                        }
                        .transition(.move(edge: .top))
                    }
                    Spacer()
                }
                .clipped()
                .padding(.bottom, chapterItem.showChildren ? 8 : 0)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: chapterItem.showChildren)
    }
}
