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

    @Query(
        filter: #Predicate<Garment> { $0.isArchived },
        sort: \Garment.createdAt,
        order: .reverse
    )
    private var archived: [Garment]

    @State private var viewModel = InsightsViewModel()

    /// Hide suggestions for garments that were deleted or archived since the analysis ran.
    private var visibleRecommendations: [WardrobeAIRecommendation] {
        viewModel.recommendations.filter { item in
            garments.contains { $0.id.uuidString == item.garmentId }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wardrobeBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        statusRow
                        content
                        archivedSection
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
                    .disabled(viewModel.isLoading || garments.isEmpty)
                    .accessibilityLabel("Refresh recommendations")
                }
            }
            .task {
                if viewModel.needsRefresh(for: garments) {
                    await viewModel.load(garments: garments)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if garments.isEmpty {
            ContentUnavailableView(
                "Nothing to review yet",
                systemImage: "hanger",
                description: Text("Add a few garments and Hanger will suggest what to keep, rotate or let go.")
            )
        } else if viewModel.isLoading {
            ProgressView("Reviewing your wardrobe…")
                .frame(maxWidth: .infinity)
                .padding(36)
        } else if visibleRecommendations.isEmpty {
            ContentUnavailableView(
                "You're all caught up",
                systemImage: "checkmark.circle",
                description: Text("There are no outstanding suggestions right now.")
            )
        } else {
            ForEach(visibleRecommendations) { item in
                RecommendationCardView(
                    recommendation: item,
                    garment: garments.first { $0.id.uuidString == item.garmentId },
                    onDismiss: { withAnimation(.snappy) { viewModel.dismiss(item) } },
                    onAccept: {
                        withAnimation(.snappy) {
                            viewModel.accept(item, garments: garments, context: modelContext)
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        if viewModel.isFallback {
            Label("Using offline recommendations", systemImage: "wifi.slash")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        } else if !viewModel.recommendations.isEmpty {
            Label("AI-powered suggestions", systemImage: "sparkles")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.wardrobeAccent)
        }

        if !viewModel.summary.isEmpty {
            Text(viewModel.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        if let error = viewModel.errorMessage {
            Text(error).font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var archivedSection: some View {
        if !archived.isEmpty {
            DisclosureGroup("Archived (\(archived.count))") {
                VStack(spacing: 10) {
                    ForEach(archived) { garment in
                        HStack(spacing: 12) {
                            GarmentImageView(garment: garment, padding: 3)
                                .frame(width: 46, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Text(garment.name).font(.subheadline.weight(.medium))
                            Spacer()
                            Button("Restore") {
                                withAnimation(.snappy) {
                                    viewModel.restore(garment, context: modelContext)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .tint(Color.wardrobeInk)
            .padding(16)
            .background(Color.wardrobeChip, in: RoundedRectangle(cornerRadius: 20))
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
}
