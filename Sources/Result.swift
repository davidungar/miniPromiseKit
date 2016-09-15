//
//  Result.swift
//  PlaygroundsAreBusted
//
//  Created by David Ungar on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation


// TODO: execute:

public enum Result<FulfilledResult> {
    case fulfilled(FulfilledResult)
    case rejected(Error)
    
    // Fulfilled consumer might fail:
    @discardableResult // avoid a warning if result is not used
    public func then<NewFulfilledResult>(execute body: (FulfilledResult) throws -> Result<NewFulfilledResult>) -> Result<NewFulfilledResult> {
        switch self {
            // Because compiler infers types
            // you don't have to say "return Result<NewFulfilledResult>.rejected(e)" below.
        case .rejected(let e): return .rejected(e)
        case .fulfilled(let r):
            do    { return try body(r) }
            catch { return .rejected( error ) }
        }
    }
    
    // Fulfilled consumer always succeeds:
    @discardableResult // avoid a warning if result is not used
    public func then<NewFulfilledResult>( execute body: (FulfilledResult) throws -> NewFulfilledResult )  -> Result<NewFulfilledResult>  {
        return then { try .fulfilled( body($0) ) }
    }
    
    @discardableResult // avoid a warning if result is not used
    public func `catch`( execute body: (Error) -> Void) -> Result {
        return recover {
            body($0)
            throw $0
         }
    }
    
    @discardableResult // avoid a warning if result is not used
    public func recover(execute body: (Error) throws -> FulfilledResult) -> Result {
        switch self {
        case .fulfilled: return self
        case .rejected(let e):
            do    { return try .fulfilled(body(e)) }
            catch { return .rejected(error)        }
        }
   }
    
    // Could add in all of the Promise protocol
    // The following is not needed for the book.
    // Why do the bodies not get to transform the result??
    
    public func tap( execute body: (Result) -> Void ) -> Result
    {
        body(self)
        return self
    }
    
    public func always( execute body: () -> Void ) -> Result {
        body()
        return self
    }


}


