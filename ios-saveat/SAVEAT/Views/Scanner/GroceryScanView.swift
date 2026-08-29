import SwiftUI

/// One product captured during a shopping session.
struct ScanEntry: Identifiable, Hashable {
    var id: UUID = UUID()
    var product: ScannedProduct
    var quantity: Double = 1
    var bestBefore: Date?
    var location: StorageLocation

    var estimatedValue: Double { product.estimatedPrice * quantity }

    func toFoodItem() -> FoodItem {
        var item = FoodItem.from(product: product, quantity: quantity, bestBefore: bestBefore)
        item.location = location
        return item
    }
}

/// 🛒 SCANNER MES COURSES — optimised for fast, consecutive barcode scanning.
struct GroceryScanView: View {
    @Environment(AppStore.self) private var store
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss

    private enum Stage { case scanning, review }
    private enum Lookup: Equatable {
        case idle
        case searching(String)
        case failed(String)
    }

    @State private var camera = BarcodeCameraService()
    @State private var stage: Stage = .scanning
    @State private var entries: [ScanEntry] = []
    @State private var lookup: Lookup = .idle
    @State private var duplicate: DuplicateCandidate?
    @State private var lastAdded: ScanEntry?
    @State private var manualCode = ""
    @State private var showsManualEntry = false
    @State private var editingEntry: ScanEntry?
    @State private var showsPaywall = false

    private struct DuplicateCandidate: Identifiable {
        var id: String { product.barcode }
        var product: ScannedProduct
        var existing: FoodItem
    }

    private var total: Double {
        entries.reduce(0) { $0 + $1.estimatedValue }
    }

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()

