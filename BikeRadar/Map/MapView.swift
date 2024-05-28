//
//  MapView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-23.
//

import SwiftUI
import MapKit

struct MapView: View {
    // Here is a great place to use dependency injection or environment object
    @ObservedObject var dataService: LocationsDataService
    @ObservedObject var locationsHandler = LocationsHandler.shared
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    // Never changed
    @State private var route: MKRoute?
    // This is never changed
    @State private var showRoute = false
    @State private var selectedStation: Station?
    // Is this really used?
    @State private var selectedCity: MKCoordinateRegion?
    @State var network: Network
    @State private var showInfoView = false
    @State private var selectedTag: String?
    
    var body: some View {
        Map(position: $position, selection: $selectedTag) {
            ForEach(dataService.stations, id: \.id) { station in
                Marker(station.name ?? "\(network.name ?? "Bike") Station", coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude))
                    .tag(station.id)
            }

            // Can be rewritten as 
            /**
            if let route, showRoute {
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 5)
            }
            */
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
        .task {
            do {
                setupInitialMapView()
                try await dataService.fetchStations(networkId: network.id ?? "noId")
            } catch {
                // handle error
                print("Failed to fetch data: \(error)")
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            // Can be rewritten as
            /**
            if let selectedStation, showInfoView {
                InfoView(route: $route, showRoute: $showRoute, selectedStation: selectedStation, showInfoView: $showInfoView)
            }
            */
            if let selectedStation {
                if showInfoView {
                    InfoView(route: $route, showRoute: $showRoute, selectedStation: selectedStation, showInfoView: $showInfoView)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onChange(of: selectedTag) {
            updateSelectedStation()
        }
        .onChange(of: showRoute) {
            updatePositionForRoute()
        }
    }
    
    private func setupInitialMapView() {
        locationsHandler.requestATTPermission()

        /** 
        You can make it a bit clearer
        if let city = network.location {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: city.latitude, 
                    longitude: city.longitude
                ), 
                span: MKCoordinateSpan(
                    latitudeDelta: 0.1, 
                    longitudeDelta: 0.1
                )
            )
            position = .region(region)
        }
        */
        
        if let city = network.location {
            selectedCity = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        }
        if let selectedCity {
            position = .region(selectedCity)
        }
    }
    
    private func updateSelectedStation() {
        selectedStation = dataService.stations.first(where: { $0.id == selectedTag})
        showInfoView = true
        if let selectedStation {
            let selectedStationRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: selectedStation.latitude, longitude: selectedStation.longitude), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            position = .region(selectedStationRegion)
        }
    }
    
    private func updatePositionForRoute() {
        if let route {
            let routeRect = route.polyline.boundingMapRect
            let routeRegion = MKCoordinateRegion(routeRect)
            position = .region(routeRegion)
        }
    }
}

struct InfoView: View {
    @Binding var route: MKRoute?
    @Binding var showRoute: Bool
    var selectedStation: Station
    @State private var viewState = CGSize.zero
    @Binding var showInfoView: Bool
    
    var body: some View {
        ItemInfoView(route: $route, showRoute: $showRoute, selectedStation: selectedStation)
            .offset(x: 0, y: viewState.height)
            .gesture(
                DragGesture().onChanged { value in
                    handleDragGestureChanged(value)
                }
                    .onEnded { value in
                        handleDragGestureEnded(value)
                    }
            )
    }
    
    private func handleDragGestureChanged(_ value: DragGesture.Value) {
        if value.translation.height > viewState.height {
            viewState = value.translation
        }
    }
    
    private func handleDragGestureEnded(_ value: DragGesture.Value) {
        withAnimation(.spring()) {
            viewState = .zero
        }
        if value.translation.height > 80 {
            showInfoView = false
        }
    }
}
