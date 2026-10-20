import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Garment> { !$0.isArchived },
        sort: \Garment.createdAt,
        order: .reverse
    )
    private var garments: [Garment]

    @State private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wardrobeBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        if viewModel.isFallback {
                            Label("Using offline recommendations", systemImage: "wifi.slash")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        if !viewModel.summary.isEmpty {
                            Text(viewModel.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let error = viewModel.errorMessage, viewModel.isFallback {
                            Text(error).font(.caption).foregroundStyle(.secondary)
                        }

                        if viewModel.isLoading {
                            ProgressView("Reviewing your wardrobe…")
                                .frame(maxWidth: .infinity)
                                .padding(36)
                        } else if viewModel.recommendations.isEmpty {
                            ContentUnavailableView(
                                "You're all caught up",
                                systemImage: "checkmark.circle",
                                description: Text("There are no outstanding suggestions right now.")
                            )
                        } else {
                            ForEach(viewModel.recommendations) { item in
                                recommendationCard(item)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load(garments: garments) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Refresh recommendations")
                }
            }
            .task {
                if viewModel.recommendations.isEmpty {
                    await viewModel.load(garments: garments)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("HANGER INSIGHTS", systemImage: "sparkles")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(Color.wardrobeAccent)

            Text("A wardrobe that\nworks harder.")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text("Thoughtful suggestions, always your choice.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func recommendationCard(_ item: WardrobeAIRecommendation) -> some View {
        let garment = garments.first { $0.id.uuidString == item.garmentId }

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: garment?.colorHex ?? "#8A8A8A").opacity(0.16))
                    Image(systemName: garment?.category.illustrationSymbol ?? "tshirt")
                        .font(.system(size: 27))
                        .foregroundStyle(Color.wardrobeInk)
                }
                .frame(width: 66, height: 72)

                VStack(alignment: .leading, spacing: 5) {
                    Text(garment?.name ?? "Wardrobe item").font(.headline)
                    Text(item.action.rawValue.capitalized)
                        .font(.caption.bold())
                        .foregroundStyle(Color.wardrobeAccent)
                    Text(item.reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack {
                Text("Confidence").font(.caption).foregroundStyle(.secondary)
                ProgressView(value: item.confidence)
                    .tint(Color.wardrobeAccent)
                    .frame(maxWidth: 90)
                Text("\(Int(item.confidence * 100))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                Spacer()
            }

            HStack(spacing: 10) {
                Button { viewModel.dismiss(item) } label: {
                    Text("Dismiss").frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.accept(item, garments: garments, context: modelContext)
                } label: {
                    Text(item.action == .donate ? "Accept & archive" : "Accept")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.wardrobeInk)
            }
        }
        .padding(16)
        .background(Color.wardrobeChip, in: RoundedRectangle(cornerRadius: 20))
    }
}
