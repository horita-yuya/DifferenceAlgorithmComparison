//
//  HeckelTest.swift
//  DifferenceAlgorithmComparisonTests
//
//  Created by 堀田 有哉 on 2018/01/19.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//
@testable import DifferenceAlgorithmComparison

import Foundation
import Quick
import Nimble

final class HeckelSpec: QuickSpec {
    override func spec() {
        describe("diff") {
            it("normal") {
                let listA: [Int] = [10, 2, 3, 5, 5]
                let listB: [Int] = [1, 2, 7, 3, 5, 5, 6, 11, 12]
                
                let patterns: [(from: [Int], to: [Int], expect: [Difference<Int>])] = [
                    (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5, 6], expect: [.insert(element: 6, index: 5)]),
                    (from: [], to: [], expect: []),
                    (from: [1], to: [], expect: [.delete(element: 1, index: 0)]),
                    (from: [], to: [1], expect: [.insert(element: 1, index: 0)]),
                    (from: [0], to: [1], expect:[
                        .delete(element: 0, index: 0),
                        .insert(element: 1, index: 0)
                        ]
                    ),
                    (from: [1, 2, 3, 4, 5], to: [2, 6, 4, 5, 6, 7], expect: [
                        .delete(element: 1, index: 0),
                        .delete(element: 3, index: 2),
                        .insert(element: 6, index: 1),
                        .insert(element: 6, index: 4),
                        .insert(element: 7, index: 5)
                        ]
                    ),
                    (from: [1, 1, 3, 2, 5], to: [1, 6, 1, 3, 5], expect: [
                        .delete(element: 2, index: 3),
                        .insert(element: 6, index: 1)
                        ]
                    ),
                ]
                
                let pickDiffValues: (Difference<Int>) -> Int? = {
                    switch $0 {
                    case let .delete(element: element, index: index):
                        expect(element) == listA[index]
                        return element
                        
                    case let .insert(element: element, index: index):
                        expect(element) == listB[index]
                        return element
                        
                    case let .move(element: element, fromIndex: fromIndex, toIndex: toIndex):
                        expect(element) == listA[fromIndex]
                        expect(element) == listB[toIndex]
                        return nil
                    }
                }
                
                let diffElements = Heckel.diff(from: listA, to: listB).flatMap(pickDiffValues)
                expect(diffElements) == [10, 1, 7, 6, 11, 12]
                
                for pattern in patterns {
                    expect(Heckel.diff(from: pattern.from, to: pattern.to)) == pattern.expect
                }
            }
        }
    }
}
