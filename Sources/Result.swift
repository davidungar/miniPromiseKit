//
//  Result.swift
//  PlaygroundsAreBusted
//
//  Created by David Ungar on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation




public enum Result<FulfilledResult> {
    case fulfilled(FulfilledResult)
    case rejected(Error)
    
    // Fulfilled consumer might fail:
    @discardableResult // avoid a warning if result is not used
    public func ifFulfilled<NewFulfilledResult>(_ fn: (FulfilledResult) -> Result<NewFulfilledResult>) -> Result<NewFulfilledResult> {
        switch self {
            // Because compiler infers types
            // you don't have to say "return Result<NewFulfilledResult>.rejected(e)" below.
        case .rejected(let e): return .rejected(e)
        case .fulfilled(let r): return fn(r)
        }
    }
    
    // Fulfilled consumer always succeeds:
    @discardableResult // avoid a warning if result is not used
    public func ifFulfilled<NewFulfilledResult>( _ fn: (FulfilledResult) -> NewFulfilledResult )  -> Result<NewFulfilledResult>  {
        switch self {
        case .rejected(let e): return .rejected(e)
        case .fulfilled(let r): return Result<NewFulfilledResult>.fulfilled( fn(r) )
        }
    }
    
    @discardableResult // avoid a warning if result is not used
    public func ifRejected(_ fn: (Error) -> Void) -> Result {
        switch self {
        case .fulfilled: return self
        case .rejected(let e):
            fn(e)
            return .rejected(e)
        }
    }
}


