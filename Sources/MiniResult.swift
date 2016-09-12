
import Foundation

private enum Errors: Error, CustomStringConvertible {
    case alreadyHandled(Error)
    
    public var description: String {
        switch self {
        case .alreadyHandled(let error):
            return "alreadyHandled \(error.localizedDescription)"
        }
    }
    public var localizedDescription: String { return description }
}


public enum MiniResult<Result> {
    case failure(Error)
    case success(Result)
    
    // Success consumer might fail:
    @discardableResult // avoid a warning if result is not used
    public func ifSuccess<NewResult>(_ fn: (Result) -> MiniResult<NewResult>) -> MiniResult<NewResult> {
        switch self {
            // Because compiler infers types
        // you don't have to say "return MiniResult<NewResult>.failure(e)" below.
        case .failure(let e): return .failure(e)
        case .success(let r): return fn(r)
        }
    }
    
    // Success consumer always succeeds:
    @discardableResult // avoid a warning if result is not used
    public func ifSuccess<NewResult>( _ fn: (Result) -> NewResult )  -> MiniResult<NewResult>  {
        switch self {
        case .failure(let e): return .failure(e)
        case .success(let r): return MiniResult<NewResult>.success( fn(r) )
        }
    }
    
    @discardableResult // avoid a warning if result is not used
    public func ifFailure(_ fn: (Error) -> Void) -> MiniResult {
        switch self {
        case .success: return self
        case .failure(let e):
            fn(e)
            return .failure(Errors.alreadyHandled(e))
        }
    }
    
    public static func catching(_ fn: () throws -> Result ) -> MiniResult<Result> {
        do    { return try .success( fn()  ) }
        catch { return     .failure( error ) }
    }
 }
