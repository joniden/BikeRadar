//
//  ItemInfoView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-24.
//

import SwiftUI
import MapKit

struct ItemInfoView: View {
    @State private var lookAroundScene: MKLookAroundScene?
    
    var selectedStation: Station
    var route: MKRoute?
    
    private var travelTime: String? {
        guard let route else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: route.expectedTravelTime)
    }
    
    var body: some View {
        VStack {
            Button {
                getLookAroundScene(station: selectedStation)
            } label: {
                Text("Look Around")
            }
            
            if let lookAroundScene {
                LookAroundPreview(initialScene: lookAroundScene)
                    .frame(height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding([.top, .horizontal])
            }
        }
        .onChange(of: selectedStation) {
            getLookAroundScene(station: selectedStation)
        }
    }
    
    func getLookAroundScene(station: Station) {
        lookAroundScene = nil
        Task {
            let request = MKLookAroundSceneRequest(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude))
            lookAroundScene = try? await request.scene
        }
    }
}
