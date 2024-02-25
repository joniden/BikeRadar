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
    @State private var showRoute = false
    @State private var selectedStation: Station?
    @State private var selectedCity: MKCoordinateRegion?
    @State var network: Network
    
    var body: some View {
        Map(position: $position) {
            ForEach(dataService.stations) { station in
                Annotation(station.name ?? "\(network.name ?? "Bike") Station", coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: "mappin.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .onTapGesture {
                            selectedStation = station
                        }
                }
            }
            //  .annotationTitles(.hidden)
            
            if let route {
                if showRoute {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            
            UserAnnotation()
        }
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
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            if let selectedStation {
                ItemInfoView(route: $route, showRoute: $showRoute, selectedStation: selectedStation)
            }
        }
        .onChange(of: dataService.stations) {
            position = .automatic
        }
        /* .onChange(of: selectedStation, {
         
         })*/
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

/*#Preview {
 MapView()
 }*/
