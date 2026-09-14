import PhotosUI
import SwiftUI
import UIKit

struct RecipeEditorSheet: View {
    @EnvironmentObject private var store: CookbookStore
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe?

    @State private var titleText = ""
    @State private var emojiText = "🌿"
    @State private var cuisineText = ""
    @State private var ingredientLines: [EditableLine] = [EditableLine(text: "")]
    @State private var instructionLines: [EditableLine] = [EditableLine(text: "")]
    @State private var pickerItem: PhotosPickerItem?
    @State private var pendingJPEG: Data?
    @State private var previewImage: UIImage?
    @State private var existingPhotoName: String?
    @State private var removeExistingPhoto = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    photoBlock

                    fieldBlock(title: "Title") {
                        TextField("Dish name", text: $titleText)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Palette.primary)
                    }

                    HStack(spacing: 10) {
                        fieldBlock(title: "Emoji") {
                            TextField("🌿", text: $emojiText)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Palette.primary)
                        }
                        fieldBlock(title: "Cuisine") {
                            TextField("Italian, market…", text: $cuisineText)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Palette.primary)
                        }
                    }

                    lineEditor(
                        title: "Ingredients",
                        lines: $ingredientLines,
                        placeholder: "One ingredient"
                    )

                    lineEditor(
                        title: "Steps",
                        lines: $instructionLines,
                        placeholder: "One instruction"
                    )

                    if let errorText {
                        Text(errorText)
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .background {
                HerbMeadow()
            }
            .gardenPage()
            .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(.body, design: .rounded).weight(.bold))
                }
            }
            .onAppear(perform: populate)
            .onChange(of: pickerItem) { newValue in
                loadPickedPhoto(newValue)
            }
        }
        .background {
            HerbMeadow()
        }
        .tint(Palette.primary)
    }

    private var photoBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(Palette.primary)

            if let previewImage {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 132)
                    .background {
                        Palette.surface
                            .overlay {
                                Image(uiImage: previewImage)
                                    .resizable()
                                    .scaledToFill()
                            }
                            .clipped()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Palette.surface)
                        .clipShape(Capsule())
                }

                if previewImage != nil {
                    Button("Remove") {
                        pendingJPEG = nil
                        previewImage = nil
                        pickerItem = nil
                        if existingPhotoName != nil {
                            removeExistingPhoto = true
                        }
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Palette.accent)
                }
            }
        }
    }

    private func fieldBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(Palette.primary)
            content()
                .padding(10)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func lineEditor(title: String, lines: Binding<[EditableLine]>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                Spacer()
                Button {
                    lines.wrappedValue.append(EditableLine(text: ""))
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Palette.primary)
                }
            }

            ForEach(lines) { $line in
                HStack(spacing: 8) {
                    TextField(placeholder, text: $line.text)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Palette.primary)
                        .padding(10)
                        .background(Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    if lines.wrappedValue.count > 1 {
                        Button {
                            lines.wrappedValue.removeAll { $0.id == line.id }
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundColor(Palette.accent)
                        }
                    }
                }
            }
        }
    }

    private func populate() {
        guard let recipe else { return }
        titleText = recipe.title
        emojiText = recipe.emoji
        cuisineText = recipe.cuisine
        ingredientLines = recipe.ingredients.isEmpty
            ? [EditableLine(text: "")]
            : recipe.ingredients.map { EditableLine(text: $0) }
        instructionLines = recipe.instructions.isEmpty
            ? [EditableLine(text: "")]
            : recipe.instructions.map { EditableLine(text: $0) }
        existingPhotoName = recipe.photoFileName
        if let name = recipe.photoFileName {
            previewImage = PhotoDisk.load(name)
        }
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let jpeg = PhotoDisk.jpegData(from: image)
                else { return }
                await MainActor.run {
                    pendingJPEG = jpeg
                    previewImage = image
                    removeExistingPhoto = false
                }
            } catch {
                return
            }
        }
    }

    private func save() {
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let ingredients = ingredientLines
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let instructions = instructionLines
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if trimmedTitle.isEmpty {
            errorText = "Please add a title."
            return
        }
        if ingredients.isEmpty {
            errorText = "Add at least one ingredient."
            return
        }
        if instructions.isEmpty {
            errorText = "Add at least one instruction."
            return
        }

        var photoName = existingPhotoName
        if removeExistingPhoto && pendingJPEG == nil {
            photoName = nil
        }
        if let pendingJPEG {
            if let saved = PhotoDisk.save(pendingJPEG) {
                photoName = saved
            }
        }

        let trimmedEmoji = emojiText.trimmingCharacters(in: .whitespacesAndNewlines)
        let draft = Recipe(
            id: recipe?.id ?? UUID(),
            title: trimmedTitle,
            emoji: trimmedEmoji.isEmpty ? "🌿" : trimmedEmoji,
            cuisine: cuisineText.trimmingCharacters(in: .whitespacesAndNewlines),
            ingredients: ingredients,
            instructions: instructions,
            photoFileName: photoName,
            createdAt: recipe?.createdAt ?? Date()
        )

        if recipe == nil {
            store.addRecipe(draft)
        } else {
            store.updateRecipe(draft)
        }
        store.markActivity(viewedRecipeID: draft.id)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}

struct EditableLine: Identifiable {
    let id = UUID()
    var text: String
}
