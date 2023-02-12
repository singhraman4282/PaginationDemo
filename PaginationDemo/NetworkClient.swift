//
//  NetworkClient.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-10.
//

import Foundation
import Combine

protocol NetworkClient {
    
    func fetch<T: Decodable>(from url: URL) async throws -> T
    func fetch<T: Decodable>(from url: URL, completion: @escaping (Result<T, Error>) -> Void)
    
}

struct DefaultNetworkClient: NetworkClient {
    
    func fetch<T: Decodable>(from url: URL) async throws -> T {
        try await withCheckedThrowingContinuation { contination in
            fetch(from: url) { (result: Result<T, Error>) in
                switch result {
                case .success(let item):
                    contination.resume(returning: item)
                case .failure(let error):
                    contination.resume(throwing: error)
                }
            }
        }
    }
    
    func fetch<T>(from url: URL, completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        /// In real life, we'd be making an http request and parsing the response. But for our example, we're just passing the parameters to an `ItemGenerator`.
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        let count = queryItems
            .first(where: { $0.name == "count" })
            .flatMap { $0.value }
            .flatMap { Int($0) }
        
        let pageNumber = queryItems
            .first(where: { $0.name == "page_number" })
            .flatMap { $0.value }
            .flatMap { Int($0) }
        
        guard let count, let pageNumber else {
            preconditionFailure("Invalid URL")
        }
        
        ItemsGenerator.generateItems(count: count, pageNumber: pageNumber) { result in
            switch result {
            case .success(let data):
                do {
                    let dto = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(dto))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}


/// This is mocking what a server would typically send when we make a request
private struct ItemsGenerator {
    
    private struct MockServerResponse: Codable {
        let items: [String]
        let currentPage: Int
        let totalPages: Int
    }
    
    enum MockError: String, LocalizedError {
        case reachedEnd = "That's all folks"
        
        var errorDescription: String? {
            rawValue
        }
    }
    
    static func generateItems(count: Int, pageNumber: Int, completion: @escaping (Result<Data, Error>) -> Void) {
        
        guard pageNumber > 0 else {
            preconditionFailure("Typically the page number is a positive integer")
        }
        
        guard pageNumber <= 10 else {
            completion(.failure(MockError.reachedEnd))
            return
        }
        
        let startingPoint = (abs(pageNumber - 1) * count) + 1
        let endingPoint = startingPoint + count
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let response = MockServerResponse(
            items: (startingPoint..<endingPoint).map { "Item number: " + $0.description },
            currentPage: pageNumber,
            totalPages: 10)
        
        let data = (try? encoder.encode(response)) ?? Data()
        
        // Imitating delay in server response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(data))
        }
    }
    
}
