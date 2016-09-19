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
    
    func testBasic() {
        
        let expectation1 = expectation(description: "Get all the user feeds")
        
        _ = firstly {
            echoPromise(message: "Awesome")
            }
        .then { returnedMessage in
            XCTAssertEqual(returnedMessage, "Echo: Awesome")
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: { _ in  })
        
    }


    static var allTests : [(String, (MiniPromiseKitTests) -> () throws -> Void)] {
        return [
            ("testBasic", testBasic),
        ]
    }
}
