//
//  MVVMViewModel.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-10.
//

import Foundation
import Combine

// MARK: - MVVMViewModelOutput

protocol MVVMViewModelOutput {
    var items: AnyPublisher<[String], Never> { get }
    var shouldShowLoadingCell: Bool { get }
}

// MARK: - MVVMViewModelInput

protocol MVVMViewModelInput {
    func fetchItems()
}

// MARK: - MVVMViewModel

protocol MVVMViewModel {
    var input: MVVMViewModelInput { get }
    var output: MVVMViewModelOutput { get }
}

// MARK: - DefaultMVVMViewModel

final class DefaultMVVMViewModel: MVVMViewModel, MVVMViewModelInput, MVVMViewModelOutput {
    
    // MARK: MVVMViewModelOutput
    
    var items: AnyPublisher<[String], Never> {
        itemsSubject.eraseToAnyPublisher()
    }
    
    private (set) var shouldShowLoadingCell: Bool = true
    
    // MARK: MVVMViewModel
    
    var input: MVVMViewModelInput { self }
    var output: MVVMViewModelOutput { self }
    
    // MARK: Private properties
    
    private var itemsSubject: CurrentValueSubject<[String], Never> = CurrentValueSubject([])
    private let endpoint: String
    private var itemsPerPage: Int
    private var currentPage: Int
    private let networkClient: NetworkClient
    private var isFetching: Bool = false
    private let paginationUrlGenerator: PaginationUrlGenerator
    
    // MARK: Initialization
    
    init(endpoint: String = "https://someurl.com",
         itemsPerPage: Int = 10,
         currentPage: Int = 1,
         networkClient: NetworkClient = DefaultNetworkClient.mockingNetworkProtocol,
         paginationUrlGenerator: PaginationUrlGenerator = DefaultPaginationUrlGenerator()) {
        
        self.endpoint = endpoint
        self.itemsPerPage = itemsPerPage
        self.currentPage = currentPage
        self.networkClient = networkClient
        self.paginationUrlGenerator = paginationUrlGenerator
    }
    
    // MARK: MVVMViewModelOutput
    
    func fetchItems() {
        guard isFetching.isFalse && shouldShowLoadingCell else {
            return
        }
        
        isFetching.toggle()
        
        let url = paginationUrlGenerator.generateUrl(
            for: endpoint,
            itemsPerPage: itemsPerPage,
            pageNumber: currentPage)
        
        guard let url else {
            preconditionFailure("This should never happen")
        }
        
        networkClient.fetch(from: url) { [weak self] (result: Result<PaginationResponseDTO, Error>) in
            switch result {
            case .success(let dto):
                self?.isFetching.toggle()
                self?.update(with: dto.toDomain)
            case .failure(let error):
                self?.isFetching.toggle()
                // TODO: Handle error here
                print(error)
                break
            }
        }
    }
    
    private func update(with paginationObject: PaginationObject<String>) {
        var items = itemsSubject.value
        items.append(contentsOf: paginationObject.items)
        if currentPage < paginationObject.totalPages {
            currentPage += 1
        }
        
        shouldShowLoadingCell = paginationObject.currentPage != paginationObject.totalPages
        itemsSubject.send(items)
    }
    
}

protocol PaginationUrlGenerator {
    
    func generateUrl(for endpoint: String, itemsPerPage: Int, pageNumber: Int) -> URL?
    
}

struct DefaultPaginationUrlGenerator: PaginationUrlGenerator {
    
    func generateUrl(for endpoint: String, itemsPerPage: Int, pageNumber: Int) -> URL? {
        var components = URLComponents()
        components.host = endpoint
        components.queryItems = [
            .init(name: "count", value: itemsPerPage.description),
            .init(name: "page_number", value: pageNumber.description),
        ]
        
        return components.url
    }
}
