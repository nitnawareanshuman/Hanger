import PhotosUI
import SwiftUI
import SwiftData
import AVFoundation

struct GarmentCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var camera = CameraService()
    @State private var viewModel = GarmentCaptureViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.capturedImage != nil {
                    review
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
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            viewModel.errorMessage = "This photo couldn't be loaded."
                            selectedPhoto = nil
                            return
                        }
                        camera.stop()
                        viewModel.handleCapture(image)
                    } catch {
                        viewModel.errorMessage = "Couldn't load the selected photo. \(error.localizedDescription)"
                    }
                    selectedPhoto = nil
                }
            }
            .alert("Camera unavailable", isPresented: Binding(
                get: { camera.errorMessage != nil },
                set: { if !$0 { camera.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { camera.errorMessage = nil }
            } message: {
                Text(camera.errorMessage ?? "You can import a photo instead.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var cameraScreen: some View {
        ZStack {
            if camera.isRunning {
                CameraPreview(session: camera.session).ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(camera.errorMessage ?? "Preparing camera…")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    if camera.errorMessage != nil {
                        Button("Try camera again") {
                            Task { await camera.configureAndStart() }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .foregroundStyle(.white)
                .padding(24)
            }

            GarmentOutlineGuide()
                .stroke(.white.opacity(0.82), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 7]))
                .padding(.horizontal, 42)
                .padding(.vertical, 100)
                .allowsHitTesting(false)

            VStack {
                Text("ADD A PIECE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.58), in: Capsule())

                Spacer()

                Text("Use a plain background and keep the whole garment inside the outline.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.60), in: Capsule())
                    .padding(.bottom, 14)

                HStack(alignment: .center) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        VStack(spacing: 5) {
                            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 21))
                            Text("Library").font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 66, height: 58)
                    }

                    Spacer()

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
                            .frame(width: 70, height: 70)
                            .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 5).padding(-7))
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.black.opacity(0.75))
                            )
                    }
                    .disabled(!camera.isRunning)
                    .accessibilityLabel("Take garment photo")

                    Spacer()
                    Color.clear.frame(width: 66, height: 58)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
            .foregroundStyle(.white)
        }
    }

    private var review: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    CaptureCheckerboard()
                    if let image = viewModel.processedImage ?? viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    }
                    if viewModel.isProcessing {
                        VStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Removing background…").font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(18)
                        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.orange)
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
                            Text("Dominant color")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                            Text("\(viewModel.dominantColorName.capitalized) · \(viewModel.dominantColorHex)")
                                .font(.subheadline.monospaced().bold())
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Button {
                            viewModel.retake()
                            Task { await camera.configureAndStart() }
                        } label: {
                            Label("Retake", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            viewModel.save(context: modelContext)
                            if viewModel.didSave {
                                camera.stop()
                                dismiss()
                            }
                        } label: {
                            Label("Save garment", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.wardrobeAccent, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .disabled(viewModel.isProcessing)
                    }
                }
                .padding(16)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(16)
        }
        .background(Color.black)
    }
}

private struct GarmentOutlineGuide: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.34, y: h * 0.08))
        p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.14))
        p.addLine(to: CGPoint(x: w * 0.05, y: h * 0.30))
        p.addLine(to: CGPoint(x: w * 0.19, y: h * 0.43))
        p.addLine(to: CGPoint(x: w * 0.29, y: h * 0.35))
        p.addLine(to: CGPoint(x: w * 0.29, y: h * 0.93))
        p.addQuadCurve(to: CGPoint(x: w * 0.71, y: h * 0.93), control: CGPoint(x: w * 0.50, y: h * 0.98))
        p.addLine(to: CGPoint(x: w * 0.71, y: h * 0.35))
        p.addLine(to: CGPoint(x: w * 0.81, y: h * 0.43))
        p.addLine(to: CGPoint(x: w * 0.95, y: h * 0.30))
        p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.14))
        p.addLine(to: CGPoint(x: w * 0.66, y: h * 0.08))
        p.addQuadCurve(to: CGPoint(x: w * 0.34, y: h * 0.08), control: CGPoint(x: w * 0.50, y: h * 0.20))
        p.closeSubpath()
        return p
    }
}

private struct CaptureCheckerboard: View {
    var body: some View {
        Canvas { context, size in
            let side: CGFloat = 18
            for row in 0..<Int(ceil(size.height / side)) {
                for column in 0..<Int(ceil(size.width / side)) {
                    let rect = CGRect(
                        x: CGFloat(column) * side,
                        y: CGFloat(row) * side,
                        width: side,
                        height: side
                    )
                    context.fill(
                        Path(rect),
                        with: .color((row + column).isMultiple(of: 2) ? .gray.opacity(0.19) : .gray.opacity(0.07))
                    )
                }
            }
        }
    }
}
