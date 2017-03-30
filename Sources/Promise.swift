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
import Dispatch

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




public struct Promise<FulfilledValue> {
    fileprivate let basicPromise: BasicPromise< Result< FulfilledValue > >
}


public extension Promise {
    fileprivate init(
        basedOn basis: BasicPromise< Result<FulfilledValue> > = BasicPromise()
        )
    {
        basicPromise = basis
    }
    
    // Following PromiseKit's convention, the public initializer and static method also supply the fulfill and reject routines for the created Promise:

    public  init(
        resolvers: (
        _ fulfill: @escaping (FulfilledValue ) -> Void,
        _ reject:  @escaping (Error          ) -> Void
        ) throws -> Void
        )
    {
        self.init()
        let bP = basicPromise // fix for EXC_BAD_ACCESS after update to Swift 3.1 (in func fulfullBasic)
        func fulfillBasic(_ r: Result< FulfilledValue >) {
            bP.fulfill(r)
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
    
}

// Two implementations of then are needed, depending upon whether the body is synchronous or asynchronous:
public extension Promise {
    
    public func then<NewFulfilledValue>(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQueue,
        execute body: @escaping (FulfilledValue) throws -> NewFulfilledValue
        ) -> Promise<NewFulfilledValue>
    {
        let newBasicPromise = basicPromise.then(on: q) {
            $0.then(execute: body)
        }
        return Promise<NewFulfilledValue>(basedOn: newBasicPromise)
    }
    
    
    public func then<NewFulfilledValue>(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQueue,
        execute body: @escaping (FulfilledValue) throws -> Promise<NewFulfilledValue>
        ) -> Promise<NewFulfilledValue>
    {
        return Promise<NewFulfilledValue> {
            fulfill, reject in
            _ = basicPromise.then(on: q) {
                result -> Void in
                _ = result
                    .catch { (e: Error) -> Void in reject(e) }
                    .then  {
                        do    {
                            try body($0)
                                .then( on: q, execute: fulfill)
                                .catch(on: q, execute: reject )
                        }
                        catch { reject(error) }
                }
            }
        }
    }
}

// Catch and recover handle errors. The latter allows an error to be turned back into success:
public extension Promise {
    @discardableResult
    public func `catch`(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQueue,
        execute body: @escaping (Error) -> Void
        ) -> Promise
    {
        let newBasicPromise = basicPromise.then(on: q) {
            outcome -> Result<FulfilledValue>  in
            outcome.catch(execute: body)
            return outcome
        }
        return Promise(basedOn: newBasicPromise)
    }
    
    public func recover(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQueue,
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
        on q: DispatchQueue  = BasicPromise<Void>.defaultQueue,
        execute body: @escaping (Error) throws -> FulfilledValue
        ) -> Promise
    {
        let (newPromise, fulfill, reject) = Promise.pending()
        _ = basicPromise.then(on: q) {
            $0
                .recover( execute: body    )
                .then   ( execute: fulfill )
                .catch  ( execute: reject  )
        }
        return newPromise
    }
}

// Tap and always provide points to observe a chain of results no matter whether things are failing or succeeding:
public extension Promise {
    public func tap(
        on q: DispatchQueue  = BasicPromise<Void>.defaultQueue,
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
        on q: DispatchQueue  = BasicPromise<Void>.defaultQueue,
        execute body: @escaping () -> Void
        )
        -> Promise
    {
        return tap(on: q) { _ in body() }
    }
}

