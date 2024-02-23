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
}

struct Network: Identifiable, Codable {
    let company: [String]
    let href: String
    let location: Location
    let name: String
    let id: String
}

struct Location: Codable {
    let latitude: Double
    let city: String
    let longitude: Double
    let country: String
}

enum NetworkError: Error {
    case invalidURL
    case invalidData
    case decodingError(Error)
}
