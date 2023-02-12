//
//  MVVMViewController.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-10.
//

import UIKit
import Combine

final class MVVMViewController: UIViewController {
    
    // MARK: Properties
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let viewModel: MVVMViewModel
    
    private var items: [String] = []
    
    private var subscriptions: Set<AnyCancellable> = []
    
    // MARK: Initialization
    
    init(viewModel: MVVMViewModel = DefaultMVVMViewModel()) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        subscribeToViewModel()
        
        title = viewModel.output.title
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
    
    // MARK: Binding
    
    private func subscribeToViewModel() {
        viewModel.output.items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.items = $0
                self?.tableView.reloadData()
            }
            .store(in: &subscriptions)
    }
    
}

extension MVVMViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let extra = viewModel.output.shouldShowLoadingCell ? 1 : 0
        return items.count + extra
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == items.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as? LoadingCell else {
                preconditionFailure("This should never happen")
            }
            
            viewModel.input.fetchItems()
            
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
