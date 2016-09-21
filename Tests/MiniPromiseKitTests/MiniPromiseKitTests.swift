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

import XCTest
@testable import MiniPromiseKit

let queue = DispatchQueue(label: "com.example.todolist")

func echoPromise(message: String) -> Promise<String> {
    return Promise { fulfill, reject in
        queue.async {
            fulfill("Echo: \(message)")
        }
    }
}

class MiniPromiseKitTests: XCTestCase {
    
    func testFirstlySuccess() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly {   echoPromise(message: "Awesome")   }
        .then { returnedMessage in
            XCTAssertEqual(returnedMessage, "Echo: Awesome")
            expectation1.fulfill()
        }
            .catch { _ in XCTFail() }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    enum TestError: Error {
        case firstlyFailure, alwaysFailure, tapFailure, thenSyncFailure, thenAsyncFailure
    }
    func testFirstlyFailure() {
        let expectation1 = expectation(description: "Good")
        
        _ = firstly { (Void) throws -> Promise<Int> in throw TestError.firstlyFailure  }
            .then { _ -> Void in XCTFail() }
            .catch {
                XCTAssert( $0 as? TestError  == TestError.firstlyFailure )
                expectation1.fulfill()
        }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testAlwaysSuccess() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly {   echoPromise(message: "Awesome")   }
            .always {
                expectation1.fulfill()
            }
            .catch { _ in XCTFail() }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testAlwaysFailure() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly { (Void) throws -> Promise<Int> in throw TestError.alwaysFailure  }
            .always {
                expectation1.fulfill()
            }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testTapSuccess() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly {   echoPromise(message: "Awesome")   }
            .tap {
                if case let .fulfilled(msg) = $0 {
                    XCTAssertEqual(msg, "Echo: Awesome")
                }
                else {
                    XCTFail()
                }
                expectation1.fulfill()
            }
            .catch { _ in XCTFail() }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testTapFailure() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly { (Void) throws -> Promise<Int> in throw TestError.tapFailure  }
            .tap {
                if case let .rejected(e) = $0 {
                    XCTAssert(e as? TestError  ==  TestError.tapFailure)
                }
                else {
                    XCTFail()
                }
                expectation1.fulfill()
        }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testThenSyncSuccess() {
        let expectation1 = expectation(description: "Get all the user feeds")
        var firstThen = false
        
        _ = firstly {   Promise(value: "Awesome")   }
            .then { (s: String) -> String in
                firstThen = s == "Awesome"
                XCTAssert(firstThen)
                return firstThen ? "yes" : "no"
            }
            .then {
                XCTAssert( firstThen &&  $0 == "yes")
                expectation1.fulfill()
                return
            }
            .catch { _ in XCTFail() }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testThenSyncFailure() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly { (Void) throws -> Promise<Int> in throw TestError.thenSyncFailure  }
            .then { _ in XCTFail() }
            .catch {
                XCTAssert($0 as? TestError  ==  TestError.thenSyncFailure)
                expectation1.fulfill()
        }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testThenAsyncSuccess() {
        let expectation1 = expectation(description: "Get all the user feeds")
        var firstThen = false
        
        _ = firstly {   Promise(value: "Awesome")   }
            .then { (s: String) -> Promise<String> in
                Promise<String> {
                    fulfill, reject in
                    DispatchQueue.global(qos: .userInitiated).async {
                        firstThen = s == "Awesome"
                        XCTAssert(firstThen)
                        if firstThen { fulfill("yes") }  else { reject(TestError.thenAsyncFailure) }
                    }
                }
            }
            .then {
                XCTAssert( firstThen &&  $0 == "yes")
                expectation1.fulfill()
                return
            }
            .catch { _ in XCTFail() }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testThenAsyncFailure() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly { (Void) throws -> Promise<Int> in   throw TestError.thenAsyncFailure  }
            .then { (Int) -> Promise<Int> in
                Promise<Int> {
                    fulfill, reject in
                    XCTFail()
                    fulfill(3)
                }
            }
            .catch {
                XCTAssert($0 as? TestError  ==  TestError.thenAsyncFailure)
                expectation1.fulfill()
        }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testNoRecoverSuccess() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly { Promise(value: "Awesome") }
            .recover { (Error) -> String in
                XCTFail()
                return "no"
            }
            .then {
                XCTAssert( $0 == "Awesome")
                expectation1.fulfill()
                return
            }
            .catch { _ in XCTFail() }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testRecoverSyncSuccess() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly {   (Void) throws -> Promise<String> in   throw TestError.thenAsyncFailure  }
            .recover { (e: Error) -> String in
                XCTAssert(e as? TestError == .thenAsyncFailure)
                return "yes"
            }
            .then {
                XCTAssert( $0 == "yes")
                expectation1.fulfill()
                return
            }
            .catch { _ in XCTFail() }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }
    func testRecoverAsyncSuccess() {
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly {   (Void) throws -> Promise<String> in   throw TestError.thenAsyncFailure  }
            .recover { (e: Error) -> Promise<String> in
                XCTAssert(e as? TestError == .thenAsyncFailure)
                return Promise<String> {
                    fulfill, reject in
                    DispatchQueue.global(qos: .userInitiated).async {
                        fulfill("yes")
                    }
                }
            }
            .then {
                XCTAssert( $0 == "yes")
                expectation1.fulfill()
                return
            }
            .catch { _ in XCTFail() }
        waitForExpectations(timeout: 5, handler: { _ in  })
    }



    static var allTests : [(String, (MiniPromiseKitTests) -> () throws -> Void)] {
        return [
            ("testFirstlySuccess",      testFirstlySuccess),
            ("testFirstlyFailure",      testFirstlyFailure),
            ("testAlwaysSuccess",       testAlwaysSuccess),
            ("testAlwaysFailure",       testAlwaysFailure),
            ("testTapSuccess",          testTapSuccess),
            ("testTapFailure",          testTapFailure),
            ("testThenSyncSuccess",     testThenSyncSuccess),
            ("testThenSyncFailure",     testThenSyncFailure),
            ("testThenAsyncSuccess",    testThenAsyncSuccess),
            ("testThenAsyncFailure",    testThenAsyncFailure),
            ("testNoRecoverSuccess",    testNoRecoverSuccess),
            ("testRecoverSyncSuccess",  testRecoverSyncSuccess),
            ("testRecoverAsyncSuccess", testRecoverAsyncSuccess),
       ]
    }
}
