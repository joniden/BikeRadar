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
    @State private var searchText = ""
    @State private var selectedCity: String? = nil
    @State private var networks: [Network] = []
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Find bikes in...")
                    .font(.title)
                    .foregroundStyle(Color.primary)
                    .padding(.top, 32)
                
                SearchTextField(searchText: $searchText)
                
                ScrollView {
                    if dataService.networks.isEmpty {
                        Text("Loading...")
                            .foregroundStyle(Color.secondary)
                            .padding()
                    } else {
                        if let selectedCity {
                            // Show list of networks for selected city
                            NetworksListView(dataService: dataService, selectedCity: selectedCity)
                        } else {
                            // Show list of cities
                            CitiesListView(dataService: dataService, searchText: $searchText, selectedCity: $selectedCity)
                        }
                    }
                }
            }
            .padding()
            .background(alignment: .center, content: {
                BackgroundImageView()
            })
            .task {
                do {
                    try await dataService.fetchData()
                    print("networks found: \(dataService.networks.count)")
                } catch {
                    // handle error
                    print("Failed to fetch data: \(error)")
                }
            }
            .onDisappear {
                resetValues()
            }
        }
    }
    
    private func resetValues() {
        // Reset search-related variables
        searchText = ""
        selectedCity = nil
        networks = []
    }
}

#Preview {
    ContentView()
}

struct NetworksListView: View {
    @ObservedObject var dataService: LocationsDataService
    let selectedCity: String
    
    var body: some View {
        ForEach(networksForCity(selectedCity)) { network in
            NavigationLink(destination: MapView(dataService: dataService, network: network)) {
                HStack {
                    Text(network.name ?? "No name network")
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
    }
    
    private func networksForCity(_ city: String) -> [Network] {
        print("Filtering networks for \(city)")
        return dataService.networks.filter { network in
            return network.location?.city.lowercased() == city.lowercased()
        }
    }
}

struct CitiesListView: View {
    @ObservedObject var dataService: LocationsDataService
    @Binding var searchText: String
    @Binding var selectedCity: String?
    
    var body: some View {
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
        }
    }
    
    private var filteredCities: [String] {
        return dataService.networks
            .compactMap { $0.location?.city }
            .filter {
                $0.lowercased().contains(searchText.lowercased())
            }
    }
}

struct BackgroundImageView: View {
    let imageNames = ["tiffany", "westend", "fixie"]
    @State private var imageName: String?
    
    var body: some View {
        GeometryReader { geometry in
            Image(imageName ?? "fixie")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width)
                .ignoresSafeArea()
                .overlay {
                    Color.white.opacity(0.3)
                        .ignoresSafeArea()
                }
                .onAppear {
                    imageName = imageNames.randomElement()
                }
        }
    }
}

struct SearchTextField: View {
    @Binding var searchText: String
    @State private var textInput: String = ""
    let textInputPublisher = PassthroughSubject<String, Never>()
    
    var body: some View {
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
            .onDisappear {
                textInput = ""
            }
    }
}
