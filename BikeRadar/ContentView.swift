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
                                NavigationLink(destination: NetworkDetail(network: network)) {
                                    Text(network.name)
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
    let network: Network

    var body: some View {
        VStack {
            Text("Name: \(network.name)")
                .padding()

            Text("Location: \(network.location.latitude), \(network.location.longitude)")
                .padding()

            Spacer()
        }
        .navigationTitle(network.name)
    }
}

#Preview {
    ContentView()
}
