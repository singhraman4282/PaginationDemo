//
//  ViewController.swift
//  PaginationDemo
//
//  Created by Raman Singh on 2023-02-10.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func mvcPressed(_ sender: UIButton) {
        navigationController?.pushViewController(MVCViewController(), animated: true)
    }
    
    @IBAction func mvvmPressed(_ sender: UIButton) {
        navigationController?.pushViewController(MVVMViewController(), animated: true)
    }

}

