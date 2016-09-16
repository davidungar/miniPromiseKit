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
    private typealias Consumer = (Outcome) -> Void
    private var outcomeIfKnown: Outcome?
    private var consumerAndQueueIfKnown: (consumer: Consumer, q: DispatchQueue)?
    
    
    private let racePrevention = DispatchSemaphore(value: 1)
    private func oneAtATime(_ fn: () -> Void) {
        defer { racePrevention.signal() }
        racePrevention.wait()
        fn()
    }
    
    internal static var defaultQ: DispatchQueue {
        return .main
            // .global(qos: .userInitiated)
    }
    
    public init() {}
    
    
    
    public func fulfill(_ outcome: Outcome) -> Void
    {
        oneAtATime {
            if let (consumer, q) = self.consumerAndQueueIfKnown {
                q.async {
                    consumer(outcome)
                }
            }
            else {
                self.outcomeIfKnown = outcome
            }
        }
    }
    
    public func then(
        on q: DispatchQueue = BasicPromise.defaultQ,
        execute consumer: @escaping (Outcome) -> Void
    )
    {
        oneAtATime {
            if let outcome = outcomeIfKnown {
                q.async { consumer(outcome) }
            }
            else {
                self.consumerAndQueueIfKnown = (consumer, q)
            }
        }
    }
    
    
    
    public func then<NewOutcome>(
        on q: DispatchQueue = BasicPromise.defaultQ,
        execute transformer: @escaping (Outcome) -> NewOutcome
        ) -> BasicPromise<NewOutcome>
    {
        let p = BasicPromise<NewOutcome>()
        then(on: q) { p.fulfill( transformer( $0 ) ) }
        return p
    }
    
    public func then<NewOutcome>(
        on q: DispatchQueue = BasicPromise.defaultQ,
        execute asyncTransformer: @escaping (Outcome) -> BasicPromise<NewOutcome>
        ) -> BasicPromise<NewOutcome>
    {
        let p = BasicPromise<NewOutcome>()
        then(on: q) {
            asyncTransformer($0)
                .then(on: q) { p.fulfill($0) }
        }
        return p
    }
 }
