//
//  Created by David Ungar on 9/9/16.
//  A toy implementation of PromiseKit.
//  Comments copied from PromiseKit
//
//

import Foundation



public func firstly<FulfilledResult>(
    execute body: () throws -> Promise<FulfilledResult>
    ) -> Promise<FulfilledResult>
{
    do {
        return try body()
    } catch {
        return Promise(error: error)
    }
}



// MARK: - members when outcome is result or error. Finagling with protocols to do it.


public struct Promise<FulfilledResult> {
    let basicPromise: BasicPromise< Result< FulfilledResult > >
    
    private init(
        basedOn basis: BasicPromise< Result<FulfilledResult> > = BasicPromise()
        )
    {
        basicPromise = basis
    }

    public  init(
        resolvers: (
        _ fulfill: @escaping (FulfilledResult ) -> Void,
        _ reject:  @escaping (Error         ) -> Void
        )  throws -> Void
        )
    {
        self.init()
        func fulfillBasic(_ r: Result< FulfilledResult >) {
            basicPromise.fulfill(r)
        }
        do {
            try resolvers(
                { fulfillBasic(.fulfilled($0)) },
                { fulfillBasic(.rejected($0)) }
            )
        }
        catch {
            fulfillBasic(.rejected(error))
        }
    }
    
    public typealias PendingTuple = (promise: Promise, fulfill: (FulfilledResult) -> Void, reject: (Error) -> Void)
    
    public static func pending() -> PendingTuple {
        var fulfill: ((FulfilledResult) -> Void)!
        var reject:  ((Error) -> Void)!
        let promise = Promise { fulfill = $0; reject = $1 }
        return (promise, fulfill, reject)
    }
    
    
    public init(value: FulfilledResult) {
        self.init {
            fulfill, reject in
            fulfill(value)
        }
    }
    public init(error: Error) {
        self.init {
            fulfill, reject in
            reject(error)
        }
    }
    
    // FIXME: ToyPromise vs Promise filenames, group names
    public func then<NewFulfilledResult>(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (FulfilledResult) throws -> NewFulfilledResult
        ) -> Promise<NewFulfilledResult>
    {
        let newBasicPromise = basicPromise.then(on: q) {
            outcome -> Result<NewFulfilledResult> in
            switch outcome {
            case let .rejected(e):
                return .rejected(e)
            case let .fulfilled(r):
                do    { return .fulfilled( try body(r) ) }
                catch { return .rejected( error )       }
            }
        }
        return Promise<NewFulfilledResult>(basedOn: newBasicPromise)
    }
    
    
    public func then<NewFulfilledResult>(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (FulfilledResult) throws -> Promise<NewFulfilledResult>) -> Promise<NewFulfilledResult>
    {
        let (newPromise, fulfill, reject) = Promise<NewFulfilledResult>.pending()
        _ = basicPromise.then(on: q) {
            outcome  -> Void in
            switch outcome {
            case let .rejected(e):
                reject(e)
            case let .fulfilled(r):
                do {
                    try body(r)
                        .then (execute: fulfill)
                        .catch(execute: reject)
                }
                catch { reject(error) }
            }
        }
        return newPromise
    }
    
    
    @discardableResult
    public func `catch`(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (Error) -> Void
        ) -> Promise
    {
        let newBasicPromise = basicPromise.then(on: q) {
            outcome -> Result<FulfilledResult>  in
            if case let .rejected(e) = outcome {
                body(e)
            }
            return outcome
        }
        return Promise(basedOn: newBasicPromise)
    }
    
    public func recover(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (Error) throws -> Promise
        ) -> Promise
    {
        let (newPromise, fulfill, reject) = Promise.pending()
        _ = basicPromise.then(on: q) {
            switch $0 {
            case let .fulfilled(r): fulfill(r)
            case let .rejected(e):
                do {
                    _ = try body(e)
                        .then (on: q, execute: fulfill)
                        .catch(on: q, execute: reject )
                }
                catch { reject(error) }
            }
        }
        return newPromise
    }
    
    public func recover(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (Error) throws -> FulfilledResult
        ) -> Promise
    {
        let (newPromise, fulfill, reject) = Promise.pending()
        _ = basicPromise.then(on: q) {
            switch $0 {
            case let .fulfilled(r): fulfill(r)
            case let .rejected(e):
                do    { try fulfill( body(e) ) }
                catch {     reject(  error )   }
            }
        }
        return newPromise
    }
    
    
    public func tap(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (Result<FulfilledResult>) -> Void
        ) -> Promise
    {
        let newBasicPromise = basicPromise.then(on: q) {
            outcome -> Result<FulfilledResult> in
            body(outcome)
            return outcome
        }
        return Promise(basedOn: newBasicPromise)
    }
    
    public func always(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping () -> Void
        )
        -> Promise
    {
        return tap(on: q) { _ in body() }
    }

}

