import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Query(sort: \Garment.createdAt, order: .reverse) private var savedGarments: [Garment]
    @State private var viewModel = WardrobeViewModel()

    private var garments: [Garment] {
        #if DEBUG
        return savedGarments.isEmpty ? WardrobeSampleData.garments : savedGarments
        #else
        return savedGarments
        #endif
    }
    private var visibleGarments: [Garment] { viewModel.filtered(garments) }
    private var hangables: [Garment] { visibleGarments.filter { [.tops, .dresses, .outerwear].contains($0.category) } }
    private var foldables: [Garment] { visibleGarments.filter { $0.category == .bottoms } }
    private var footwear: [Garment] { visibleGarments.filter { $0.category == .shoes } }
    private var accessories: [Garment] { visibleGarments.filter { [.accessories, .bags].contains($0.category) } }

    var body: some View {
        ZStack {
            Color.wardrobeBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    summaryStrip
                    CategoryFilterView(selection: $viewModel.selectedCategory)
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Your wardrobe").font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("\(visibleGarments.count) pieces, thoughtfully kept").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.showCapturePlaceholder = true
                        } label: {
                            Image(systemName: "camera.fill").font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white).frame(width: 42, height: 42)
                                .background(Color.wardrobeInk, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityLabel("Capture garment")
                    }
                    .padding(.horizontal, 20)
                    WardrobeCabinet {
                        VStack(spacing: 14) {
                            HangingRailSection(garments: hangables, onSelect: select)
                            WardrobeShelfView(title: "Folded essentials", subtitle: "Shelf 02", garments: foldables, compact: true, onSelect: select)
                            WardrobeShelfView(title: "Footwear", subtitle: "Shelf 03", garments: footwear, compact: true, onSelect: select)
                            DrawerSection(garments: accessories, onSelect: select)
                        }
                        .padding(14)
                    }
                    .padding(.horizontal, 14)
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Color.wardrobeAccent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("A little wardrobe wisdom").font(.system(size: 14, weight: .bold, design: .rounded))
                            Text("Wear what you love. Let the rest earn its place.").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.wardrobeChip, in: RoundedRectangle(cornerRadius: 18)).padding(.horizontal, 20)
                }
                .padding(.top, 10).padding(.bottom, 28)
            }
        }
        .sheet(item: selectedGarmentBinding) { garment in
            GarmentDetailView(garment: garment) { viewModel.markAsWorn(garment) }
                .background(Color.wardrobeBackground)
        }
        .sheet(isPresented: $viewModel.showCapturePlaceholder) {
            CaptureComingSoonView().presentationDetents([.medium]).presentationDragIndicator(.visible)
        }
    }

    private var selectedGarmentBinding: Binding<Garment?> {
        Binding(get: { garments.first { $0.id == viewModel.selectedGarmentID } }, set: { viewModel.selectedGarmentID = $0?.id })
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Image(systemName: "hanger").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.wardrobeAccent)
                    Text("HANGER").font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(2.6).foregroundStyle(.secondary)
                }
                Text("Good style,\nright where you left it.")
                    .font(.system(size: 28, weight: .bold, design: .rounded)).tracking(-0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            ZStack {
                Circle().fill(Color.wardrobeAccent.opacity(0.13)).frame(width: 52, height: 52)
                Image(systemName: "person.crop.circle.fill").font(.system(size: 34)).foregroundStyle(Color.wardrobeAccent)
            }
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, 20)
    }

    private var summaryStrip: some View {
        HStack(spacing: 0) {
            summaryMetric(value: "\(garments.count)", label: "PIECES", symbol: "square.grid.2x2")
            Divider().frame(height: 36)
            summaryMetric(value: "\(garments.reduce(0) { $0 + $1.wearCount })", label: "TOTAL WEARS", symbol: "arrow.clockwise")
            Divider().frame(height: 36)
            summaryMetric(value: "\(garments.filter { $0.wearCount == 0 }.count)", label: "UNWORN", symbol: "sparkles")
        }
        .padding(.vertical, 13).background(Color.wardrobeChip, in: RoundedRectangle(cornerRadius: 18)).padding(.horizontal, 20)
    }

    private func summaryMetric(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 10, weight: .bold)).foregroundStyle(Color.wardrobeAccent)
                Text(value).font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
            }
            Text(label).font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func select(_ garment: Garment) { viewModel.select(garment) }
}

