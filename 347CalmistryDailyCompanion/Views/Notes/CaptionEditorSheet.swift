import PhotosUI
import SwiftUI
import UIKit

struct CaptionEditorSheet: View {
    @EnvironmentObject private var store: CookbookStore
    @Environment(\.dismiss) private var dismiss

    let caption: CaptionEntry?

    @State private var selectedRecipeID: UUID?
    @State private var text = ""
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
                    recipePicker

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Caption")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        TextEditor(text: $text)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Palette.primary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(Palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    photoBlock

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
            .navigationTitle(caption == nil ? "New Caption" : "Edit Caption")
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

    private var recipePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dish")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(Palette.primary)

            if store.recipes.isEmpty {
                Text("Add a dish in Book first.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Palette.accent)
            } else {
                Picker("Dish", selection: Binding(
                    get: { selectedRecipeID ?? store.recipes.first?.id },
                    set: { selectedRecipeID = $0 }
                )) {
                    ForEach(store.recipes) { recipe in
                        Text("\(recipe.emoji) \(recipe.title)")
                            .tag(Optional(recipe.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(Palette.primary)
            }
        }
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

    private func populate() {
        if let caption {
            selectedRecipeID = caption.recipeID
            text = caption.text
            existingPhotoName = caption.photoFileName
            if let name = caption.photoFileName {
                previewImage = PhotoDisk.load(name)
            }
        } else {
            selectedRecipeID = store.recipes.first?.id
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            errorText = "Write a caption before saving."
            return
        }

        let recipeID = selectedRecipeID ?? store.recipes.first?.id
        guard let recipeID, store.recipe(id: recipeID) != nil else {
            errorText = "Add a dish in Book before writing a caption."
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

        let draft = CaptionEntry(
            id: caption?.id ?? UUID(),
            recipeID: recipeID,
            text: trimmed,
            photoFileName: photoName,
            updatedAt: Date()
        )

        if caption == nil {
            store.addCaption(draft)
        } else {
            store.updateCaption(draft)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
