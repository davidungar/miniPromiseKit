# miniPromiseKit

A simplified subset of the [PromiseKit](https://github.com/mxcl/PromiseKit) library for an upcoming book

[![Build Status](https://travis-ci.org/davidungar/miniPromiseKit.svg?branch=master)](https://travis-ci.org/davidungar/miniPromiseKit)
![](https://img.shields.io/badge/Swift-3.0%20RELEASE-orange.svg?style=flat)
![](https://img.shields.io/badge/platform-Linux,%20macOS-blue.svg?style=flat)

## Basic usage

Creating promises:

```swift
func getTasks() -> Promise<[Task]> {
        return Promise { fulfill, reject in 
            database.getTasks() {
                fulfill(values)
            }
        }
    }
```

Using promise chains:

```swift
firstly {
     return self.database.getTasks()
 }
.then(on: queue) { tasks -> Void in
     response.send(json: JSON(tasks.stringValuePairs))
 }
.always(on: queue) { _ in
     next()
 }
.catch { error in
    response.status(.badRequest).send("Error in the request")
 }
```


## License

Copyright 2016 IBM

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
