import SwiftUI

struct PackingListView: View {
    @EnvironmentObject private var store: AppStore
    let destinationId: UUID

    @State private var newCategoryTitle = ""
    @State private var editingCategory: PackCategory?
    @State private var editingItem: PackItem?
    @State private var addingItemCategoryId: UUID?
    @State private var templateTitle = ""
    @State private var copySourceId: UUID?

    var body: some View {
        Group {
            if let destination = store.destination(id: destinationId) {
                packingDesk(for: destination)
            } else {
                Text("This suitcase is no longer linked to a city.")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Palette.primary)
                    .padding()
            }
        }
        .deskBackdrop()
        .navigationTitle("Packing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $editingCategory) { category in
            PackCategoryEditorView(category: category)
                .environmentObject(store)
        }
        .sheet(item: $editingItem) { item in
            PackItemEditorView(item: item)
                .environmentObject(store)
        }
        .sheet(isPresented: Binding(
            get: { addingItemCategoryId != nil },
            set: { presented in
                if presented == false {
                    addingItemCategoryId = nil
                }
            }
        )) {
            if let addingItemCategoryId {
                PackItemEditorView(categoryId: addingItemCategoryId)
                    .environmentObject(store)
            }
        }
        .onAppear {
            store.markTripEdited(destinationId)
        }
    }

    private func packingDesk(for destination: Destination) -> some View {
        let cats = store.categories(for: destinationId)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerStrip(imageName: "BannerPack", caption: "SUITCASE CHECK")
                DeskSurface {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(destination.city.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Palette.accent)
                        Text("Packing sorter")
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundStyle(Palette.primary)
                        Text("Categories stay tied to this ticket. Check items as they go in the case.")
                            .font(.system(.subheadline, design: .default))
                            .foregroundStyle(Palette.accent)
                    }
                }
                .padding(.horizontal, 16)
                if cats.isEmpty {
                    DeskSurface {
                        Text("No categories yet. Add Documents, Tech, or a custom group.")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(Palette.accent)
                    }
                    .padding(.horizontal, 16)
                }
                ForEach(Array(cats.enumerated()), id: \.element.id) { index, category in
                    categoryBlock(category, index: index, total: cats.count)
                }
                addCategoryField
                    .padding(.horizontal, 16)
                templateDesk
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
            }
        }
    }

    private func categoryBlock(_ category: PackCategory, index: Int, total: Int) -> some View {
        let categoryItems = store.items(for: category.id)
        let done = categoryItems.filter(\.isComplete).count
        return DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title)
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Palette.primary)
                        Text(TripFormat.packedCount(done: done, total: categoryItems.count))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Palette.accent)
                    }
                    Spacer()
                    Button("Edit") {
                        editingCategory = category
                    }
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(Palette.accent)
                }
                HStack(spacing: 8) {
                    moveChip("Move Up", enabled: index > 0) {
                        store.moveCategory(category.id, up: true)
                    }
                    moveChip("Move Down", enabled: index < total - 1) {
                        store.moveCategory(category.id, up: false)
                    }
                }
                ForEach(Array(categoryItems.enumerated()), id: \.element.id) { itemIndex, item in
                    SuitcaseCheckRow(
                        title: item.title,
                        isComplete: item.isComplete,
                        canMoveUp: itemIndex > 0,
                        canMoveDown: itemIndex < categoryItems.count - 1,
                        onToggle: {
                            store.toggleItem(item.id)
                        },
                        onMoveUp: {
                            store.moveItem(item.id, up: true)
                        },
                        onMoveDown: {
                            store.moveItem(item.id, up: false)
                        },
                        onEdit: {
                            editingItem = item
                        }
                    )
                }
                Button {
                    addingItemCategoryId = category.id
                } label: {
                    Label("Add item", systemImage: "plus")
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(Palette.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var addCategoryField: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("New category")
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(Palette.accent)
                DeskTextField(placeholder: "Category name", text: $newCategoryTitle)
                Button("Add category") {
                    let title = newCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if title.isEmpty == false {
                        store.addCategory(destinationId: destinationId, title: title)
                        newCategoryTitle = ""
                    }
                }
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(Palette.background)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Palette.primary)
                .clipShape(Capsule())
            }
        }
    }

    private var templateDesk: some View {
        let otherCities = store.destinations.filter { destination in
            destination.id != destinationId
        }
        return DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("SUITCASE TEMPLATES")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text("Save this case, apply a template, or copy from another city. Apply and copy replace the current list; items land unchecked.")
                    .font(.system(.subheadline, design: .default))
                    .foregroundStyle(Palette.accent)
                DeskTextField(placeholder: "Template name", text: $templateTitle)
                Button("Save as template") {
                    store.saveTemplate(from: destinationId, title: templateTitle)
                    templateTitle = ""
                    Haptics.confirm()
                }
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(Palette.background)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Palette.primary)
                .clipShape(Capsule())
                if store.packingTemplates.isEmpty == false {
                    ForEach(store.packingTemplates) { template in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.title)
                                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                                    .foregroundStyle(Palette.primary)
                                Text("\(template.categories.count) groups")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(Palette.accent)
                            }
                            Spacer()
                            Button("Apply") {
                                store.applyTemplate(template.id, to: destinationId)
                                Haptics.tap()
                            }
                            .font(.system(.caption, design: .serif).weight(.semibold))
                            .foregroundStyle(Palette.background)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Palette.accent)
                            .clipShape(Capsule())
                            Button("Delete") {
                                store.deleteTemplate(template.id)
                            }
                            .font(.system(.caption, design: .serif).weight(.semibold))
                            .foregroundStyle(Palette.primary)
                        }
                    }
                }
                if otherCities.isEmpty == false {
                    Picker("Copy from city", selection: $copySourceId) {
                        Text("Copy from city").tag(Optional<UUID>.none)
                        ForEach(otherCities) { destination in
                            Text(destination.city).tag(Optional(destination.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Palette.primary)
                    Button("Copy packing") {
                        if let copySourceId {
                            store.copyPacking(from: copySourceId, to: destinationId)
                            Haptics.confirm()
                            self.copySourceId = nil
                        }
                    }
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(copySourceId == nil ? Palette.accent : Palette.background)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(copySourceId == nil ? Palette.background.opacity(0.35) : Palette.primary)
                    .clipShape(Capsule())
                    .disabled(copySourceId == nil)
                }
            }
        }
    }

    private func moveChip(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(.caption2, design: .monospaced).weight(.semibold))
            .foregroundStyle(enabled ? Palette.primary : Palette.accent.opacity(0.4))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Palette.background.opacity(0.4))
            .clipShape(Capsule())
            .disabled(enabled == false)
    }
}
