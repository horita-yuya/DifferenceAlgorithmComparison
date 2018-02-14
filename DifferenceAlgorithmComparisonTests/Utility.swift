//
//  Utility.swift
//  DifferenceAlgorithmComparisonTests
//
//  Created by 堀田 有哉 on 2018/02/14.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//

import Foundation

func generate(count: Int, removeRange: Range<Int>? = nil, addRange: Range<Int>? = nil) -> (old: Array<String>, new: Array<String>) {
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
