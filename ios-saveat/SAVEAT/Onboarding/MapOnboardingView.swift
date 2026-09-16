import MapKit
import SwiftUI

/// Sixth screen of the product-pitch onboarding: a preview of SAVEAT Local.
///
/// The map itself is genuine MapKit — a real `Map` with sample pins, not a
/// flattened image — kept prominent as this page's hero visual instead of a
/// food photo, since the map *is* the subject here. The search bar and
/// filter chips are static (they don't respond to taps) and the example
/// place card is fictional: no location permission is requested and no real
/// place data is shown. The real anti-waste map (`Map/AntiWasteMapView`, now
/// the app's own "Carte" tab) is a different, fully live screen; this one
/// only sets expectations for it during onboarding.
struct MapOnboardingView: View {
    var onContinue: () -> Void
    var onSkip: () -> Void

    @State private var camera = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        )
    )

    private struct PreviewPin {
        let icon: String
        let tint: Color
        let coordinate: CLLocationCoordinate2D
    }

    private let previewPins: [PreviewPin] = [
        PreviewPin(icon: "cart.fill", tint: SaveatColors.brand, coordinate: CLLocationCoordinate2D(latitude: 48.8606, longitude: 2.3376)),
        PreviewPin(icon: "heart.fill", tint: SaveatColors.alert, coordinate: CLLocationCoordinate2D(latitude: 48.8529, longitude: 2.3499)),
        PreviewPin(icon: "leaf.fill", tint: SaveatColors.brandLight, coordinate: CLLocationCoordinate2D(latitude: 48.8496, longitude: 2.3656)),
        PreviewPin(icon: "percent", tint: SaveatColors.promo, coordinate: CLLocationCoordinate2D(latitude: 48.8580, longitude: 2.3450))
    ]

    private let filters: [String] = [
        S.Intro.mapFilterAll.s,
        S.Intro.mapFilterBaskets.s,
        S.Intro.mapFilterAntiWaste.s,
        S.Intro.mapFilterFridges.s
    ]

    @State private var selectedFilter = 0

    var body: some View {
        IntroStepShell(
            photoAssetNames: [],
            stepIndex: 5,
            stepCount: 7,
            icon: "map.fill",
            title: S.Intro.mapTitle.s,
            body_: S.Intro.mapBody.s,
            ctaTitle: S.Intro.mapCTA.s,
            onContinue: onContinue,
            onSkip: onSkip
        ) {
            VStack(spacing: 10) {
                mapPreview
                searchBar
                filterChips
                exampleCard
                Text(S.Intro.mapPreviewNotice.s)
                    .font(SaveatTypography.caption(11))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, Theme.hMargin)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SaveatColors.textSecondary)
            Text(S.Intro.mapSearchPlaceholder.s)
                .font(SaveatTypography.caption(13))
                .foregroundStyle(SaveatColors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.white.opacity(0.92), in: .capsule)
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(Array(filters.enumerated()), id: \.offset) { index, label in
                Text(label)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(selectedFilter == index ? SaveatColors.textOnDark : SaveatColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        selectedFilter == index ? SaveatColors.brand : .white.opacity(0.92),
                        in: .capsule
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedFilter = index }
                    }
            }
            Spacer(minLength: 0)
        }
    }

    private var mapPreview: some View {
        Map(position: $camera, interactionModes: []) {
            ForEach(Array(previewPins.enumerated()), id: \.offset) { _, pin in
                Annotation("", coordinate: pin.coordinate) {
                    ZStack {
                        Circle().fill(pin.tint).frame(width: 30, height: 30)
                        Image(systemName: pin.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .frame(height: 210)
        .clipShape(.rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.5), lineWidth: 1.5)
        }
        .shadow(color: SaveatColors.nightBlue.opacity(0.35), radius: 20, x: 0, y: 10)
    }

    private var exampleCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(SaveatColors.brandSoft).frame(width: 40, height: 40)
                Image(systemName: "cart.fill").font(.system(size: 15)).foregroundStyle(SaveatColors.forestDeep)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Le Panier Solidaire")
                        .font(SaveatTypography.headline(13.5))
                        .foregroundStyle(SaveatColors.textPrimary)
                    SaveatBadge(text: S.Intro.mapExampleBadge.s, tone: .brand)
                }
                Text("1,2 km • 12 Rue des Écoles, Bordeaux")
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .saveatTranslucentCard(padding: 12, radius: 16)
    }
}

#Preview {
    MapOnboardingView(onContinue: {}, onSkip: {})
}