            switch stage {
            case .scanning:
                scanningStage
            case .review:
                reviewStage
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: stage)
        .task {
            camera.onCode = { code in handle(code: code) }
            await camera.start()
        }
        .onDisappear { camera.stop() }
        .sheet(isPresented: $showsPaywall) { PaywallSheet(feature: .unlimitedScans) }
        .sheet(item: $editingEntry) { entry in
            ScanEntryEditor(entry: entry) { updated in
                if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                    entries[index] = updated
                }
            }
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
        }
        .alert("Saisir un code-barres", isPresented: $showsManualEntry) {
            TextField("Ex. 3017620422003", text: $manualCode)
                .keyboardType(.numberPad)
            Button("Rechercher") {
                let code = manualCode.trimmingCharacters(in: .whitespaces)
                manualCode = ""
                guard !code.isEmpty else { return }
                handle(code: code)
            }
            Button("Annuler", role: .cancel) { manualCode = "" }
        }
    }

    // MARK: - Scanning stage

    private var scanningStage: some View {
        VStack(spacing: 0) {
            viewfinder
            scanPanel
        }
        .ignoresSafeArea(edges: .top)
    }

    private var viewfinder: some View {
        ZStack {
            switch camera.state {
            case .running:
                BarcodePreview(session: camera.session)
                    .ignoresSafeArea(edges: .top)
            case .denied:
                cameraMessage(
                    emoji: "🔒",
                    title: "Accès caméra refusé",
                    message: "Autorise la caméra dans Réglages pour scanner tes codes-barres, ou saisis-les à la main."
                )
            case .noDevice:
                cameraMessage(
                    emoji: "📷",
                    title: "Aucune caméra détectée",
                    message: "Tu peux saisir un code-barres ou utiliser les produits de démonstration ci-dessous."
                )
            case .failed:
                cameraMessage(
                    emoji: "⚠️",
                    title: "Caméra indisponible",
                    message: "Réessaie plus tard, ou ajoute tes produits manuellement."
                )
            case .idle:
                ProgressView().tint(.white)
            }

            VStack {
                topBar
                Spacer()
                if camera.state == .running { scanFrame }
                Spacer()
                statusStrip
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 54)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .background(Theme.ink)
        .clipped()
    }

    private func cameraMessage(emoji: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Text(emoji).font(.system(size: 36))
            Text(title)
                .font(Theme.title(18))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    private var topBar: some View {
        HStack {
            Button {
                camera.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.18), in: .circle)
            }
            .accessibilityLabel("Fermer")

            Spacer()

            Text("Scanner mes courses")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                showsManualEntry = true
                Haptics.light()
            } label: {
                Image(systemName: "keyboard")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.18), in: .circle)
            }
            .accessibilityLabel("Saisir un code-barres")
        }
    }

    private var scanFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.85), lineWidth: 2.5)
                .frame(width: 260, height: 150)
            RoundedRectangle(cornerRadius: 22)
                .fill(.white.opacity(0.06))
                .frame(width: 260, height: 150)
            ScanLine()
        }
    }

    private var statusStrip: some View {
        Group {
            switch lookup {
            case .searching(let code):
                HStack(spacing: 10) {
                    ProgressView().tint(.white).scaleEffect(0.8)
                    Text("Recherche du produit \(code.suffix(6))…")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16).padding(.vertical, 11)
                .background(.black.opacity(0.4), in: .capsule)
            case .failed(let message):
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 11)
                    .background(Theme.clay.opacity(0.9), in: .capsule)
            case .idle:
                if let entry = lastAdded {
                    HStack(spacing: 10) {
                        Text("✅").font(.system(size: 15))
                        Text(entry.product.displayTitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 11)
                    .background(Theme.sageDeep.opacity(0.92), in: .capsule)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Vise un code-barres, il s'ajoute tout seul")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .background(.black.opacity(0.35), in: .capsule)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: lookup)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: lastAdded?.id)
    }

    // MARK: Bottom panel

    private var scanPanel: some View {
        VStack(spacing: 0) {
            if let duplicate {
                duplicateCard(duplicate)
                    .padding(.horizontal, Theme.hMargin)
                    .padding(.top, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            counterHeader

            if entries.isEmpty {
                demoSection
            } else {
                scannedList
            }

            finishButton
        }
        .frame(maxWidth: .infinity)
        .background(Theme.cream)
        .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: duplicate?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: entries.count)
    }

    private var counterHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(entries.count)")
                        .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                    Text("produit\(entries.count > 1 ? "s" : "") ajouté\(entries.count > 1 ? "s" : "")")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                if total > 0 {
                    Text("Courses enregistrées : \(Format.euro(total)) — estimation")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)
                }
            }
            Spacer()
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private var scannedList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(entries.reversed()) { entry in
                    Button {
                        editingEntry = entry
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            ProductThumb(product: entry.product, size: 44, radius: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.product.displayTitle)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                HStack(spacing: 5) {
                                    Text("\(Format.quantity(entry.quantity)) × \(entry.product.unit)")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(Theme.inkSoft)
                                    Text("• \(entry.location.emoji)")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(Theme.inkSoft)
                                    if entry.bestBefore == nil {
                                        Text("• sans date")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Theme.terracotta)
                                    }
                                }
                            }
                            Spacer(minLength: 0)
                            ScoreChip(value: entry.product.score.value, tone: entry.product.score.tone)
                        }
                        .padding(10)
                        .background(Theme.surface, in: .rect(cornerRadius: 16))
                        .contentShape(.rect)
                    }
                    .buttonStyle(SoftPressStyle())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 210)
    }

    private var demoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pas de code-barres sous la main ? Essaie :")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(DemoCatalogue.all.prefix(8)) { product in
                        Button {
                            handle(code: product.barcode)
                        } label: {
                            HStack(spacing: 6) {
                                Text(product.emoji)
                                Text(product.name)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 10)
                            .background(Theme.surface, in: .capsule)
                        }
                        .buttonStyle(SoftPressStyle())
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, Theme.hMargin)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Theme.hMargin)
        .padding(.bottom, 10)
    }

    private func duplicateCard(_ candidate: DuplicateCandidate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("⚠️").font(.system(size: 17))
                Text("Tu en as déjà")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(candidate.existing.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Tu as déjà \(candidate.existing.stockLine) dans \(candidate.existing.location.title.lowercased()).")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button("Ne pas ajouter") {
                    withAnimation { duplicate = nil }
                    Haptics.light()
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.creamDeep, in: .capsule)

                Button("Ajouter quand même") {
                    append(product: candidate.product)
                    withAnimation { duplicate = nil }
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.sage, in: .capsule)
            }
        }
        .padding(16)
        .background(Theme.terracotta.opacity(0.14), in: .rect(cornerRadius: Theme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.terracotta.opacity(0.5), lineWidth: 1.2)
        }
    }

    private var finishButton: some View {
        VStack(spacing: 8) {
            Button {
                Haptics.soft()
                camera.stop()
                withAnimation { stage = .review }
            } label: {
                Text(entries.isEmpty ? "Fermer" : "Terminer mes courses")
            }
            .buttonStyle(SaveatButtonStyle(tint: entries.isEmpty ? Theme.inkSoft : Theme.sage))
            .disabled(false)

            Text("Chaque produit rejoint automatiquement ton stock.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.hMargin)
        .padding(.top, 6)
        .padding(.bottom, 22)
    }

    // MARK: - Review stage

    private var reviewStage: some View {
        GroceryReviewView(
            entries: $entries,
            onBack: {
                withAnimation { stage = .scanning }
                Task { await camera.start() }
            },
            onConfirm: {
                store.finishGroceryRun(entries.map { $0.toFoodItem() })
                Haptics.success()
                dismiss()
            },
            onCancel: { dismiss() }
        )
    }

    // MARK: - Scan handling

    private func handle(code: String) {
        guard duplicate == nil else { return }

        // Free tier: a daily scan allowance, then the paywall — nothing already
        // scanned in this session is ever lost.
        guard subscriptions.canScan else {
            Haptics.warning()
            showsPaywall = true
            return
        }

        lookup = .searching(code)

        Task {
            let result = await OpenFoodFactsService.shared.product(barcode: code)
            switch result {
            case .success(let product):
                lookup = .idle
                if let existing = store.existingItem(for: product) ?? existingInSession(product) {
                    Haptics.warning()
                    withAnimation { duplicate = DuplicateCandidate(product: product, existing: existing) }
                } else {
                    append(product: product)
                }
            case .failure(let error):
                Haptics.warning()
                lookup = .failed(error.localizedDescription)
                try? await Task.sleep(for: .seconds(2.5))
                if case .failed = lookup { lookup = .idle }
            }
        }
    }

    private func existingInSession(_ product: ScannedProduct) -> FoodItem? {
        guard let entry = entries.first(where: { $0.product.barcode == product.barcode }) else { return nil }
        return entry.toFoodItem()
    }

    private func append(product: ScannedProduct) {
        subscriptions.registerScan()
        let bestBefore = product.defaultShelfLifeDays.flatMap {
            Calendar.current.date(byAdding: .day, value: $0, to: .now)
        }
        let entry = ScanEntry(
            product: product,
            quantity: 1,
            bestBefore: bestBefore,
            location: product.suggestedLocation
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            entries.append(entry)
            lastAdded = entry
        }
        Haptics.rigid()

        Task {
            try? await Task.sleep(for: .seconds(2))
            if lastAdded?.id == entry.id {
                withAnimation { lastAdded = nil }
            }
        }
    }
}

/// Thin animated laser sweeping the scan frame.
private struct ScanLine: View {
    @State private var offset: CGFloat = -60

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(colors: [.clear, Theme.sage, .clear],
                               startPoint: .leading, endPoint: .trailing)
            )
            .frame(width: 236, height: 3)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    offset = 60
                }
            }
    }
}
