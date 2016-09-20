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

// A BasicPromise handles any type of Outcome, and doesn't help deal with about errors.

private var defaultQ: DispatchQueue = .main

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
    
    internal static var defaultQueue: DispatchQueue {
        get { return defaultQ }
        set { defaultQ = newValue }
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
        on q: DispatchQueue = BasicPromise.defaultQueue,
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
        on q: DispatchQueue = BasicPromise.defaultQueue,
        execute transformer: @escaping (Outcome) -> NewOutcome
        ) -> BasicPromise<NewOutcome>
    {
        let p = BasicPromise<NewOutcome>()
        then(on: q) { p.fulfill( transformer( $0 ) ) }
        return p
    }
    
    
    public func then<NewOutcome>(
        on q: DispatchQueue = BasicPromise.defaultQueue,
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
