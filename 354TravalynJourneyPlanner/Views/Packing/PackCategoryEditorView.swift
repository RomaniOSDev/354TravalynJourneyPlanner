import SwiftUI

struct PackCategoryEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let category: PackCategory
    @State private var title = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerStrip(imageName: "BannerPack", caption: "CATEGORY LABEL")
                    DeskSurface {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name")
                                .font(.system(.caption, design: .serif).weight(.semibold))
                                .foregroundStyle(Palette.accent)
                            DeskTextField(placeholder: "Documents, Tech, Apparel", text: $title)
                        }
                    }
                    .padding(.horizontal, 16)
                    Button("Delete category", role: .destructive) {
                        store.deleteCategory(category.id)
                        dismiss()
                    }
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(Palette.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .deskBackdrop()
            .navigationTitle("Edit category")
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
                        if trimmed.isEmpty == false {
                            var updated = category
                            updated.title = trimmed
                            store.updateCategory(updated)
                            dismiss()
                        }
                    }
                    .foregroundStyle(Palette.primary)
                }
            }
            .onAppear {
                title = category.title
            }
        }
    }
}
