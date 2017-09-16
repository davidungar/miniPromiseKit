/**
 Copyright IBM Corporation 2016
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

// Abstract to a protocol for collection extensions
public protocol ResultProtocol {
    associatedtype FulfilledValue
    // SOMEDAY: make then return a ResultProtocol
    func then<NewFulfilledValue>( execute body: (FulfilledValue) throws -> NewFulfilledValue )  -> Result<NewFulfilledValue>
    func getOrThrow() throws -> FulfilledValue
    func recover(execute body: (Error) throws -> FulfilledValue) -> Self
    func `catch`( execute body: (Error) throws -> Void) rethrows -> Self
    
    func tap( execute body: (Self) -> Void ) -> Self
    func always( execute body: () -> Void ) -> Self
    var errorOrNil: Error? {get}
}

public enum Result<FulfilledValueParameter> {
    public typealias FulfilledValue = FulfilledValueParameter
    case fulfilled(FulfilledValue)
    case rejected(Error)
}

public extension Result {
    public init(of body: () throws -> FulfilledValue) {
        do    { self =  try .fulfilled( body() ) }
        catch { self =      .rejected ( error  ) }
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
            catch { return     .rejected( error   ) }
        }
    }
    public func getOrThrow() throws -> FulfilledValue {
        switch self {
        case .rejected(let e):
            throw e
        case .fulfilled(let r):
            return r
        }
    }
}

public extension Result {
    @discardableResult
    public func recover(execute body: (Error) throws -> FulfilledValue) -> Result {
        switch self {
        case .fulfilled: return self
        case .rejected(let e):
            do    { return try .fulfilled(body(e)) }
            catch { return .rejected(error)        }
        }
    }
    @discardableResult
    public func `catch`( execute body: (Error) throws -> Void) rethrows -> Result {
        switch self {
        case .fulfilled:
            break
        case .rejected(let e):
            try body(e)
        }
        return self
    }
}


public extension Result {
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

public extension Result {
    public var errorOrNil: Error? {
        switch self {
        case .rejected(let e): return e
        case .fulfilled: return nil
        }
    }
}

extension Result: ResultProtocol {}
