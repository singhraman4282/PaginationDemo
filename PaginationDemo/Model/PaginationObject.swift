//
//  PaginationObject.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-10.
//

import Foundation

// MARK: - Domain

struct PaginationObject<T: Decodable>: Decodable {
    let items: [T]
    let currentPage: Int
    let totalPages: Int
    
    var didReachEndOfPagination: Bool {
        currentPage == totalPages
    }
}

// MARK: - Data

/// DTO - Data Transfer Object
struct PaginationResponseDTO: Decodable {
    let items: [String]
    let currentPage: Int
    let totalPages: Int
}

extension PaginationResponseDTO {
    
    var toDomain: PaginationObject<String> {
        .init(items: items, currentPage: currentPage, totalPages: totalPages)
    }
    
}
