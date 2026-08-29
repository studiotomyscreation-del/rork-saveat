import AVFoundation
import SwiftUI

/// Live barcode capture for the grocery scanning session.
///
/// Runs the real AVFoundation pipeline everywhere. When no capture device is
/// available the view falls back to manual entry instead of faking a camera.
@Observable
final class BarcodeCameraService: NSObject {
    nonisolated enum State: Equatable, Sendable {
        case idle
        case running
        case denied
        case noDevice
        case failed
    }

    private(set) var state: State = .idle
    /// Last barcode read, published so the view can react.
    private(set) var lastCode: String?

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "saveat.barcode.session")
    private var isConfigured = false
    private var recentCodes: [String: Date] = [:]

    /// Called on the main actor for every accepted barcode.
    var onCode: ((String) -> Void)?

    func start() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                state = .denied
                return
            }
        default:
            state = .denied
            return
        }

        guard configureIfNeeded() else { return }

        queue.async { [session] in
            guard !session.isRunning else { return }
            session.startRunning()
        }
        state = .running
    }

    func stop() {
        queue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
        if state == .running { state = .idle }
    }

    private func configureIfNeeded() -> Bool {
        guard !isConfigured else { return true }

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

        guard let device = discovery.devices.first(where: { $0.position == .back }) ?? discovery.devices.first else {
            state = .noDevice
            return false
        }

        session.beginConfiguration()
        session.sessionPreset = .high

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                state = .failed
                return false
            }
            session.addInput(input)
        } catch {
            session.commitConfiguration()
            state = .failed
            return false
        }

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            state = .failed
            return false
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: queue)
        let wanted: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .upce, .code128, .itf14, .dataMatrix]
        output.metadataObjectTypes = wanted.filter { output.availableMetadataObjectTypes.contains($0) }

        session.commitConfiguration()
        isConfigured = true
        return true
    }

    /// Debounces repeated reads of the same code while the camera stays pointed at it.
    private func accept(_ code: String) {
        let now = Date()
        recentCodes = recentCodes.filter { now.timeIntervalSince($0.value) < 6 }
        if let seen = recentCodes[code], now.timeIntervalSince(seen) < 3 { return }
        recentCodes[code] = now
        lastCode = code
        onCode?(code)
    }
}

extension BarcodeCameraService: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        let codes = metadataObjects
            .compactMap { $0 as? AVMetadataMachineReadableCodeObject }
            .compactMap(\.stringValue)
            .filter { $0.count >= 6 }

        guard let code = codes.first else { return }
        Task { @MainActor [weak self] in
            self?.accept(code)
        }
    }
}

/// Thin UIKit bridge showing the live capture session.
struct BarcodePreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                return AVCaptureVideoPreviewLayer()
            }
            return layer
        }
    }
}
