import SwiftUI

struct ContentView: View {
    @StateObject private var store = CookbookStore()
    @State private var tab: AppTab = .fridge

    var body: some View {
        ZStack {
            PantryCanvas()

            Group {
                switch tab {
                case .fridge:
                    FridgePlanView()
                case .shelf:
                    AuthorShelfView()
                case .kitchen:
                    RecipeBookView()
                case .capture:
                    CaptureImportView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(store)

            VStack {
                Spacer()
                MainTabBar(selection: $tab)
            }
        }
        .ignoresSafeArea(.keyboard)
        .studioBackdrop()
        .dismissKeyboardOnTap()
        .tint(Palette.primary)
        .fullScreenCover(isPresented: Binding(
            get: { !store.hasCompletedOnboarding },
            set: { if !$0 { store.completeOnboarding() } }
        )) {
            OnboardingFlow {
                store.completeOnboarding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
