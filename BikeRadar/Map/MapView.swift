//
//  MapView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-23.
//

import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var dataService: LocationsDataService
    @ObservedObject var locationsHandler = LocationsHandler.shared
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var route: MKRoute?
    @State private var showRoute = false
    @State private var selectedStation: Station?
    @State private var selectedCity: MKCoordinateRegion?
    @State var network: Network
    @State private var showInfoView = false
    @State var viewState = CGSize.zero
    @State private var selectedTag: String?
    
    var body: some View {
        Map(position: $position, selection: $selectedTag) {
            ForEach(dataService.stations, id: \.id) { station in
                Marker(station.name ?? "\(network.name ?? "Bike") Station", coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude))
                    .tag(station.id)
            }
            
            if let route {
                if showRoute {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            
            UserAnnotation()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            locationsHandler.requestATTPermission()
        }
        .onAppear {
            if let city = network.location {
                selectedCity = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            }
            if let selectedCity {
                position = .region(selectedCity)
            }
        }
        .task {
            do {
                try await dataService.fetchStations(networkId: network.id ?? "noId")
                print("stations: \(dataService.stations.count)")
            } catch {
                // handle error
                print("Failed to fetch data: \(error)")
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            if let selectedStation {
                if showInfoView {
                    ItemInfoView(route: $route, showRoute: $showRoute, selectedStation: selectedStation)
                        .offset(x: 0, y: viewState.height)
                        .gesture(
                            DragGesture().onChanged{ value in
                                if value.translation.height > viewState.height {
                                    viewState = value.translation
                                }
                            }
                                .onEnded { value in
                                    withAnimation(.spring()) {
                                        viewState = .zero
                                    }
                                    if value.translation.height > 80 {
                                        showInfoView = false
                                        
                                    }
                                }
                        )
                }
            }
        }
        .onChange(of: dataService.stations) {
            position = .automatic
        }
        .onChange(of: selectedTag) {
            selectedStation = dataService.stations.first(where: { $0.id == selectedTag})
            showInfoView = true
            if let selectedStation {
                let selectedStationRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: selectedStation.latitude, longitude: selectedStation.longitude), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                position = .region(selectedStationRegion)
            }
        }
        .onChange(of: showRoute) {
            if let route {
                let routeRect = route.polyline.boundingMapRect
                var routeRegion = MKCoordinateRegion(routeRect)
                position = .region(routeRegion)
            }
        }
        .onMapCameraChange { context in
            visibleRegion = context.region
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }
}
/*
#Preview {
    MapView()
}
*/