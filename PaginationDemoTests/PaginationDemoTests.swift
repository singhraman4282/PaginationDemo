//
//  PaginationDemoTests.swift
//  PaginationDemoTests
//
//  Created by Raman Singh on 2023-02-10.
//

import XCTest
@testable import PaginationDemo

final class PaginationDemoTests: XCTestCase {
    
    private var queryProvider: SFCCPaginationQueryProvider!
    private let defaultPageSize: Int = 10
    
    func testShouldProvideInitialQueries() throws {
        
        guard setupTests() else {
            return
        }
        
        XCTAssertTrue(queryProvider.moreItemsAvailable(), "Should always return true initially")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 0, "Should always return 0")
        
        let queries = queryProvider.next()
        let start = try XCTUnwrap(getStartIndex(in: queries))
        let count = try XCTUnwrap(getItemsCount(in: queries))
        
        XCTAssertEqual(start, 0, "Should always start at index 0")
        XCTAssertEqual(count, defaultPageSize, "Should return the default page size set during installation")
    }
    
    func testShouldProvideCorrectQuerriesWhenNotInBeginning() throws {
        
        guard setupTests() else {
            return
        }
        
        XCTAssertTrue(queryProvider.moreItemsAvailable(), "Should always return true initially")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 0, "Should always return 0")
        
        queryProvider.handleDownloadedItems(count: 10, start: 0, total: 81)
        
        XCTAssertTrue(queryProvider.moreItemsAvailable(), "Should return true when more items are available")
        
        let queries = queryProvider.next()
        let start = try XCTUnwrap(getStartIndex(in: queries))
        let count = try XCTUnwrap(getItemsCount(in: queries))
        
        XCTAssertEqual(start, 10, "Should start at next index after successfully fetching previous query")
        XCTAssertEqual(count, defaultPageSize, "Should return the default page size set during installation")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 10, "Should always return correct count")
    }
    
    func testShouldProvideCorrectQuerriesWhenNearingEnd() throws {
        
        guard setupTests() else {
            return
        }
        
        XCTAssertTrue(queryProvider.moreItemsAvailable(), "Should always return true initially")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 0, "Should always return 0")
        
        queryProvider.handleDownloadedItems(count: 10, start: 65, total: 81)
        
        XCTAssertTrue(queryProvider.moreItemsAvailable(), "Should return true when more items are available")
        
        let queries = queryProvider.next()
        let start = try XCTUnwrap(getStartIndex(in: queries))
        let count = try XCTUnwrap(getItemsCount(in: queries))
        
        XCTAssertEqual(start, 75, "Should start at next index after successfully fetching previous query")
        XCTAssertEqual(count, 6, "Should return modified page size when remaining items count is below page size")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 75, "Should always return correct count")
    }
    
    func testShouldNotReturnAnyQueriesWhenReachedEnd() {
        
        guard setupTests() else {
            return
        }
        
        XCTAssertTrue(queryProvider.moreItemsAvailable(), "Should always return true initially")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 0, "Should always return 0")
        
        queryProvider.handleDownloadedItems(count: 6, start: 75, total: 81)
        
        XCTAssertFalse(queryProvider.moreItemsAvailable(), "Should return false when no more items are available")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 81, "Should always return correct count")
        
        let queries = queryProvider.next()
        XCTAssertTrue(queries.isEmpty, "Should not return any queries when reached end")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 81, "Should always return correct count")
    }
    
    
    func testSanityTest() throws {
        
        guard setupTests() else {
            return
        }
        
        XCTAssertTrue(queryProvider.moreItemsAvailable(), "Should always return true initially")
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 0, "Should always return 0")
        
        queryProvider = SFCCPaginationQueryProvider(pageSize: 31, startIndex: 0)
        
        var queries = queryProvider.next()
        var start = try XCTUnwrap(getStartIndex(in: queries))
        var count = try XCTUnwrap(getItemsCount(in: queries))
        
        XCTAssertTrue(queryProvider.moreItemsAvailable())
        XCTAssertEqual([start, count], [0, 31])
        
        queryProvider.handleDownloadedItems(count: 31, start: 0, total: 81)
        
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 31, "Should always return correct count")
        
        queries = queryProvider.next()
        start = try XCTUnwrap(getStartIndex(in: queries))
        count = try XCTUnwrap(getItemsCount(in: queries))
        
        XCTAssertTrue(queryProvider.moreItemsAvailable())
        XCTAssertEqual([start, count], [31, 31])
        
        queryProvider.handleDownloadedItems(count: 31, start: 31, total: 81)
        
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 62, "Should always return correct count")
        
        queries = queryProvider.next()
        start = try XCTUnwrap(getStartIndex(in: queries))
        count = try XCTUnwrap(getItemsCount(in: queries))
        
        XCTAssertTrue(queryProvider.moreItemsAvailable())
        XCTAssertEqual([start, count], [62, 19])
        
        queryProvider.handleDownloadedItems(count: 19, start: 62, total: 81)
        
        XCTAssertEqual(queryProvider.downloadedItemsCount(), 81, "Should always return correct count")
        
        queries = queryProvider.next()
        
        XCTAssertFalse(queryProvider.moreItemsAvailable())
        XCTAssertTrue(queries.isEmpty)
        
    }
    
    // MARK: - Helper Methods
    
    private func setupTests() -> Bool {
        queryProvider = SFCCPaginationQueryProvider(pageSize: defaultPageSize, startIndex: 0)
        return true
    }
    
    private func getStartIndex(in queries: [URLQueryItem]) -> Int? {
        queries.get(queryItemWithKey: "start")?.value.flatMap { Int($0) }
    }
    
    private func getItemsCount(in queries: [URLQueryItem]) -> Int? {
        queries.get(queryItemWithKey: "count")?.value.flatMap { Int($0) }
    }

}

final class SFCCPaginationQueryProvider {
    
    // MARK: Properties
    
    private var pageSize: Int
    private var startIndex: Int
    private var reachedEnd: Bool = false
    
    // MARK: Initialization
    
    init(pageSize: Int, startIndex: Int) {
        self.pageSize = pageSize
        self.startIndex = startIndex
    }
    
    func handleDownloadedItems(count: Int, start: Int, total: Int) {
        startIndex = start + count
        pageSize = min(total - startIndex, pageSize)
        reachedEnd = (total - start) == count
    }
    
    func moreItemsAvailable() -> Bool {
        reachedEnd.isFalse
    }
    
    func next() -> [URLQueryItem] {
        
        guard moreItemsAvailable() else {
            return []
        }
        
        return [
            URLQueryItem(name: "start", value: startIndex.description),
            URLQueryItem(name: "count", value: pageSize.description),
        ]
    }
    
    func downloadedItemsCount() -> Int {
        startIndex
    }
}

extension Array where Element == URLQueryItem {
    
    func get(queryItemWithKey key: String) -> URLQueryItem? {
        first(where: { $0.name == key })
    }
}
