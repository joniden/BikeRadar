//
//  LocationsDataService.swift
//  BikeRadar
//
//  Created by Joanne Yager on 2024-02-23.
//

import Foundation
import MapKit

class LocationsDataService: ObservableObject {
    @Published var networks: [Network] = []
    @Published var stations: [Station] = []
    
    func fetchData() async throws {
        guard let url = URL(string: "http://api.citybik.es/v2/networks") else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        
        do {
            let result = try decoder.decode([String: [Network]].self, from: data)
            if let networks = result["networks"] {
                DispatchQueue.main.async {
                    self.networks = networks
                }
            } else {
                throw NetworkError.invalidData
            }
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func fetchStations(networkId: String) async throws {
        let urlString = "http://api.citybik.es/v2/networks/" + networkId
        print("networkId: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let networkResponse = try decoder.decode(NetworkResponse.self, from: data)
            if let stations = networkResponse.network.stations {
                DispatchQueue.main.async {
                    self.stations = stations
                }
            } else {
                throw NetworkError.invalidData
            }
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

struct NetworkResponse: Decodable {
    let network: Network
}

struct Network: Identifiable, Decodable {
    let company: [String]?
    let href: String?
    let location: Location
    let name: String?
    let id: String
    let stations: [Station]?
}

struct Location: Codable {
    let latitude: Double
    let city: String
    let longitude: Double
    let country: String
}

struct Station: Identifiable, Decodable {
    let emptySlots: Int
    let extra: Extra?
    let freeBikes: Int
    let id: String
    let latitude: Double
    let longitude: Double
    let name: String?
    let timestamp: String
}

struct Extra: Decodable {
    let address: String
    let status: String
    let uid: Int
}

enum NetworkError: Error {
    case invalidURL
    case invalidData
    case decodingError(Error)
    case networkError(Error)
}
