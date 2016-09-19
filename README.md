# miniPromiseKit

A simplified subset of the [PromiseKit](https://github.com/mxcl/PromiseKit) library for an upcoming book

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