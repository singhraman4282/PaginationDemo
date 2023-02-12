//
//  PaginationUrlGenerator.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-11.
//

import Foundation

protocol PaginationUrlGenerator {
    func generateUrl(for endpoint: String, itemsPerPage: Int, pageNumber: Int) -> URL?
}

// MARK: - DefaultPaginationUrlGenerator

struct DefaultPaginationUrlGenerator: PaginationUrlGenerator {
    
    func generateUrl(for endpoint: String, itemsPerPage: Int, pageNumber: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = endpoint
        components.queryItems = [
            .init(name: "count", value: itemsPerPage.description),
            .init(name: "page_number", value: pageNumber.description),
        ]
        
        return components.url
    }
}
