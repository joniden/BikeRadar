//
//  MapView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-23.
//

import SwiftUI
import MapKit

/*extension CLLocationCoordinate2D {
    static let parking = CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369)
}*/

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
    @State private var route: MKRoute?
    @State private var selectedStation: Station?
    @State private var selectedCity: MKCoordinateRegion?
    @State var network: Network
    
    var body: some View {
        Map(position: $position) {
            ForEach(dataService.stations) { station in
                Annotation("Bike station", coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: "mappin.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .onTapGesture {
                            getDirections(station: station)
                            selectedStation = station
                        }
                }
            }
            //  .annotationTitles(.hidden)
            
            if let route {
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 5)
            }
            
            UserAnnotation()
        }
        .onAppear {
            if let city = network.location {
                selectedCity = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            }
            if let selectedCity {
                position = .region(selectedCity)
            }
           // print("dataservice stations count \(dataService.stations[0])")
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            if let selectedStation {
                ItemInfoView(selectedStation: selectedStation)
            }
        }
        .onChange(of: dataService.stations) {
            position = .automatic
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
    
    func getDirections(station: Station) {
        route = nil
        
        let location = locationsHandler.manager.location
        guard let coordinate = location?.coordinate else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.destination = MKMapItem(placemark: .init(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)))
        
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            withAnimation {
                route = response?.routes.first
            }
        }
    }
}

/*#Preview {
 MapView()
 }*/

/*struct MapButtons: View {
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
}*/
