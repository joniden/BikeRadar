//
//  ContentView.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-23.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @StateObject private var dataService = LocationsDataService()
    @State private var textInput: String = ""
    let textInputPublisher = PassthroughSubject<String, Never>()
    @State private var searchText = ""
    @State private var selectedCity: String? = nil
    @State private var networks: [Network] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search for your city", text: $textInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: textInput) {
                        textInputPublisher.send(textInput)
                    }
                    .onReceive(textInputPublisher
                        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                        .removeDuplicates()
                    ) { debouncedTextInput in
                        searchText = debouncedTextInput
                    }
                ScrollView {
                    if dataService.networks.isEmpty {
                        Text("Loading data...")
                    } else {
                        if let selectedCity {
                            // Show list of networks for selected city
                            if networks.count > 0 {
                                ForEach(networks) { network in
                                   
                                    NavigationLink(destination: MapView(dataService: dataService, network: network)) {
                                        Text(network.name ?? "test")
                                    }
                                }
                            }
                            Spacer()
                        } else {
                            // Show list of cities
                            LazyVStack {
                                ForEach(filteredCities, id: \.self) { city in
                                    Button {
                                        selectedCity = city
                                    } label: {
                                        Text(city)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .onChange(of: selectedCity) {
                    if let selectedCity {
                        networks = networksForCity(selectedCity)
                    } else {
                        networks = []
                    }
                }
            }
        }
        .task {
            do {
                try await dataService.fetchData()
                print("networks: \(dataService.networks.count)")
            } catch {
                // handle error
                print("Failed to fetch data: \(error)")
            }
        }
        .onChange(of: selectedCity) {
            print("selectedCity \(selectedCity)")
        }
    }
    
    private var filteredCities: [String] {
        return dataService.networks
            .compactMap { $0.location?.city }
            .filter {
                $0.lowercased().contains(searchText.lowercased())
            }
    }
    
    private func networksForCity(_ city: String) -> [Network] {
        print("Fetching networks for \(city)")
        return dataService.networks.filter { network in
            return network.location?.city.lowercased() == city.lowercased()
        }
    }
}

#Preview {
    ContentView()
}


/*struct FancyLoadingView: View {
    @State private var rotationAngle: Double = 0.0
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    var body: some View {
        VStack {
            Image(systemName: "bicycle")
                .rotationEffect(Angle(degrees: rotationAngle))
                .foregroundColor(.blue)
                .font(.system(size: 50))
            
            Text("Loading data...")
                .font(.headline)
                .foregroundColor(.gray)
                .opacity(0.5)
                .padding(.top, 8)
        }
        .onAppear {
            withAnimation(animation) {
                rotationAngle += 360.0
            }
        }
    }
}*/

