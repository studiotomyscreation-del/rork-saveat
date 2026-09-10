import SwiftUI
import Vision

/// Photographs the printed date on a pack and asks the user to confirm it.
///
/// Text recognition only reads characters — it never judges whether the food
/// is still good. Nothing is saved without an explicit confirmation.
struct ExpiryDateCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    let onConfirm: (Date) -> Void

    @State private var camera = CameraService()
    @State private var isReading = false
    @State private var detected: Date?
    @State private var failed = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch camera.status {
            case .ready:
                CameraPreview(session: camera.session).ignoresSafeArea()
            case .denied:
                message(emoji: "🔒", title: S.Scan.cameraDeniedTitle.s,
                        detail: S.Scan.captureDeniedDetail.s)
            case .noDevice:
                message(emoji: "📷", title: S.Scan.noCameraTitle.s,
                        detail: S.Scan.captureNoDeviceDetail.s)
            case .failed:
                message(emoji: "⚠️", title: S.Scan.cameraFailedTitle.s,
                        detail: S.Scan.captureFailedDetail.s)
            case .idle:
                ProgressView().tint(.white)
            }

            VStack {
                topBar
                Spacer()
                guide
                Spacer()
                bottomBar
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.vertical, 22)

            if let detected {
                confirmationOverlay(detected)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .task { await camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.capturedImage) { _, image in
            guard let image else { return }
            read(image)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: detected)
    }

    private func message(emoji: String, title: String, detail: String) -> some View {
        VStack(spacing: 10) {
            Text(emoji).font(.system(size: 38))
            Text(title).font(Theme.title(19)).foregroundStyle(.white)
            Text(detail)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.18), in: .circle)
            }
            .accessibilityLabel(S.Common.close.s)
            Spacer()
            Text(S.Scan.captureTitle.s)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
    }

    private var guide: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.85), lineWidth: 2.5)
                .frame(width: 250, height: 90)

            Text(failed ? S.Scan.captureFailed.s : S.Scan.captureHint.s)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(failed ? Theme.terracotta : .white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var bottomBar: some View {
        Button {
            guard camera.status == .ready, !isReading else { return }
            isReading = true
            failed = false
            camera.capturePhoto()
            Haptics.soft()
        } label: {
            ZStack {
                Circle().stroke(.white.opacity(0.9), lineWidth: 3).frame(width: 74, height: 74)
                Circle().fill(.white).frame(width: 60, height: 60)
                if isReading {
                    ProgressView().tint(Theme.sageDeep)
                }
            }
        }
        .buttonStyle(SoftPressStyle())
        .disabled(camera.status != .ready)
        .opacity(camera.status == .ready ? 1 : 0.4)
        .accessibilityLabel(S.Scan.takePhoto.s)
    }

    private func confirmationOverlay(_ date: Date) -> some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 16) {
                Text(S.Scan.dateDetected.s)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Theme.inkSoft)

                Text(Self.longDate(date))
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.ink)

                Text(S.Scan.checkDate.s)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)

                Button(S.Scan.confirm.s) {
                    onConfirm(date)
                    Haptics.success()
                    dismiss()
                }
                .buttonStyle(SaveatButtonStyle())

                Button(S.Scan.retakePhoto.s) {
                    detected = nil
                    camera.reset()
                    Haptics.light()
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
            }
            .padding(24)
            .background(Theme.cream, in: .rect(cornerRadius: 28))
            .padding(.horizontal, 28)
        }
    }

    // MARK: Text recognition

    private func read(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            isReading = false
            failed = true
            camera.reset()
            return
        }

        Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["fr-FR", "en-US"]
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])

            let lines = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }

            let found = DateTextParser.firstDate(in: lines)

            await MainActor.run {
                isReading = false
                camera.reset()
                if let found {
                    detected = found
                    Haptics.success()
                } else {
                    failed = true
                    Haptics.warning()
                }
            }
        }
    }

    /// Full date in the reader's own order, so a US user never misreads 09/12.
    static func longDate(_ date: Date) -> String {
        Units.mediumDate(date)
    }
}

/// Extracts printed best-before dates from recognised text lines.
nonisolated enum DateTextParser {
    /// Day-first formats, as printed on European packs.
    private static let dayFirstFormats = [
        "dd/MM/yyyy", "dd/MM/yy", "dd.MM.yyyy", "dd.MM.yy", "dd-MM-yyyy", "dd-MM-yy", "MM/yyyy", "MM/yy"
    ]

    /// Month-first formats, as printed on US packs.
    private static let monthFirstFormats = [
        "MM/dd/yyyy", "MM/dd/yy", "MM.dd.yyyy", "MM.dd.yy", "MM-dd-yyyy", "MM-dd-yy", "MM/yyyy", "MM/yy"
    ]

    /// Tries the reader's own convention first, then the other one.
    ///
    /// A US pack printing 09/12 means September 12; a French one means 9 December.
    /// Guessing the wrong way round would silently create a three-month error.
    private static var formats: [String] {
        LanguageRuntime.current.readsDayFirstDates
            ? dayFirstFormats + monthFirstFormats
            : monthFirstFormats + dayFirstFormats
    }

    nonisolated static func firstDate(in lines: [String]) -> Date? {
        for line in lines {
            if let date = date(in: line) { return date }
        }
        return nil
    }

    nonisolated static func date(in text: String) -> Date? {
        let cleaned = text.replacingOccurrences(of: " ", with: "")
        let pattern = #"(\d{1,2}[\/\.\-]\d{1,2}[\/\.\-]\d{2,4})|(\d{1,2}[\/\.\-]\d{4})"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(cleaned.startIndex..., in: cleaned)

        for match in regex.matches(in: cleaned, range: range) {
            guard let matchRange = Range(match.range, in: cleaned) else { continue }
            let candidate = String(cleaned[matchRange])

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current

            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: candidate) {
                    // Printed dates are in the future; ignore obvious misreads.
                    if date > Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now {
                        return date
                    }
                }
            }
        }
        return nil
    }
}
