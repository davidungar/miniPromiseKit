//
//  Created by David Ungar on 9/9/16.
//  A toy implementation of PromiseKit.
//  Comments copied from PromiseKit
//
//

import Foundation



public func firstly<SuccessResult>(
    execute body: () throws -> Promise<SuccessResult>
    ) -> Promise<SuccessResult>
{
    do {
        return try body()
    } catch {
        return Promise(error: error)
    }
}



// MARK: - members when outcome is result or error. Finagling with protocols to do it.


public struct Promise<SuccessResult> {
    let basicPromise: BasicPromise< ResultOrError< SuccessResult > >
    
    private init(
        basedOn basis: BasicPromise< ResultOrError<SuccessResult> > = BasicPromise()
        )
    {
        basicPromise = basis
    }

    public  init(
        resolvers: (
        _ fulfill: @escaping (SuccessResult ) -> Void,
        _ reject:  @escaping (Error         ) -> Void
        )  throws -> Void
        )
    {
        self.init()
        func fulfillBasic(_ r: ResultOrError< SuccessResult >) {
            basicPromise.fulfill(r)
        }
        do {
            try resolvers(
                { fulfillBasic(.success($0)) },
                { fulfillBasic(.failure($0)) }
            )
        }
        catch {
            fulfillBasic(.failure(error))
        }
    }
    
    public typealias PendingTuple = (promise: Promise, fulfill: (SuccessResult) -> Void, reject: (Error) -> Void)
    
    public static func pending() -> PendingTuple {
        var fulfill: ((SuccessResult) -> Void)!
        var reject:  ((Error) -> Void)!
        let promise = Promise { fulfill = $0; reject = $1 }
        return (promise, fulfill, reject)
    }
    
    
    public init(value: SuccessResult) {
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
    public func then<NewSuccessResult>(
        on q: DispatchQueue = .main,
        execute body: @escaping (SuccessResult) throws -> NewSuccessResult
        ) -> Promise<NewSuccessResult>
    {
        let newBasicPromise = basicPromise.then(on: q) {
            outcome -> ResultOrError<NewSuccessResult> in
            switch outcome {
            case let .failure(e):
                return .failure(e)
            case let .success(r):
                do    { return .success( try body(r) ) }
                catch { return .failure( error )       }
            }
        }
        return Promise<NewSuccessResult>(basedOn: newBasicPromise)
    }
    
    
    public func then<NewSuccessResult>(
        on q: DispatchQueue = .main,
        execute body: @escaping (SuccessResult) throws -> Promise<NewSuccessResult>) -> Promise<NewSuccessResult>
    {
        let (newPromise, fulfill, reject) = Promise<NewSuccessResult>.pending()
        _ = basicPromise.then(on: q) {
            outcome  -> Void in
            switch outcome {
            case let .failure(e):
                reject(e)
            case let .success(r):
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
        on q: DispatchQueue = .main,
        execute body: @escaping (Error) -> Void
        ) -> Promise
    {
        let newBasicPromise = basicPromise.then(on: q) {
            outcome -> ResultOrError<SuccessResult>  in
            if case let .failure(e) = outcome {
                body(e)
            }
            return outcome
        }
        return Promise(basedOn: newBasicPromise)
    }
    
    public func recover(
        on q: DispatchQueue = .main,
        execute body: @escaping (Error) throws -> Promise
        ) -> Promise
    {
        let (newPromise, fulfill, reject) = Promise.pending()
        _ = basicPromise.then(on: q) {
            switch $0 {
            case let .success(r): fulfill(r)
            case let .failure(e):
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
        on q: DispatchQueue = .main,
        execute body: @escaping (Error) throws -> SuccessResult
        ) -> Promise
    {
        let (newPromise, fulfill, reject) = Promise.pending()
        _ = basicPromise.then(on: q) {
            switch $0 {
            case let .success(r): fulfill(r)
            case let .failure(e):
                do    { try fulfill( body(e) ) }
                catch {     reject(  error )   }
            }
        }
        return newPromise
    }
    
    
    public func tap(
        on q: DispatchQueue = .main,
        execute body: @escaping (ResultOrError<SuccessResult>) -> Void
        ) -> Promise
    {
        let newBasicPromise = basicPromise.then(on: q) {
            outcome -> ResultOrError<SuccessResult> in
            body(outcome)
            return outcome
        }
        return Promise(basedOn: newBasicPromise)
    }
    
    public func always(
        on q: DispatchQueue = .main,
        execute body: @escaping () -> Void
        )
        -> Promise
    {
        return tap(on: q) { _ in body() }
    }

}

