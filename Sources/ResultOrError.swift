//
//  ResultOrError.swift
//  PlaygroundsAreBusted
//
//  Created by David Ungar on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

// FIXME: rename to Result, use PromiseKit names

struct AlreadyHandledError: Error {}

public enum ResultOrError<SuccessResult> {
    case failure(Error)
    case success(SuccessResult)
    
    // Success consumer might fail:
    @discardableResult // avoid a warning if result is not used
    public func ifSuccess<NewSuccessResult>(_ fn: (SuccessResult) -> ResultOrError<NewSuccessResult>) -> ResultOrError<NewSuccessResult> {
        switch self {
            // Because compiler infers types
            // you don't have to say "return ResultOrError<NewSuccessResult>.failure(e)" below.
        case .failure(let e): return .failure(e)
        case .success(let r): return fn(r)
        }
    }
    
    // Success consumer always succeeds:
    @discardableResult // avoid a warning if result is not used
    public func ifSuccess<NewSuccessResult>( _ fn: (SuccessResult) -> NewSuccessResult )  -> ResultOrError<NewSuccessResult>  {
        switch self {
        case .failure(let e): return .failure(e)
        case .success(let r): return ResultOrError<NewSuccessResult>.success( fn(r) )
        }
    }
    
    @discardableResult // avoid a warning if result is not used
    public func ifFailure(_ fn: (Error) -> Void) -> ResultOrError {
        switch self {
        case .success: return self
        case .failure(let e):
            fn(e)
            return .failure(AlreadyHandledError())
        }
    }
}


