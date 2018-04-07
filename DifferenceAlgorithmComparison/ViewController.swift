//
//  ViewController.swift
//  DifferenceAlgorithmComparison
//
//  Created by Yuya Horita on 2018/01/18.
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
        let a = [1, 2, 3, 4, 5]
        let b = [1, 2, 3, 4, 5, 6]
        print(Heckel.diff(from: a, to: b))
        
        let n1 = [[1, 2, 5], []]
        let n2 = [[], [1, 2, 5]]
        print(NestedHeckel.diff(from: n1, to: n2))
    }
}
