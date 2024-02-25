//
//  ItemInfoView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-24.
//

import SwiftUI
import MapKit

struct ItemInfoView: View {
    @ObservedObject var locationsHandler = LocationsHandler.shared
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showLookAround = false
    @State private var route: MKRoute?
    
    var selectedStation: Station
    
    private var distance: String? {
        guard let route, route.distance >= 0 else { return nil }
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        let distanceMeasurement: Measurement<UnitLength>
        if route.distance >= 1000 {
            distanceMeasurement = Measurement(value: route.distance / 1000, unit: UnitLength.kilometers)
        } else {
            distanceMeasurement = Measurement(value: route.distance, unit: UnitLength.meters)
        }
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: distanceMeasurement)
    }
    
    private var travelTime: String? {
        guard let route else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: route.expectedTravelTime)
    }
    
    private var timestamp: String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .short
        
        if let date = inputFormatter.date(from: selectedStation.timestamp) {
            if Calendar.current.isDateInToday(date) {
                outputFormatter.dateStyle = .none
            }
            outputFormatter.locale = Locale(identifier: "en_GB")
            return outputFormatter.string(from: date)
        } else {
            return "Invalid Timestamp"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(selectedStation.name ?? "")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    showLookAround.toggle()
                } label: {
                    Image(systemName: showLookAround ? "info.circle" : "eye")
                        .foregroundColor(.accentColor)
                        .padding()
                        .frame(width: 44, height: 44)
                }
            }
            
            ZStack {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("Free bikes:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(selectedStation.freeBikes)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("Empty slots:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(selectedStation.emptySlots)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                    
                    HStack {
                        if let distance {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            Text("\(distance) away")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let travelTime {
                            Image(systemName: "figure.walk")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            Text("\(travelTime)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Last updated \(timestamp)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if let lookAroundScene {
                    LookAroundPreview(initialScene: lookAroundScene)
                        .frame(height: 128)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    //  .padding([.top, .horizontal])
                }
            }
        }
        
        
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .onChange(of: selectedStation) {
            getDirections(station: selectedStation)
        }
        .onChange(of: showLookAround) {
            if showLookAround {
                getLookAroundScene(station: selectedStation)
            } else {
                lookAroundScene = nil
            }
        }
    }
    
    func getLookAroundScene(station: Station) {
        lookAroundScene = nil
        Task {
            let request = MKLookAroundSceneRequest(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude))
            lookAroundScene = try? await request.scene
        }
    }
    
    func getDirections(station: Station) {
        route = nil
        
        let location = locationsHandler.manager.location
        guard let coordinate = location?.coordinate else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.destination = MKMapItem(placemark: .init(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)))
        request.transportType = .walking
        
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            withAnimation {
                route = response?.routes.first
            }
        }
    }
}

#Preview {
    ItemInfoView(selectedStation: Station(emptySlots: 14, freeBikes: 10, id: "87492ed48d78c573f95e99bc7f87ac9d", latitude: 55.60899, longitude: 12.99907, name: "Malmö C Norra", timestamp: "2024-02-25T08:34:42.895000Z"))
}
