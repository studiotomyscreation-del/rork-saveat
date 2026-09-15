import MapKit
import SwiftUI

extension GeoBoundingBox {
    /// Bridges a MapKit region into the MapKit-free box every provider talks in.
    init(region: MKCoordinateRegion) {
        self.init(
            minLatitude: region.center.latitude - region.span.latitudeDelta / 2,
            maxLatitude: region.center.latitude + region.span.latitudeDelta / 2,
            minLongitude: region.center.longitude - region.span.longitudeDelta / 2,
            maxLongitude: region.center.longitude + region.span.longitudeDelta / 2
        )
    }
}

/// The real SAVEAT Local map: live position (once authorized), markers from
/// `AntiWasteRepository`, category + radius filters, and a detail sheet.
///
/// The real "Carte" tab as of Phase 5 (Navigation V2, `RootView`). Fully
/// self-contained (own state, own data), so it also previews and can be
/// pushed from anywhere else in the app.
struct AntiWasteMapView: View {
    @State private var viewModel: AntiWasteMapViewModel
    @State private var camera = MapCameraPosition.region(
        MKCoordinateRegion(
            center: AntiWasteMapViewModel.franceFallbackCenter,
            span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
        )
    )
    @State private var showsFilters = false

    init(repository: AntiWasteRepository = .shared) {
        _viewModel = State(initialValue: AntiWasteMapViewModel(repository: repository))
    }

    var body: some View {
        ZStack(alignment: .top) {
            map

            VStack(spacing: 10) {
                if viewModel.locationManager.status != .authorized {
                    locationPrompt
                }
                filterSummaryBar
                if !viewModel.isLoading && viewModel.filteredPlaces.isEmpty {
                    noResultsBanner
                }
                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, Theme.hMargin)

            recenterButton
            osmAttribution
        }
        .background(SaveatColors.background.ignoresSafeArea())
        .navigationTitle(S.Map.title.s)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsFilters) {
            MapFiltersView(
                categories: viewModel.availableCategories,
                selectedCategory: $viewModel.selectedCategory,
                radiusKm: $viewModel.radiusKm,
                onDone: { showsFilters = false }
            )
        }
        .sheet(item: $viewModel.selectedPlace) { place in
            AntiWastePlaceDetailView(
                place: place,
                distanceText: viewModel.distanceText(to: place),
                isFavorite: viewModel.isFavorite(place),
                onToggleFavorite: { viewModel.toggleFavorite(place) }
            )
        }
        .task {
            await viewModel.load(in: GeoBoundingBox(region: initialRegion), force: true)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.scheduleLoad(in: GeoBoundingBox(region: context.region))
        }
        .onChange(of: viewModel.locationManager.updateCount) { _, _ in
            guard let location = viewModel.locationManager.userLocation else { return }
            withAnimation {
                camera = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    )
                )
            }
        }
    }

    private var initialRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: AntiWasteMapViewModel.franceFallbackCenter,
            span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
        )
    }

    private var map: some View {
        Map(position: $camera) {
            if viewModel.locationManager.status == .authorized {
                UserAnnotation()
            }
            ForEach(viewModel.filteredPlaces) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    Button {
                        Haptics.soft()
                        viewModel.selectedPlace = place
                    } label: {
                        ZStack {
                            Circle().fill(place.category.tint).frame(width: 32, height: 32)
                            Image(systemName: place.category.icon)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: SaveatColors.nightBlue.opacity(0.25), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var locationPrompt: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(SaveatColors.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text(S.Map.locationPromptTitle.s)
                    .font(SaveatTypography.headline(13.5))
                    .foregroundStyle(SaveatColors.textPrimary)
                Text(viewModel.locationManager.status == .denied
                     ? S.Map.locationDeniedNotice.s
                     : S.Map.locationPromptBody.s)
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(SaveatColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if viewModel.locationManager.status == .notDetermined {
                Button(S.Map.locationPromptButton.s) {
                    viewModel.locationManager.requestAuthorization()
                }
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(SaveatColors.brand, in: .capsule)
            }
        }
        .padding(12)
        .background(SaveatColors.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: SaveatColors.nightBlue.opacity(0.08), radius: 12, y: 4)
    }

    private var filterSummaryBar: some View {
        HStack(spacing: 8) {
            Button {
                showsFilters = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                    Text(S.Map.filtersButton.s)
                    if viewModel.selectedCategory != nil {
                        Circle().fill(SaveatColors.brand).frame(width: 6, height: 6)
                    }
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SaveatColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(SaveatColors.surface, in: .capsule)
                .shadow(color: SaveatColors.nightBlue.opacity(0.06), radius: 8, y: 3)
            }
            .buttonStyle(SoftPressStyle())

            Text("\(Int(viewModel.radiusKm)) km")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(SaveatColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(SaveatColors.surface, in: .capsule)

            Spacer(minLength: 0)
        }
    }

    private var noResultsBanner: some View {
        Text(S.Map.noResults.s)
            .font(SaveatTypography.caption(12.5))
            .foregroundStyle(SaveatColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(SaveatColors.surface, in: .capsule)
            .shadow(color: SaveatColors.nightBlue.opacity(0.06), radius: 8, y: 3)
    }

    /// Required by OpenStreetMap's ODbL license whenever OSM data is shown —
    /// kept visible at all times, not tucked away in a settings screen.
    private var osmAttribution: some View {
        VStack {
            Spacer()
            HStack {
                Link(destination: URL(string: "https://www.openstreetmap.org/copyright")!) {
                    Text(S.Map.osmAttribution.s)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(SaveatColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SaveatColors.surface.opacity(0.85), in: .capsule)
                }
                Spacer()
            }
            .padding(.leading, Theme.hMargin)
            .padding(.bottom, 8)
        }
    }

    private var recenterButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    guard let location = viewModel.locationManager.userLocation else { return }
                    Haptics.light()
                    withAnimation {
                        camera = .region(
                            MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                            )
                        )
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SaveatColors.forestDeep)
                        .frame(width: 44, height: 44)
                        .background(SaveatColors.surface, in: .circle)
                        .shadow(color: SaveatColors.nightBlue.opacity(0.15), radius: 8, y: 3)
                }
                .buttonStyle(SoftPressStyle())
                .opacity(viewModel.locationManager.userLocation == nil ? 0.4 : 1)
                .disabled(viewModel.locationManager.userLocation == nil)
                .accessibilityLabel(S.Map.recenterAccessibility.s)
                .padding(.trailing, Theme.hMargin)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AntiWasteMapView(repository: .preview)
    }
}
