import SwiftUI
import SwiftData
import AVFoundation

struct GarmentCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var camera = CameraService()
    @State private var viewModel = GarmentCaptureViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let image = viewModel.capturedImage {
                    review(image)
                } else {
                    cameraScreen
                }
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        camera.stop()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text(viewModel.capturedImage == nil ? "Capture garment" : "Review garment")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task { await camera.configureAndStart() }
            .onDisappear { camera.stop() }
            .alert("Camera", isPresented: Binding(
                get: { camera.errorMessage != nil },
                set: { if !$0 { camera.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { camera.errorMessage = nil }
            } message: {
                Text(camera.errorMessage ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var cameraScreen: some View {
        ZStack {
            CameraPreview(session: camera.session).ignoresSafeArea()
            VStack {
                Spacer()
                Text("Place one garment against a plain background")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(.bottom, 26)
                Button {
                    Task {
                        do {
                            let image = try await camera.capturePhoto()
                            camera.stop()
                            viewModel.handleCapture(image)
                        } catch {
                            camera.errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 5).padding(-7))
                }
                .padding(.bottom, 28)
                .accessibilityLabel("Take photo")
            }
        }
    }

    private func review(_ original: UIImage) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    Checkerboard()
                    if let image = viewModel.processedImage ?? viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    }
                    if viewModel.isProcessing {
                        ProgressView("Removing background…")
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .frame(height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                if let message = viewModel.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 14) {
                    TextField("Garment name", text: $viewModel.garmentName)
                        .textFieldStyle(.roundedBorder)

                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(GarmentCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .tint(.white)

                    Picker("Season", selection: $viewModel.selectedSeason) {
                        ForEach(Season.allCases) { season in
                            Text(season.title).tag(season)
                        }
                    }
                    .tint(.white)

                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: viewModel.dominantColorHex))
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Estimated dominant color").font(.caption).foregroundStyle(.white.opacity(0.65))
                            Text(viewModel.dominantColorHex).font(.subheadline.monospaced().bold())
                        }
                        Spacer()
                    }

                    Button {
                        viewModel.save(context: modelContext)
                        if viewModel.didSave { dismiss() }
                    } label: {
                        Label("Save to wardrobe", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.wardrobeAccent, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .disabled(viewModel.isProcessing)
                }
                .padding(16)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(16)
        }
        .background(Color.black)
    }
}

private struct Checkerboard: View {
    var body: some View {
        GeometryReader { proxy in
            let columns = max(1, Int(proxy.size.width / 18))
            let rows = max(1, Int(proxy.size.height / 18))
            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<columns, id: \.self) { column in
                            Rectangle()
                                .fill((row + column).isMultiple(of: 2) ? Color.white.opacity(0.12) : Color.gray.opacity(0.12))
                        }
                    }
                }
            }
        }
    }
}
