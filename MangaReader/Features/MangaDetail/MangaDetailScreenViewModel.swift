import Combine
import Foundation
import SwiftData

@MainActor
class MangaDetailScreenViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var mangaDetail: MangaDetailViewModel?

    @Published var chapters = [Chapter]()
    @Published var chapterItems: [ChapterListItem] = []
    @Published var mangaReadState: MangaReadState? = nil

    func fetchData(mangaSlug: String) async {
        isLoading = true
        await getMangaDetail(slug: mangaSlug)

        if let mangaHid = mangaDetail?.hid, let mangaSlug = mangaDetail?.slug, chapters.isEmpty {
            await getChapters(hid: mangaHid, mangaSlug: mangaSlug)
        } else {
            isLoading = false
        }
    }

    private func getMangaDetail(slug: String) async {
        do {
            let mangaDetail = try await Networking.shared.getMangaDetails(slug: slug)
            self.mangaDetail = MangaDetailViewModel(mangaDetail)
        } catch {
            print(error)
        }
    }

    private func getChapters(hid: String, mangaSlug: String) async {
        do {
            let chapterResponse = try await Networking.shared.getChapters(hid: hid, limit: 1)
            guard chapterResponse.total > 0 else { return }

            let allChapterResponse = try await Networking.shared.getChapters(hid: hid, limit: chapterResponse.total)
            #warning("debug - dont forget to remove")
            chapters = allChapterResponse.chapters.filter { $0.lang == "en" }

            let groupNames = Array(Set(chapters.compactMap { $0.groupName?.first }))
            let chapterListItems = groupNames.map { ChapterListItem(id: UUID().uuidString, title: $0, mangaSlug: mangaSlug) }

            Task.detached(priority: .userInitiated) {
                Task { @MainActor in
                    self.chapterItems = chapterListItems.map { chapterListItem in
                        let chapters = self.chapters
                            .filter { $0.groupName?.first ?? "" == chapterListItem.title }
                            .map { chapter in
                                let childChapterListItem = ChapterListItem(id: chapter.hid, title: chapter.title ?? chapter.chap ?? chapter.vol ?? "Unkown Chapter", mangaSlug: mangaSlug)
                                
                                childChapterListItem.parent = chapterListItem
                                
                                return childChapterListItem
                            }
                        chapterListItem.children = chapters
                        return chapterListItem
                    }

                    self.isLoading = false
                }
            }
        } catch {
            print(error)
        }
    }
}
