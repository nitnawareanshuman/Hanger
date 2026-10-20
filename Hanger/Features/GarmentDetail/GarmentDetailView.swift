import SwiftUI
import SwiftData

struct GarmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var garment: Garment
    let onMarkWorn: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    GarmentIllustration(garment: garment)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .padding(.horizontal, 20)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(garment.name).font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("\(garment.category.title) · \(garment.season.title)").font(.subheadline).foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            Circle().fill(Color(hex: garment.colorHex)).frame(width: 27, height: 27)
                                .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dominant colour").font(.caption).foregroundStyle(.secondary)
                                Text(garment.colorHex.uppercased()).font(.subheadline.weight(.semibold).monospaced())
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(garment.wearCount)").font(.title2.bold().monospacedDigit())
                                Text("total wears").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color.wardrobeChip, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 22)
                    Button(action: onMarkWorn) {
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
                    }
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
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
