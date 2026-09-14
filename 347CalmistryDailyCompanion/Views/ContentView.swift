import SwiftUI

struct ContentView: View {
    @StateObject private var store = CookbookStore()
    @State private var destination: DeskDestination = .book

    var body: some View {
        HStack(spacing: 0) {
            HerbRail(selection: $destination)

            Group {
                switch destination {
                case .book:
                    RecipeBookView()
                case .notes:
                    CaptionAlbumView()
                case .tastes:
                    TasteExplorerView()
                case .stats:
                    KitchenStatsView()
                case .desk:
                    KitchenDeskView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(.keyboard)
        .studioBackdrop()
        .dismissKeyboardOnTap()
        .environmentObject(store)
        .tint(Palette.primary)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
