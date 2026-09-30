import SwiftUI

struct CaptureImportView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var input = ""
    @State private var draft: ImportedRecipeDraft?
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var successText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FeatureHero(
                        title: "Import Lab",
                        subtitle: "Paste a full recipe or drop a https link. We extract title, ingredients, and steps.",
                        symbol: "square.and.arrow.down.on.square.fill"
                    )

                    PaperCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Source")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.ink)
                                .padding(.top, 6)
                            TextEditor(text: $input)
                                .frame(minHeight: 160)
                                .scrollContentBackground(.hidden)
                                .padding(10)
                                .background(Palette.cardSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Palette.hairline, lineWidth: 1)
                                }
                                .foregroundColor(Palette.ink)
                                .font(.system(.body, design: .rounded))
                            Text("Tip: include headings like Ingredients and Instructions for cleaner parsing.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Palette.muted)

                            HStack(spacing: 10) {
                                Button {
                                    parsePasted()
                                } label: {
                                    Text("Parse text")
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        .foregroundColor(Palette.onPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Palette.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    Task { await parseLink() }
                                } label: {
                                    Group {
                                        if isLoading {
                                            ProgressView()
                                                .tint(Palette.primary)
                                        } else {
                                            Text("Fetch link")
                                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        }
                                    }
                                    .foregroundColor(Palette.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Palette.cardSoft)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Palette.primary.opacity(0.35), lineWidth: 1)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                            }
                        }
                    }

                    if let errorText {
                        Text(errorText)
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.onPrimary)
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    }

                    if let draft {
                        PaperCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(draft.emoji) \(draft.title)")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.ink)
                                    .padding(.top, 6)
                                Text(draft.sourceNote)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(Palette.muted)
                                Text("Ingredients (\(draft.ingredients.count))")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.ink)
                                ForEach(draft.ingredients.prefix(12), id: \.self) { line in
                                    Text("• \(line)")
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(Palette.muted)
                                }
                                Text("Steps (\(draft.instructions.count))")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.ink)
                                ForEach(Array(draft.instructions.prefix(8).enumerated()), id: \.offset) { index, line in
                                    Text("\(index + 1). \(line)")
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(Palette.muted)
                                }

                                Button {
                                    _ = store.importDraft(draft)
                                    successText = "Saved to Kitchen"
                                    self.draft = nil
                                    input = ""
                                } label: {
                                    Text("Save imported recipe")
                                        .font(.system(.headline, design: .rounded).weight(.bold))
                                        .foregroundColor(Palette.onPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Palette.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        EmptyGarden(
                            title: "Nothing parsed yet",
                            systemImage: "doc.text.magnifyingglass",
                            message: "Drop recipe text with clear sections, or paste a public recipe URL starting with https://"
                        )
                    }

                    if let successText {
                        Text(successText)
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.onPrimary)
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .tabRootPadding()
            }
            .gardenPage()
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func parsePasted() {
        errorText = nil
        successText = nil
        do {
            draft = try RecipeImporter.parseText(input)
        } catch {
            draft = nil
            errorText = error.localizedDescription
        }
    }

    private func parseLink() async {
        errorText = nil
        successText = nil
        isLoading = true
        defer { isLoading = false }
        let candidate = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString: String
        if candidate.lowercased().hasPrefix("http") {
            urlString = candidate.components(separatedBy: .newlines).first ?? candidate
        } else {
            errorText = "Paste a full https link to fetch."
            return
        }
        do {
            draft = try await RecipeImporter.parseURL(urlString)
        } catch {
            draft = nil
            errorText = error.localizedDescription
        }
    }
}
