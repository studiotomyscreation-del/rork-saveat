import AVFoundation
import SwiftUI

/// Camera availability states surfaced to the scanner UI.
enum CameraStatus: Equatable {
    case idle
    case ready
    case denied
    case noDevice
    case failed(String)
}

/// Thin AVFoundation wrapper for the kitchen scanner.
@Observable
final class CameraService: NSObject {
    private(set) var status: CameraStatus = .idle
    private(set) var capturedImage: UIImage?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "saveat.camera.session")
    private var isConfigured = false

    /// Requests access then configures the capture session.
    func start() async {
        let granted = await requestAccess()
        guard granted else {
            status = .denied
            return
        }

        if !isConfigured {
            let outcome = await configure()
            switch outcome {
            case .success:
                isConfigured = true
            case .noDevice:
                status = .noDevice
                return
            case .failure(let message):
                status = .failed(message)
                return
            }
        }

        status = .ready
        sessionQueue.async { [session] in
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func capturePhoto() {
        guard status == .ready else { return }
        let settings = AVCapturePhotoSettings()
        sessionQueue.async { [photoOutput] in
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func reset() {
        capturedImage = nil
    }

    private func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    private enum ConfigureOutcome {
        case success
        case noDevice
        case failure(String)
    }

    private func configure() async -> ConfigureOutcome {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [session, photoOutput] in
                session.beginConfiguration()
                session.sessionPreset = .photo

                // `.external` keeps injected/USB cameras discoverable alongside built-ins.
                var deviceTypes: [AVCaptureDevice.DeviceType] = [
                    .builtInWideAngleCamera,
                    .builtInDualCamera,
                    .builtInTripleCamera
                ]
                if #available(iOS 17.0, *) {
                    deviceTypes.append(.external)
                }

                let discovery = AVCaptureDevice.DiscoverySession(
                    deviceTypes: deviceTypes,
                    mediaType: .video,
                    position: .unspecified
                )

                guard let device = discovery.devices.first(where: { $0.position == .back })
                        ?? discovery.devices.first else {
                    session.commitConfiguration()
                    continuation.resume(returning: .noDevice)
                    return
                }

                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    guard session.canAddInput(input) else {
                        session.commitConfiguration()
                        continuation.resume(returning: .failure("Entrée caméra indisponible"))
                        return
                    }
                    session.addInput(input)

                    guard session.canAddOutput(photoOutput) else {
                        session.commitConfiguration()
                        continuation.resume(returning: .failure("Sortie photo indisponible"))
                        return
                    }
                    session.addOutput(photoOutput)
                    session.commitConfiguration()
                    continuation.resume(returning: .success)
                } catch {
                    session.commitConfiguration()
                    continuation.resume(returning: .failure(error.localizedDescription))
                }
            }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        Task { @MainActor in
            self.capturedImage = image
        }
    }
}

/// Live camera preview layer bridged into SwiftUI.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                return AVCaptureVideoPreviewLayer()
            }
            return layer
        }
    }
}
