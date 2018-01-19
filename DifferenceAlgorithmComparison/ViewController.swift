//
//  ViewController.swift
//  DifferenceAlgorithmComparison
//
//  Created by 堀田 有哉 on 2018/01/18.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        calculate()
    }
}

private extension ViewController {
    func calculate() {
        //let fromArray = [1, 2, 3, 4, 5]
        //let toArray = [1, 2, 3, 4, 5, 6]
        //print(Heckel.diff(from: fromArray, to: toArray))
        
        let listA: [Int] = [10, 2, 3, 5, 5]
        let listB: [Int] = [1, 2, 7, 3, 5, 5, 6]
        print(Heckel.diff(from: listA, to: listB))
    }
}
