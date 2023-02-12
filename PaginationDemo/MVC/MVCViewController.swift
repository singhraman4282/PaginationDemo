//
//  MVCViewController.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-10.
//

import Foundation
import UIKit

final class MVCViewController: UIViewController {
    
    // MARK: Properties
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private var items: [String] = []
    
    private let endpoint: String = "https://someurl.com"
    
    private var itemsPerPage: Int = 10
    
    private var currentPage: Int = 1
    
    private let networkClient: NetworkClient = DefaultNetworkClient()
    
    private let paginationUrlGenerator: PaginationUrlGenerator = DefaultPaginationUrlGenerator()
    
    private var isFetching: Bool = false
    
    private var didReachEndOfPagination: Bool = false
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    // MARK: Setup
    
    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        tableView.dataSource = self
    }
    
    private func fetchItems() {
        
        guard isFetching.isFalse && didReachEndOfPagination.isFalse else {
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
            case .failure:
                self?.isFetching.toggle()
                // TODO: Handle error here
                break
            }
        }
    }
    
    private func update(with paginationObject: PaginationObject<String>) {
        items.append(contentsOf: paginationObject.items)
        if currentPage < paginationObject.totalPages {
            currentPage += 1
        }
        
        didReachEndOfPagination = paginationObject.currentPage == paginationObject.totalPages
        tableView.reloadData()
    }
    
}

extension MVCViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let extra = didReachEndOfPagination.isFalse ? 1 : 0
        return items.count + extra
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == items.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as? LoadingCell else {
                preconditionFailure("This should never happen")
            }
            
            fetchItems()
            
            cell.startLoading()
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        
        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.text = items[indexPath.row]
        cell.contentConfiguration = contentConfiguration
        
        return cell
    }
    
}

extension Bool {
    var isFalse: Bool {
        self == false
    }
}