private struct WardrobeCabinet<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [.wardrobeWoodLight, .wardrobeWoodDark], startPoint: .top, endPoint: .bottom))
                .frame(height: 14)
                .overlay(alignment: .top) { Rectangle().fill(Color.wardrobeWoodHighlight.opacity(0.9)).frame(height: 2).padding(.horizontal, 7) }
            content.padding(8).background(LinearGradient(colors: [.wardrobeWoodLight, .wardrobeWoodDark], startPoint: .leading, endPoint: .trailing))
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [.wardrobeWoodLight, .wardrobeWoodDark], startPoint: .top, endPoint: .bottom))
                .frame(height: 15).shadow(color: .black.opacity(0.16), radius: 4, y: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color.wardrobeWoodDark.opacity(0.22), radius: 18, y: 10)
    }
}

private struct HangingRailSection: View {
    let garments: [Garment]
    let onSelect: (Garment) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Hanging favourites").font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Text("RAIL 01").font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.2).foregroundStyle(.secondary)
            }.padding(.bottom, 12)
            ZStack(alignment: .top) {
                Capsule().fill(LinearGradient(colors: [.gray.opacity(0.28), .white.opacity(0.9), .gray.opacity(0.35)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 7).padding(.horizontal, 7).shadow(color: .black.opacity(0.16), radius: 2, y: 2)
                if garments.isEmpty {
                    Text("Your hanging space is waiting").font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).padding(.top, 55).padding(.bottom, 20)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 2) {
                            ForEach(Array(garments.enumerated()), id: \.element.id) { index, garment in
                                HangingGarmentView(garment: garment, index: index) { onSelect(garment) }
                                    .frame(width: 82, height: 174).draggable(garment.id.uuidString)
                            }
                        }.padding(.top, 4)
                    }.padding(.top, 2)
                }
            }
        }
        .padding(14).background(Color.wardrobeInterior, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.wardrobeWoodHighlight.opacity(0.4), lineWidth: 1))
    }
}

private struct HangingGarmentView: View {
    let garment: Garment
    let index: Int
    let onSelect: () -> Void
    @State private var swings = false
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                HangerShape().stroke(Color.wardrobeMetal, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 36, height: 24).padding(.top, 5)
                GarmentIllustration(garment: garment).frame(width: 68, height: 118)
                    .clipShape(GarmentBodyShape()).overlay(GarmentBodyShape().stroke(Color.white.opacity(0.3), lineWidth: 1)).padding(.top, -1)
            }
            .rotationEffect(.degrees(swings ? (index.isMultiple(of: 2) ? 1.8 : -1.5) : (index.isMultiple(of: 2) ? -1.8 : 1.5)), anchor: .top)
            .frame(maxHeight: .infinity, alignment: .top).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2 + Double(index % 3) * 0.3).repeatForever(autoreverses: true).delay(Double(index) * 0.12)) { swings = true }
        }
        .accessibilityLabel(garment.name)
    }
}

private struct DrawerSection: View {
    let garments: [Garment]
    let onSelect: (Garment) -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Accessories drawer").font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Text("DRAWER 04").font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(.secondary)
            }.padding(.bottom, 10)
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [.wardrobeWoodLight, .wardrobeWoodDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 15).overlay(alignment: .center) { Capsule().fill(Color.wardrobeMetal.opacity(0.75)).frame(width: 42, height: 3) }
            if garments.isEmpty {
                Text("Add watches, bags and little details").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 22)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(garments) { garment in
                            Button { onSelect(garment) } label: {
                                VStack(spacing: 7) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 13).fill(Color(hex: garment.colorHex).opacity(0.15))
                                        Image(systemName: garment.category.illustrationSymbol).font(.system(size: 26, weight: .medium)).foregroundStyle(Color(hex: garment.colorHex))
                                    }.frame(width: 58, height: 52)
                                    Text(garment.name).font(.system(size: 10, weight: .medium)).lineLimit(1)
                                }.frame(width: 72)
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(.vertical, 12)
            }
        }
        .padding(14).background(Color.wardrobeInterior, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct CaptureComingSoonView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.aperture").font(.system(size: 42)).foregroundStyle(Color.wardrobeAccent)
            Text("Add to your wardrobe").font(.title2.bold())
            Text("Connect your existing GarmentCaptureView here to use the live camera and image-processing flow.")
                .multilineTextAlignment(.center).font(.subheadline).foregroundStyle(.secondary).padding(.horizontal, 22)
            Button("Got it") { dismiss() }.buttonStyle(.borderedProminent).tint(Color.wardrobeInk)
        }.padding(24)
    }
}

#Preview {
    WardrobeView().modelContainer(WardrobeSampleData.previewContainer)
}
