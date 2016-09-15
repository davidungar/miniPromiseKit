//
//  Created by David Ungar on 9/9/16.
//  A toy implementation of PromiseKit.
//  Comments copied from PromiseKit
//
//

import Foundation



public func firstly<FulfilledValue>(
    execute body: () throws -> Promise<FulfilledValue>
    ) -> Promise<FulfilledValue>
{
    do {
        return try body()
    } catch {
        return Promise(error: error)
    }
}


// MARK: - members when outcome is result or error. Finagling with protocols to do it.


public struct Promise<FulfilledValue> {
    let basicPromise: BasicPromise< Result< FulfilledValue > >
    
    private init(
        basedOn basis: BasicPromise< Result<FulfilledValue> > = BasicPromise()
        )
    {
        basicPromise = basis
    }

    public  init(
        resolvers: (
        _ fulfill: @escaping (FulfilledValue ) -> Void,
        _ reject:  @escaping (Error          ) -> Void
        ) throws -> Void
        )
    {
        self.init()
        func fulfillBasic(_ r: Result< FulfilledValue >) {
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
    
    public typealias PendingTuple = (promise: Promise, fulfill: (FulfilledValue) -> Void, reject: (Error) -> Void)
    
    public static func pending() -> PendingTuple {
        var fulfill: ((FulfilledValue) -> Void)!
        var reject:  ((Error) -> Void)!
        let promise = Promise { fulfill = $0; reject = $1 }
        return (promise, fulfill, reject)
    }
    
    
    public init(value: FulfilledValue) {
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
    public func then<NewFulfilledValue>(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (FulfilledValue) throws -> NewFulfilledValue
        ) -> Promise<NewFulfilledValue>
    {
        let newBasicPromise = basicPromise.then(on: q) {
            $0.then(execute: body)
        }
        return Promise<NewFulfilledValue>(basedOn: newBasicPromise)
    }
    
    
    public func then<NewFulfilledValue>(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (FulfilledValue) throws -> Promise<NewFulfilledValue>) -> Promise<NewFulfilledValue>
    {
        let (newPromise, fulfill, reject) = Promise<NewFulfilledValue>.pending()
        _ = basicPromise.then(on: q) {
            $0.then(execute: body)
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
            outcome -> Result<FulfilledValue>  in
            outcome.catch     (execute: body)
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
        execute body: @escaping (Error) throws -> FulfilledValue
        ) -> Promise
    {
        let (newPromise, fulfill, reject) = Promise.pending()
        _ = basicPromise.then(on: q) {
            $0
                .recover(execute: body)
                .then( execute: fulfill )
                .catch      ( execute: reject  )
        }
        return newPromise
    }
    
    
    public func tap(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQ,
        execute body: @escaping (Result<FulfilledValue>) -> Void
        ) -> Promise
    {
        let newBasicPromise = basicPromise.then(on: q) {
            outcome -> Result<FulfilledValue> in
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

