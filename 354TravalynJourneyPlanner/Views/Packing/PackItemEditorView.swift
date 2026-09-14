import SwiftUI

struct PackItemEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    private let existing: PackItem?
    private let categoryId: UUID

    @State private var title = ""

    init(item: PackItem) {
        existing = item
        categoryId = item.categoryId
    }

    init(categoryId: UUID) {
        existing = nil
        self.categoryId = categoryId
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerStrip(imageName: "BannerPack", caption: existing == nil ? "NEW TAG" : "EDIT TAG")
                    DeskSurface {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Item")
                                .font(.system(.caption, design: .serif).weight(.semibold))
                                .foregroundStyle(Palette.accent)
                            DeskTextField(
                                placeholder: "What goes in the case",
                                text: $title,
                                autocapitalization: .sentences
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    if existing != nil {
                        Button("Delete item", role: .destructive) {
                            if let existing {
                                store.deleteItem(existing.id)
                                dismiss()
                            }
                        }
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(Palette.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .deskBackdrop()
            .navigationTitle(existing == nil ? "Add item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            return
                        }
                        if var existing {
                            existing.title = trimmed
                            store.updateItem(existing)
                        } else {
                            store.addItem(categoryId: categoryId, title: trimmed)
                        }
                        dismiss()
                    }
                    .foregroundStyle(Palette.primary)
                }
            }
            .onAppear {
                title = existing?.title ?? ""
            }
        }
    }
}
