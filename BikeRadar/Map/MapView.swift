//
//  MapView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-23.
//

import SwiftUI
import MapKit

extension CLLocationCoordinate2D {
    static let parking = CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369)
}

extension MKCoordinateRegion {
    static let boston = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.360256, longitude: -71.057279), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    static let northShore = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.547408, longitude: -70.870085), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
}

struct MapView: View {
    @ObservedObject var dataService: LocationsDataService
    @ObservedObject var locationsHandler = LocationsHandler.shared
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchResults: [MKMapItem] = []
    @State private var stationResults: [Station] = []
    @State private var selectedResult: MKMapItem?
    @State private var route: MKRoute?
    @State private var selectedTag: Int?
    
    var body: some View {
        Map(position: $position, selection: $selectedTag) {
            
            ForEach(searchResults, id: \.self) { result in
                Marker(item: result)
            }
            .annotationTitles(.hidden)
            
            ForEach(dataService.stations) { station in
                Marker(station.name ?? "no name", coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude))
                  //  .tag(1)
            }
          //  .annotationTitles(.hidden)
            
            if let route {
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 5)
            }
            
            UserAnnotation()
        }
        .onAppear {
            print("dataservice stations count \(dataService.stations[0])")
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                
                VStack(spacing: 0) {
                    if let selectedResult {
                        ItemInfoView(selectedResult: selectedResult, route: route)
                            .frame(height: 128)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding([.top, .horizontal])
                    }
                    MapButtons(dataService: dataService, position: $position, searchResults: $searchResults, stationResults: $stationResults, visibleRegion: visibleRegion)
                        .padding(.top)
                }
                Spacer()
            }
            .background(.ultraThinMaterial)
        }
        .onChange(of: searchResults) {
            position = .automatic
        }
        .onChange(of: selectedResult) {
            getDirections()
        }
        .onMapCameraChange { context in
            visibleRegion = context.region
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            locationsHandler.requestATTPermission()
        }
    }
    
    func getDirections() {
        route = nil
        guard let selectedResult else { return }
        
        let location = locationsHandler.manager.location
        guard let coordinate = location?.coordinate else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.destination = selectedResult
        
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            route = response?.routes.first
        }
    }
}

/*#Preview {
    MapView()
}*/

struct MapButtons: View {
    @ObservedObject var dataService: LocationsDataService
    @Binding var position: MapCameraPosition
    @Binding var searchResults: [MKMapItem]
    @Binding var stationResults: [Station]
    
    var visibleRegion: MKCoordinateRegion?
    
    var body: some View {
        HStack {
            Button {
                search(for: "playground")
            } label: {
                Label("Playgrounds", systemImage: "figure.and.child.holdinghands")
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                search(for: "beach")
            } label: {
                Label("Beaches", systemImage: "beach.umbrella")
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                position = .region(.boston)
            } label: {
                Label("Boston", systemImage: "building.2")
            }
            .buttonStyle(.bordered)
            
            Button {
                position = .region(.northShore)
            } label: {
                Label("North Shore", systemImage: "water.waves")
            }
            .buttonStyle(.bordered)
            
            Button {
                addBikeSharingStations(dataService.stations)
                print("stationResults: \(stationResults)")

            } label: {
                Label("Bike Stations", systemImage: "bicycle")
            }
            .buttonStyle(.bordered)
        }
        .labelStyle(.iconOnly)
    }
    
    func addBikeSharingStations(_ stations: [Station]) {
        let request = MKLocalSearch.Request()
        request.region = visibleRegion ?? MKCoordinateRegion(
            center: .parking,
            span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)
        )
        
        var mapItems = [MKMapItem]()
        
        for station in stations {
            let coordinate = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
            let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
            
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = station.name
            mapItem.phoneNumber = String(station.freeBikes)
            mapItem.url = URL(string: "https://www.example.com")
            mapItems.append(mapItem)
        }
        Task {
            stationResults = stations
        }
    }
    
    func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = visibleRegion ?? MKCoordinateRegion(
            center: .parking,
            span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)
        )
        
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            searchResults = response?.mapItems ?? []
            print("searchResults: \(searchResults)")
        }
    }
}
