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
        //calculate()
        //doTest()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doTest()
    }
}

private extension ViewController {
    func calculate() {
        //let fromArray = [1, 2, 3, 4, 5]
        //let toArray = [1, 2, 3, 4, 5, 6]
        //print(Heckel.diff(from: fromArray, to: toArray))
        
        //let listA: [Int] = [10, 2, 3, 5, 5]
        //let listB: [Int] = [1, 2, 7, 3, 5, 5, 6]
        let listA: [Int] = [1, 2, 3, 4, 5, 6]
        let listB: [Int] = [6, 1, 2, 3, 4, 5]
        print(Heckel.diff(from: listA, to: listB))
    }
    
    func doTest() {
        let (old, new) = generate(count: 2000, removeRange: 0..<100, addRange: 100..<150)
        benchmark(name: "Myers") {
            _ = Myers.diff(from: old, to: new)
        }
        
        benchmark(name: "CoolDiff") {
            _ = Heckel.diff(from: old, to: new)
        }
    }
    
    func benchmark(name: String ,closure: () -> Void) {
        let start = Date()
        closure()
        let end = Date()
        
        print("\(name): \(end.timeIntervalSince1970 - start.timeIntervalSince1970)s")
    }
    
    func generate(
        count: Int,
        removeRange: Range<Int>? = nil,
        addRange: Range<Int>? = nil)
        -> (old: Array<String>, new: Array<String>) {
            
            let old = Array(repeating: UUID().uuidString, count: count)
            var new = old
            
            if let removeRange = removeRange {
                new.removeSubrange(removeRange)
            }
            
            if let addRange = addRange {
                new.insert(
                    contentsOf: Array(repeating: UUID().uuidString, count: addRange.count),
                    at: addRange.lowerBound
                )
            }
            
            return (old: old, new: new)
    }
}
