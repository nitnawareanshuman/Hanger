import AVFoundation
import UIKit
import Combine

enum CameraServiceError: LocalizedError {
    case noCamera, cannotAddInput, cannotAddOutput, permissionDenied, captureInProgress, sessionNotRunning

    var errorDescription: String? {
        switch self {
        case .noCamera: return "No back camera is available on this device."
        case .cannotAddInput: return "The camera input couldn't be configured."
        case .cannotAddOutput: return "The photo output couldn't be configured."
        case .permissionDenied: return "Camera access is denied. Enable it in Settings."
        case .captureInProgress: return "A photo capture is already in progress."
        case .sessionNotRunning: return "The camera is not ready yet."
        }
    }
}

/// Owns AVCaptureSession. All session configuration and start/stop operations run on sessionQueue.
@MainActor
final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published private(set) var isRunning = false
    @Published private(set) var isConfigured = false
    @Published var errorMessage: String?

    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.hanger.camera.session")
    private var captureCompletion: ((Result<UIImage, Error>) -> Void)?

    func configureAndStart() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let allowed: Bool
        switch status {
        case .authorized: allowed = true
        case .notDetermined: allowed = await AVCaptureDevice.requestAccess(for: .video)
        default: allowed = false
        }

        guard allowed else {
            errorMessage = CameraServiceError.permissionDenied.localizedDescription
            return
        }

        do {
            try await configureSessionIfNeeded()
            try await startSession()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func configureSessionIfNeeded() async throws {
        guard !isConfigured else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraServiceError.noCamera)
                    return
                }

                do {
                    self.session.beginConfiguration()
                    self.session.sessionPreset = .photo
                    defer { self.session.commitConfiguration() }

                    guard let device = AVCaptureDevice.default(
                        .builtInWideAngleCamera,
                        for: .video,
                        position: .back
                    ) else {
                        throw CameraServiceError.noCamera
                    }

                    let input = try AVCaptureDeviceInput(device: device)
                    if self.session.inputs.isEmpty {
                        guard self.session.canAddInput(input) else {
                            throw CameraServiceError.cannotAddInput
                        }
                        self.session.addInput(input)
                    }

                    if !self.session.outputs.contains(where: { $0 === self.output }) {
                        guard self.session.canAddOutput(self.output) else {
                            throw CameraServiceError.cannotAddOutput
                        }
                        self.session.addOutput(self.output)
                        self.output.maxPhotoQualityPrioritization = .quality
                    }

                    continuation.resume()
                    Task { @MainActor in self.isConfigured = true }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func startSession() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraServiceError.noCamera)
                    return
                }

                if !self.session.isRunning {
                    self.session.startRunning()
                }
                let running = self.session.isRunning

                Task { @MainActor in
                    self.isRunning = running
                    if running {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: CameraServiceError.sessionNotRunning)
                    }
                }
            }
        }
    }

    func capturePhoto() async throws -> UIImage {
        guard isRunning else { throw CameraServiceError.sessionNotRunning }
        guard captureCompletion == nil else { throw CameraServiceError.captureInProgress }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UIImage, Error>) in
            captureCompletion = { continuation.resume(with: $0) }
            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
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
        let result: Result<UIImage, Error>
        if let error {
            result = .failure(error)
        } else if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            result = .success(image)
        } else {
            result = .failure(CameraServiceError.noCamera)
        }

        Task { @MainActor in
            captureCompletion?(result)
            captureCompletion = nil
        }
    }
}
