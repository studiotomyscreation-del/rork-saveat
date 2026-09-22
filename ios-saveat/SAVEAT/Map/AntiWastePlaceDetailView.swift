import MapKit
import SwiftUI

/// Full detail sheet for one SAVEAT Local place.
struct AntiWastePlaceDetailView: View {
    let place: AntiWastePlace
    let distanceText: String
    let isFavorite: Bool
    var onToggleFavorite: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let offerTitle = place.offerTitle {
                    offerCard(title: offerTitle)
                }

                infoCard

                actionRow

                attribution
            }
            .padding(Theme.hMargin)
            .padding(.bottom, 12)
        }
        .background(SaveatColors.background.ignoresSafeArea())
    }

    /// Source credit, required by OpenStreetMap's ODbL, by ADEME's Licence
    /// Ouverte, and by every open-data provider under Licence Ouverte 2.0
    /// (Etalab) whenever their data is shown (§ Étape 3). `place.license`
    /// carries the specific licence + publishing organisation per record
    /// (e.g. "Licence Ouverte 2.0 (Etalab) — Mulhouse Alsace Agglomération")
    /// — it used to be collected on the model but never actually rendered.
    private var attribution: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(S.Map.sourceLabel.f(place.source.attributionText))
                if let url = place.sourceURL {
                    Link(S.Map.sourceLink.s, destination: url)
                }
            }
            if let license = place.license, !license.isEmpty {
                Text(license)
            }
        }
        .font(.system(size: 10.5, weight: .medium, design: .rounded))
        .foregroundStyle(SaveatColors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                SaveatBadge(text: place.category.title, tone: .brand, icon: place.category.icon)
                if place.isTestData {
                    SaveatBadge(text: S.Map.testBadge.s, tone: .neutral)
                }
                Spacer(minLength: 0)
            }

            Text(place.name)
                .font(SaveatTypography.hero(24))
                .foregroundStyle(SaveatColors.textPrimary)

            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(distanceText)
            }
            .font(SaveatTypography.caption(13))
            .foregroundStyle(SaveatColors.brand)

            if !place.description.isEmpty {
                Text(place.description)
                    .font(SaveatTypography.body(14.5))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
        }
    }

    private func offerCard(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(S.Map.placeDetailOffer.s.uppercased())
                .font(SaveatTypography.eyebrow(10.5))
                .tracking(1)
                .foregroundStyle(SaveatColors.forestDeep.opacity(0.7))
            Text(title)
                .font(SaveatTypography.headline(16))
                .foregroundStyle(SaveatColors.forestDeep)
            if let detail = place.offerDescription, !detail.isEmpty {
                Text(detail)
                    .font(SaveatTypography.caption(13))
                    .foregroundStyle(SaveatColors.forestDeep.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SaveatColors.brandSoft, in: .rect(cornerRadius: Theme.cardRadius))
    }

    private var infoCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 14) {
                infoRow(icon: "mappin.and.ellipse", label: S.Map.placeDetailAddress.s, value: place.fullAddress)
                if let hours = place.openingHours {
                    infoRow(icon: "clock.fill", label: S.Map.placeDetailHours.s, value: hours)
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SaveatColors.brand)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(SaveatColors.textSecondary)
                Text(value)
                    .font(SaveatTypography.headline(14))
                    .foregroundStyle(SaveatColors.textPrimary)
            }
            Spacer(minLength: 0)
        }
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: openInMaps) {
                    actionLabel(icon: "arrow.triangle.turn.up.right.circle.fill", title: S.Map.placeDetailItinerary.s)
                }
                .buttonStyle(SoftPressStyle())

                Button(action: onToggleFavorite) {
                    actionLabel(
                        icon: isFavorite ? "heart.fill" : "heart",
                        title: isFavorite ? S.Map.placeDetailFavorited.s : S.Map.placeDetailFavorite.s,
                        tint: isFavorite ? SaveatColors.alert : SaveatColors.forestDeep
                    )
                }
                .buttonStyle(SoftPressStyle())
            }

            HStack(spacing: 10) {
                ShareLink(item: shareText) {
                    actionLabel(icon: "square.and.arrow.up", title: S.Map.placeDetailShare.s)
                }
                .buttonStyle(SoftPressStyle())

                if let url = place.websiteURL {
                    Link(destination: url) {
                        actionLabel(icon: "safari.fill", title: S.Map.placeDetailWebsite.s)
                    }
                    .buttonStyle(SoftPressStyle())
                }
            }
        }
    }

    private func actionLabel(icon: String, title: String, tint: Color = SaveatColors.forestDeep) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold))
            Text(title).font(.system(size: 11.5, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, minHeight: 62)
        .background(SaveatColors.surface, in: .rect(cornerRadius: 16))
    }

    private var shareText: String {
        String(format: S.Map.shareMessage.s, place.name, place.fullAddress)
    }

    private func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        item.name = place.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
}

#Preview {
    AntiWastePlaceDetailView(
        place: MockAntiWastePlacesService.all[0],
        distanceText: "1,2 km",
        isFavorite: false,
        onToggleFavorite: {}
    )
}
