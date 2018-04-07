//
//  ViewController.swift
//  DifferenceAlgorithmComparison
//
//  Created by 堀田 有哉 on 2018/01/18.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//

import UIKit
import RxDataSources

enum HogeError: Error {
    case hoge
}

struct MySection {
    var header: String
    var items: [Item]
}

extension MySection : AnimatableSectionModelType {
    typealias Item = Int
    
    var identity: String {
        return header
    }
    
    init(original: MySection, items: [Item]) {
        self = original
        self.items = items
    }
}

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        //calculate()
        //doTest()
        
        let section1 = [MySection(header: "", items: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])]
        let section2 = [MySection(header: "", items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0])]
        let diff = try! Diff.differencesForSectionedView(initialSections: section2, finalSections: section1)
        print("D Count", diff.first!.deletedItems.count)
        print("I Count", diff.first!.insertedItems.count)
        print("M Count", diff.first!.movedItems.count)
        print("U Count", diff.first!.updatedItems.count)
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
        //let listA: [Int] = [1, 2, 3, 4, 5, 6]
        //let listB: [Int] = [6, 1, 2, 3, 4, 5]
        //print(Heckel.diff(from: listA, to: listB))
        
        //let a = [1, 1, 3, 2, 5]
        //let b = [1, 6, 1, 3, 5]
        //print(originalHeckel.diff(from: a, to: b))
        
        //let a = [[1, 2], [3, 4]]
        //let b = [[1, 3], [2, 4]]
        
        let nestArray11 = [[1, 2, 5], []]
        let nestArray22 = [[], [1, 2, 5]]
        print(NestedHeckel.diff(from: nestArray11, to: nestArray22))
    }
    
    func doTest() {
        let patterns: [(from: [Int], to: [Int], expect: [Myers<Int>.Script])] = [
            // normal insert
            (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5, 6], expect: [.insert(from: 5, to: 4)]),
            // empty
            (from: [], to: [], expect: []),
            // delete to empty
            (from: [1], to: [], expect: [.delete(at: 0)]),
            // empty to insert
            (from: [], to: [1], expect: [.insert(from: 0, to: 0)]),
            // exchange
            (from: [0], to: [1], expect:[
                .delete(at: 0),
                .insert(from: 0, to: 0)
                ]
            ),
            // same sequence
            (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5], expect: []),
            // random, the other having several same symbols
            (from: [1, 2, 3, 4, 5], to: [2, 6, 4, 5, 6, 7], expect: [
                .delete(at: 0),
                .delete(at: 2),
                .insert(from: 1, to: 1),
                .insert(from: 4, to: 4),
                .insert(from: 5, to: 4)
                ]
            ),
            // random, both having several same symbols
            (from: [1, 1, 3, 2, 5], to: [1, 6, 1, 3, 5], expect: [
                .delete(at: 3),
                .insert(from: 1, to: 0)
                ]
            )]
        
        patterns.forEach { from, to, expext in
            //print(Myers.diff(from: from, to: to))
            //print(originalMyers.diff(from: from, to: to))
        }
        let k: [Int] = []
        //print(Myers.diff(from:k, to: k))
        
        //let a = [1, 2, 3, 4, 5]
        //let b = [1, 2, 3, 4, 5, 6]
        //let a = [0]
        //let b = [1]
        //let a = [1, 1, 3, 2, 5]
        //let b = [1, 6, 1, 3, 5]
        //let a = [1, 2]
        //let b = [1]
        let a = "1362"
        let b = "31526"
        //print(Myers.diff(from: a, to: b))
        print(Wu.diff(from: .init(a), to: .init(b)))
        //print(originalMyers.diff(from: [], to: []))
        //print(Myers.diff(from: .init("1362"), to: .init("31526")).reduce("") { $0 + $1.description })
        //print(originalMyers.diff(from: .init("kitten"), to: .init("sitting")))
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
