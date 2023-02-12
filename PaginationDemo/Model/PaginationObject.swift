//
//  PaginationObject.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-10.
//

import Foundation

// MARK: - Domain

struct PaginationObject<T: Decodable> {
    let items: [T]
    let currentPage: Int
    let totalPages: Int
    
    static func empty<T>() -> PaginationObject<T> {
        .init(items: [], currentPage: 1, totalPages: Int.max)
    }
}

// MARK: - Data

/// DTO - Data Transfer Object
struct PaginationResponseDTO: Codable {
    let items: [String]
    let currentPage: Int
    let totalPages: Int
}

extension PaginationResponseDTO {
    
    var toDomain: PaginationObject<String> {
        .init(items: items, currentPage: currentPage, totalPages: totalPages)
    }
    
}
