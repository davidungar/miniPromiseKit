//
//  Created by David Ungar on 9/9/16.
//  A toy implementation of PromiseKit.
//  Comments copied from PromiseKit
//
//

import Foundation

public typealias MiniPromise<ResultType> = GeneralPromise<MiniResult<ResultType>>


//: Simple GeneralPromise implementation, no errors, no composition
//: Leaks memory, most likely

// MARK: - first, basic future without MiniResult

public func firstly<Result>(execute body: () throws -> MiniPromise<Result>) -> MiniPromise<Result> {
    do {
        return try body()
    } catch {
        return MiniPromise(error: error)
    }
}


// A GeneralPromise handles any type of Outcome, and doesn't care about errors.

public class GeneralPromise<Outcome> {
    private typealias Reader = (Outcome) -> Void
    private var outcomeIfKnown: Outcome?
    private var readerIfKnown: Reader?
    
    
    private let racePrevention = DispatchSemaphore(value: 1)
    private func oneAtATime(_ fn: () -> Void) {
        defer { racePrevention.signal() }
        racePrevention.wait()
        fn()
    }
    
    
    public init() {}
    
     public convenience init(outcome: Outcome) {
        self.init()
        resolve(outcome)
    }
    
    
    public func resolve(_ outcome: Outcome) -> Void {
        oneAtATime {
            if let reader = self.readerIfKnown {
                DispatchQueue(label: "GeneralPromise reader", qos: .userInitiated)
                    .async {
                        reader(outcome)
                }
            }
            else {
                self.outcomeIfKnown = outcome
            }
        }
    }
    
    public func always(
        on q: DispatchQueue = .main,
        execute body: @escaping () -> Void
        )
        -> GeneralPromise
    {
        let p = GeneralPromise()
        getOutcome(on: q) {
            body()
            p.resolve($0)
        }
        return p
    }
    
    // When ready, run reader with outcome
    fileprivate func getOutcome(
        on q: DispatchQueue = .main,
        execute reader: @escaping (Outcome) -> Void
        )
    {
        oneAtATime {
            if let outcome = self.outcomeIfKnown {
                q.async { reader(outcome) }
            }
            else {
                self.readerIfKnown = reader
            }
        }
    }
    
    fileprivate func transformOutcome<NewOutcome>(
        on q: DispatchQueue = .main,
        execute transformer: @escaping (Outcome) -> NewOutcome
        ) -> GeneralPromise<NewOutcome>
    {
        let p = GeneralPromise<NewOutcome>()
        getOutcome(on: q) { p.resolve( transformer( $0 ) ) }
        return p
    }
    
    fileprivate func asyncTransformOutcome<NewOutcome>(
        on q: DispatchQueue = .main,
        execute asyncTransformer: @escaping (Outcome) -> GeneralPromise<NewOutcome>
        ) -> GeneralPromise<NewOutcome>
    {
        let p = GeneralPromise<NewOutcome>()
        getOutcome(on: q) {
            ($0 |> asyncTransformer).getOutcome(on: q) { p.resolve($0) }
        }
        return p
    }
    
    public func tap(
        on q: DispatchQueue = .main,
        execute body: @escaping (Outcome) -> Void
        ) -> GeneralPromise
    {
        return transformOutcome(on: q) {
            body($0)
            return $0
        }
    }
}





// MARK: - members when outcome is result or error. Finagling with protocols to do it.

public protocol MiniResultProtocol {
    associatedtype Result
    var asMiniResult: MiniResult<Result> { get }
    
    static func with( error  e: Error  ) -> Self
    static func with( result s: Result ) -> Self
}
extension MiniResult: MiniResultProtocol {
    public var asMiniResult: MiniResult { return self }
    
    public static func with( error  e: Error ) -> MiniResult { return .failure(e) }
    public static func with( result s: Result) -> MiniResult { return .success(s) }
}

public extension GeneralPromise where Outcome: MiniResultProtocol {
    
    public convenience  init(
        resolvers: (
        _ fulfill: @escaping (Outcome.Result) -> Void,
        _ reject:  @escaping (Error         ) -> Void
        )  throws -> Void
        )
    {
        self.init()
        do {
            func fulfill(result: Outcome.Result) { resolve( Outcome.with(result: result)) }
            func reject (error:  Error         ) { resolve( Outcome.with(error:  error )) }
            try resolvers( fulfill, reject )
        }
        catch {
            error |> Outcome.with(error:) |> resolve
        }
    }
    
    public typealias PendingTuple = (promise: GeneralPromise, fulfill: (Outcome.Result) -> Void, reject: (Error) -> Void)
    
    public static func pending() -> PendingTuple {
        var fulfill: ((Outcome.Result) -> Void)!
        var reject: ((Error) -> Void)!
        let promise = GeneralPromise.init { fulfill = $0; reject = $1 }
        return (promise, fulfill, reject)
    }
    
    
    public convenience init(value: Outcome.Result) {
        self.init {
            fulfill, reject in
            fulfill(value)
        }
    }
    public convenience init(error: Error) {
        self.init {
            fulfill, reject in
            reject(error)
        }
    }
    
    // FIXME: ToyPromise vs MiniPromise filenames, group names
    public func then<NewResult>(
        on q: DispatchQueue = .main,
        execute body: @escaping (Outcome.Result) throws -> NewResult
        ) -> GeneralPromise<MiniResult<NewResult>>
    {
        return transformOutcome(on: q) {
            outcome -> MiniResult<NewResult> in
            switch outcome.asMiniResult {
            case let .success(r): return {try body(r)} |> MiniResult.catching
            case let .failure(e): return .failure(e)
            }
        }
    }
    
    public func then<NewResult>(
        on q: DispatchQueue = .main,
        execute body: @escaping (Outcome.Result) throws -> MiniPromise<NewResult>) -> MiniPromise<NewResult>
    {
        let (p, _, reject) = MiniPromise<NewResult>.pending()
        getOutcome(on: q) {
            outcome in
            switch outcome.asMiniResult {
            case let .success(r):
                do { try body(r).getOutcome(on: q, execute: p.resolve) }
                catch { reject(error) }
            case let .failure(e):
                reject(e)
            }
        }
        return p
    }
    
    @discardableResult
    public func `catch`(
        on q: DispatchQueue = .main,
        execute body: @escaping (Error) -> Void
        ) -> GeneralPromise
    {
        return transformOutcome(on: q) {
            if case let .failure(e) = $0.asMiniResult {
                body(e)
            }
            return $0
        }
    }
    
    public func recover(
        on q: DispatchQueue = .main,
        execute body: @escaping (Error) throws -> GeneralPromise
        ) -> GeneralPromise
    {
        let (newPromise, fulfill, reject) = GeneralPromise.pending()
        getOutcome(on: q) {
            switch $0.asMiniResult {
            case let .success(r): fulfill(r)
            case let .failure(e):
                do { try body(e).getOutcome(on: q, execute: newPromise.resolve) }
                catch { reject(error) }
            }
        }
        return newPromise
    }
    
    public func recover(
        on q: DispatchQueue = .main,
        execute body: @escaping (Error) throws -> Outcome.Result
        ) -> GeneralPromise
    {
        let (newPromise, fulfill, reject) = GeneralPromise.pending()
        getOutcome(on: q) {
            switch $0.asMiniResult {
            case let .success(r): fulfill(r)
            case let .failure(e):
                do { try body(e) |> fulfill }
                catch { reject(error) }
            }
        }
        return newPromise
    }
}