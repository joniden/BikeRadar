//
//  ContentView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var dataService = LocationsDataService()
    @State private var city: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for your city", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Text("You entered: \(city)")
                
                VStack {
                    if dataService.networks.isEmpty {
                        Text("Loading data...")
                        Spacer()
                    } else {
                        List(dataService.networks) { network in
                            if city == network.location.city {
                                NavigationLink(destination: NetworkDetail(dataService: dataService, network: network)) {
                                    Text(network.name ?? "No network name")
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            do {
                try await dataService.fetchData()
                print("networks: \(dataService.networks.count)")
                print("networks id: \(dataService.networks[0].id)")
            } catch {
                // handle error
                print("Failed to fetch data: \(error)")
            }
        }
    }
}

struct NetworkDetail: View {
    @ObservedObject var dataService: LocationsDataService
    let network: Network

    var body: some View {
        VStack {
            Text("Name: \(network.name ?? "No name")")
                .padding()

            Text("Location: \(network.location.latitude), \(network.location.longitude)")
                .padding()

            Spacer()
            NavigationLink {
                MapView(dataService: dataService, network: network)
            } label: {
                Text("MapView")
            }

        }
        .navigationTitle(network.name ?? "No name")
        .task {
            do {
                try await dataService.fetchStations(networkId: network.id)
                print("stations: \(dataService.stations.count)")
                print("stations id: \(dataService.stations[0].id)")
            } catch {
                // handle error
                print("Failed to fetch data: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
