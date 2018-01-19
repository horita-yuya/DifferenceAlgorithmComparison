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

class HeckelSpec: QuickSpec {
    override func spec() {
        describe("diff") {
            it("normal") {
                let listA: [Int] = [10, 2, 3, 5, 5]
                let listB: [Int] = [1, 2, 7, 3, 5, 5, 6]
                
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
                expect(diffElements) == [10, 1, 7, 6]
            }
        }
    }
}
