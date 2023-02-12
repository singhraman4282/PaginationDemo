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
    var title: String { get }
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
    
    let title: String
    
    private (set) var shouldShowLoadingCell: Bool = true
    
    var items: AnyPublisher<[String], Never> {
        itemsSubject.eraseToAnyPublisher()
    }
    
    // MARK: MVVMViewModel
    
    var input: MVVMViewModelInput { self }
    var output: MVVMViewModelOutput { self }
    
    // MARK: Private properties
    
    private let itemsSubject: CurrentValueSubject<[String], Never> = CurrentValueSubject([])
    private let endpoint: String
    private let paginationUrlGenerator: PaginationUrlGenerator
    private let networkClient: NetworkClient
    
    private var itemsPerPage: Int
    private var currentPage: Int
    private var isFetching: Bool = false
     
    // MARK: Initialization
    
    init(endpoint: String = "someurl.com",
         itemsPerPage: Int = 10,
         currentPage: Int = 1,
         title: String = "MVVM",
         networkClient: NetworkClient = DefaultNetworkClient.mockingNetworkProtocol,
         paginationUrlGenerator: PaginationUrlGenerator = DefaultPaginationUrlGenerator()) {
        
        self.endpoint = endpoint
        self.itemsPerPage = itemsPerPage
        self.currentPage = currentPage
        self.title = title
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
        
        shouldShowLoadingCell = paginationObject.didReachEndOfPagination.isFalse
        itemsSubject.send(items)
    }
    
}
