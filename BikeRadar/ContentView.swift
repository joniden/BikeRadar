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
    let imageNames = ["tiffany", "westend", "fixie"]
    @State var image: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Find bikes in...")
                    .font(.title)
                    .foregroundStyle(Color.primary)
                    .padding(.top, 32)
                
                TextField("Type a city", text: $textInput)
                    .font(.title)
                    .padding()
                    .foregroundColor(.primary)
                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.secondary.opacity(0.2)))
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
                        Text("Loading...")
                            .foregroundStyle(Color.secondary)
                            .padding()
                    } else {
                        if let selectedCity {
                            // Show list of networks for selected city
                            ForEach(networks) { network in
                                NavigationLink(destination: MapView(dataService: dataService, network: network)) {
                                    HStack {
                                        Text(network.name ?? "test")
                                            .font(.title2)
                                            .foregroundStyle(Color.primary)
                                            .multilineTextAlignment(.leading)
                                            .padding(4)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Color.primary)
                                    }
                                }
                            }
                            Spacer()
                        } else {
                            // Show list of cities
                            LazyVStack(alignment: .leading) {
                                ForEach(filteredCities, id: \.self) { city in
                                    Button {
                                        selectedCity = city
                                    } label: {
                                        HStack {
                                            Text(city)
                                                .font(.title2)
                                                .foregroundStyle(Color.primary)
                                                .multilineTextAlignment(.leading)
                                                .padding(4)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(Color.primary)
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .onChange(of: selectedCity) {
                    if let selectedCity {
                        networks = networksForCity(selectedCity)
                    } else {
                        networks = []
                    }
                }
            }
            .padding()
            .background(alignment: .center, content: {
                GeometryReader { geometry in
                    Image(image ?? "fixie")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width)
                        .ignoresSafeArea()
                        .overlay {
                            Color.white.opacity(0.3)
                                .ignoresSafeArea()
                        }
                }
            })
            .task {
                do {
                    image = imageNames.randomElement() ?? "tiffany"
                    try await dataService.fetchData()
                    print("networks found: \(dataService.networks.count)")
                } catch {
                    // handle error
                    print("Failed to fetch data: \(error)")
                }
            }
            .onDisappear {
                // Reset search-related variables
                searchText = ""
                textInput = ""
                selectedCity = nil
                networks = []
            }
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
