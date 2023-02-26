//
//  NetworkClient.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-10.
//

import Foundation
import Combine

// MARK: - NetworkClient

protocol NetworkClient {
    
    func fetch<T: Decodable>(from url: URL) async throws -> T
    func fetch<T: Decodable>(from url: URL, completion: @escaping (Result<T, Error>) -> Void)
    
}

// MARK: - DefaultNetworkClient

struct DefaultNetworkClient: NetworkClient {
    
    enum NetworkError: LocalizedError {
        case noData
    }
    
    let urlSession: URLSession
    let decoder: JSONDecoder
    
    func fetch<T: Decodable>(from url: URL) async throws -> T {
        let data = try await urlSession.data(from: url).0
        return try decoder.decode(T.self, from: data)
    }
    
    func fetch<T>(from url: URL, completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        
        print("fetching from \(url)")
        
        urlSession.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let object = try decoder.decode(T.self, from: data)
                completion(.success(object))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
}

extension DefaultNetworkClient {
    
    static let mockingNetworkProtocol: NetworkClient = {
        URLProtocol.registerClass(MockURLProtocol.self)
        
        let configurationWithMock = URLSessionConfiguration.default
        configurationWithMock.protocolClasses?.insert(MockURLProtocol.self, at: 0)
        
        return DefaultNetworkClient(
            urlSession: URLSession(configuration: configurationWithMock),
            decoder: JSONDecoder())
    }()
    
}

// MARK: - MockURLProtocol

/// Note: - We can replace swagger with this. 💰💵
private final class MockURLProtocol: URLProtocol {
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        
        guard let url = request.url else {
            return
        }
        
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
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocol(self, didReceive: HTTPURLResponse(), cacheStoragePolicy: .allowed)
            case .failure(let error):
                self.client?.urlProtocol(self, didFailWithError: error)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {}
    
}

// MARK: - ItemsGenerator

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
        let delay = (5...20).map({ Double($0) }).randomElement().map( { $0 / 10.0 } ) ?? 0.5
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            completion(.success(data))
        }
    }
    
}
