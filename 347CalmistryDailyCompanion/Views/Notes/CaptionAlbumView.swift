import SwiftUI

struct CaptionAlbumView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var editorCaption: CaptionEntry?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TasteBanner(assetName: "BannerCaption")
                        .clipShape(TornPaperShape())
                        .shadow(color: Palette.background.opacity(0.32), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Caption Album")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        Text("Short notes under a thumbnail for each dish you cook.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Palette.accent)
                    }

                    if store.recipes.isEmpty {
                        EmptyGarden(
                            title: "Add a dish first",
                            systemImage: "fork.knife.circle",
                            message: "You need at least one recipe in Book before you can write a caption."
                        )
                    } else if store.captions.isEmpty {
                        EmptyGarden(
                            title: "Add your first recipe caption",
                            systemImage: "pencil.circle",
                            message: "Capture how a dish tasted, or a tweak you want to remember."
                        )
                        addCaptionButton
                    } else {
                        addCaptionButton
                        ForEach(store.captions) { caption in
                            captionCard(caption)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .gardenPage()
            .dismissKeyboardOnTap()
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        guard !store.recipes.isEmpty else { return }
                        editorCaption = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(store.recipes.isEmpty ? Palette.accent.opacity(0.45) : Palette.primary)
                    }
                    .disabled(store.recipes.isEmpty)
                    .accessibilityLabel("Add caption")
                }
            }
            .sheet(isPresented: $showEditor) {
                CaptionEditorSheet(caption: editorCaption)
                    .environmentObject(store)
            }
        }
    }

    private var addCaptionButton: some View {
        Button {
            editorCaption = nil
            showEditor = true
        } label: {
            HStack {
                Image(systemName: "pencil.circle.fill")
                Text("Write a caption")
                    .font(.system(.body, design: .rounded).weight(.bold))
                Spacer()
            }
            .foregroundColor(Palette.primary)
            .padding(12)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func captionCard(_ caption: CaptionEntry) -> some View {
        let recipe = store.recipe(id: caption.recipeID)
        return Button {
            editorCaption = caption
            showEditor = true
        } label: {
            PaperCard {
                VStack(alignment: .leading, spacing: 10) {
                    thumbnail(for: caption, recipe: recipe)

                    HStack(spacing: 8) {
                        Text(recipe?.emoji ?? "📝")
                            .font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe?.title ?? "Recipe removed")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.primary)
                            Text(caption.updatedAt, style: .date)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Palette.accent)
                        }
                    }

                    Text(caption.text)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Palette.accent)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func thumbnail(for caption: CaptionEntry, recipe: Recipe?) -> some View {
        if let fileName = caption.photoFileName, PhotoDisk.load(fileName) != nil {
            RecipePhotoFrame(fileName: fileName, height: 110)
        } else if let fileName = recipe?.photoFileName, PhotoDisk.load(fileName) != nil {
            RecipePhotoFrame(fileName: fileName, height: 110)
        }
    }
}
