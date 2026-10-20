import SwiftUI
import SwiftData

struct GarmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var garment: Garment
    let onMarkWorn: () -> Void
    let onDelete: () -> Void

    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    GarmentImageView(garment: garment, padding: 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .background(Color(hex: garment.colorHex).opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(garment.name).font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("\(garment.category.title) · \(garment.season.title)")
                            .font(.subheadline).foregroundStyle(.secondary)

                        if !garment.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(garment.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(Color.wardrobeChip, in: Capsule())
                                    }
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            Circle().fill(Color(hex: garment.colorHex)).frame(width: 27, height: 27)
                                .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dominant colour").font(.caption).foregroundStyle(.secondary)
                                Text("\(ColorAnalysisService.name(forHex: garment.colorHex).capitalized) · \(garment.colorHex.uppercased())")
                                    .font(.subheadline.weight(.semibold))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(garment.wearCount)")
                                    .font(.title2.bold().monospacedDigit())
                                    .contentTransition(.numericText())
                                Text("total wears").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color.wardrobeChip, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 22)

                    Button {
                        withAnimation(.snappy) { onMarkWorn() }
                    } label: {
                        Label("Mark as worn", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.wardrobeInk, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(Color.wardrobeBackground)
                    }
                    .buttonStyle(.plain).padding(.horizontal, 20)

                    if let lastWornDate = garment.lastWornDate {
                        Text("Last worn \(lastWornDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Not worn yet").font(.caption).foregroundStyle(.secondary)
                    }

                    Button("Remove from wardrobe", role: .destructive) { confirmDelete = true }
                        .font(.footnote.weight(.semibold))
                        .padding(.top, 4)
                }
                .padding(.vertical, 18)
            }
            .background(Color.wardrobeBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color.wardrobeBackground, for: .navigationBar)
            .confirmationDialog("Remove \(garment.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Remove", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes the garment and its photo from this device.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
