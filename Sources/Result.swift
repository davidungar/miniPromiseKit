//
//  Result.swift
//  PlaygroundsAreBusted
//
//  Created by David Ungar on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation


public enum Result<FulfilledValue> {
    case fulfilled(FulfilledValue)
    case rejected(Error)
    
    public init(of body: () throws -> FulfilledValue) {
        do    { self =  try .fulfilled( body() ) }
        catch { self =      .rejected ( error) }
    }
}

public extension Result {
    @discardableResult
    public func then<NewFulfilledValue>( execute body: (FulfilledValue) throws -> NewFulfilledValue )  -> Result<NewFulfilledValue>  {
        switch self {
        case .rejected(let e):
            return .rejected(e)
        case .fulfilled(let r):
            do    { return try .fulfilled( body(r) ) }
            catch { return .rejected( error ) }
        }
    }
}

public extension Result {
    @discardableResult
    public func `catch`( execute body: (Error) -> Void) -> Result {
        switch self {
        case .fulfilled:
            break
        case .rejected(let e):
            body(e)
        }
        return self
    }
}

public extension Result { // not for book

    @discardableResult // avoid a warning if result is not used
    public func recover(execute body: (Error) throws -> FulfilledValue) -> Result {
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


