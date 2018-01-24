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
                let patterns: [(from: [Int], to: [Int], expect: [Difference<Int>])] = [
                    // normal insert
                    (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5, 6], expect: [.insert(element: 6, index: 5)]),
                    // empty
                    (from: [], to: [], expect: []),
                    // delete to empty
                    (from: [1], to: [], expect: [.delete(element: 1, index: 0)]),
                    // empty to insert
                    (from: [], to: [1], expect: [.insert(element: 1, index: 0)]),
                    // exchange
                    (from: [0], to: [1], expect:[
                        .delete(element: 0, index: 0),
                        .insert(element: 1, index: 0)
                        ]
                    ),
                    // same sequence
                    (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5], expect: []),
                    // random, the other having several same symbols
                    (from: [1, 2, 3, 4, 5], to: [2, 6, 4, 5, 6, 7], expect: [
                        .delete(element: 1, index: 0),
                        .delete(element: 3, index: 2),
                        .insert(element: 6, index: 1),
                        .insert(element: 6, index: 4),
                        .insert(element: 7, index: 5)
                        ]
                    ),
                    // random, both having several same symbols
                    (from: [1, 1, 3, 2, 5], to: [1, 6, 1, 3, 5], expect: [
                        .delete(element: 2, index: 3),
                        .insert(element: 6, index: 1)
                        ]
                    ),
                    // random, the other having several same symbols
                    (from: [1, 7, 3, 2, 5], to: [1, 6, 1, 3, 5], expect: [
                        .delete(element: 7, index: 1),
                        .delete(element: 2, index: 3),
                        .insert(element: 6, index: 1),
                        .insert(element: 1, index: 2)
                        ]
                    ),
                    // random, move
                    (from: [11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], to: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 11, 11], expect: [
                        .insert(element: 11, index: 11),
                        .insert(element: 11, index: 12),
                        .move(element: 11, fromIndex: 0, toIndex: 10)
                        ]
                    ),
                    // move first to last
                    (from: [6, 1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5, 6], expect: [
                        .move(element: 6, fromIndex: 0, toIndex: 5)
                        ]
                    ),
                    // move last to first
                    (from: [1, 2, 3, 4, 5, 6], to: [6, 1, 2, 3, 4, 5], expect: [
                        .move(element: 6, fromIndex: 5, toIndex: 0)
                        ]
                    ),
                    // random,
                    (from: [1, 1, 3, 5, 2, 2, 6], to: [1, 2, 3, 5, 2, 1, 7, 5], expect: [
                        .delete(element: 6, index: 6),
                        .insert(element: 7, index: 6),
                        .insert(element: 5, index: 7),
                        .move(element: 2, fromIndex: 4, toIndex: 1),
                        .move(element: 1, fromIndex: 1, toIndex: 5)
                        ]
                    ),
                    // ascending and descending move
                    (from: [1, 2, 3, 4, 5, 11, 7, 8, 9], to: [10, 1, 2, 3, 4, 5, 6, 9, 8, 7], expect: [
                        .delete(element: 11, index: 5),
                        .insert(element: 10, index: 0),
                        .insert(element: 6, index: 6),
                        .move(element: 9, fromIndex: 8, toIndex: 7),
                        .move(element: 7, fromIndex: 6, toIndex: 9)
                        ]
                    )
                    /*  DEBUG NOW
                    (from: [1, 2, 3, 4, 5, 6, 7], to: [1, 2, 6, 7, 3, 4, 5], expect: [
                        .move(element: 3, fromIndex: 2, toIndex: 4),
                        .move(element: 4, fromIndex: 3, toIndex: 5),
                        .move(element: 5, fromIndex: 4, toIndex: 6)
                        ]
                    )*/
                ]
                
                for pattern in patterns {
                    expect(Heckel.diff(from: pattern.from, to: pattern.to)) == pattern.expect
                }
            }
        }
    }
}
