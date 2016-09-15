//
//  BasicPromise.swift
//  SwiftBook_S1-4
//
//  Created by David Ungar on 9/14/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

// A BasicPromise handles any type of Outcome, and doesn't care about errors.

public class BasicPromise<Outcome> {
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
    
    public convenience init(resolver: (
        _ fulfill: @escaping (Outcome) -> Void
        ) -> Void) {
        self.init()
        resolver(fulfill)
    }
    
    // TODO change init? ala Prom
    
    public convenience init(outcome: Outcome) {
        self.init { fulfill in
            fulfill(outcome)
        }
    }
    
    
    public func fulfill(_ outcome: Outcome) -> Void {
        oneAtATime {
            if let reader = self.readerIfKnown {
                DispatchQueue(label: "BasicPromise reader", qos: .userInitiated)
                    .async {
                        reader(outcome)
                }
            }
            else {
                self.outcomeIfKnown = outcome
            }
        }
    }
    
    
    // When ready, run reader with outcome
    
    public func then<NewOutcome>(
        on q: DispatchQueue = .main,
        execute transformer: @escaping (Outcome) -> NewOutcome
        ) -> BasicPromise<NewOutcome>
    {
        let p = BasicPromise<NewOutcome>()
        _ = then(on: q) { p.fulfill( transformer( $0 ) ) }
        return p
    }
    
    public func then<NewOutcome>(
        on q: DispatchQueue = .main,
        execute asyncTransformer: @escaping (Outcome) -> BasicPromise<NewOutcome>
        ) -> BasicPromise<NewOutcome>
    {
        let p = BasicPromise<NewOutcome>()
        _ = then(on: q) {
            ($0 |> asyncTransformer).then(on: q) { p.fulfill($0) }
        }
        return p
    }
    
 }
