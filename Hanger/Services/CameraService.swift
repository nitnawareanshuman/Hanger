import AVFoundation
import UIKit
import Combine

enum CameraServiceError: LocalizedError {
    case noCamera
    case cannotAddInput
    case cannotAddOutput
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noCamera: "No camera is available on this device."
        case .cannotAddInput: "The camera input couldn't be configured."
        case .cannotAddOutput: "The photo output couldn't be configured."
        case .permissionDenied: "Camera access is denied. Enable it in Settings."
        }
    }
}

@MainActor
final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published private(set) var isRunning = false
    @Published var errorMessage: String?

    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "hanger.camera.session")
    private var captureCompletion: ((Result<UIImage, Error>) -> Void)?

    func configureAndStart() async {
        let permission = AVCaptureDevice.authorizationStatus(for: .video)
        let allowed: Bool
        if permission == .authorized {
            allowed = true
        } else if permission == .notDetermined {
            allowed = await AVCaptureDevice.requestAccess(for: .video)
        } else {
            allowed = false
        }

        guard allowed else {
            errorMessage = CameraServiceError.permissionDenied.localizedDescription
            return
        }

        do {
            try configureSession()
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if !self.session.isRunning { self.session.startRunning() }
                Task { @MainActor in self.isRunning = true }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraServiceError.noCamera
        }
        let input = try AVCaptureDeviceInput(device: device)
        if session.inputs.isEmpty {
            guard session.canAddInput(input) else { throw CameraServiceError.cannotAddInput }
            session.addInput(input)
        }
        if session.outputs.isEmpty {
            guard session.canAddOutput(output) else { throw CameraServiceError.cannotAddOutput }
            session.addOutput(output)
            output.maxPhotoQualityPrioritization = .quality
        }
    }

    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            guard isRunning else {
                continuation.resume(throwing: CameraServiceError.noCamera)
                return
            }
            captureCompletion = { result in continuation.resume(with: result) }
            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            Task { @MainActor in self.isRunning = false }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                captureCompletion?(.failure(error))
            } else if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                captureCompletion?(.success(image))
            } else {
                captureCompletion?(.failure(CameraServiceError.noCamera))
            }
            captureCompletion = nil
        }
    }
}
