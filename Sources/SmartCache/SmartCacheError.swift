import Foundation

/// Problems a ``SmartCacheValue`` conformance can report.
public enum SmartCacheError: Error, Equatable{
    /// The value could not be turned into storage data.
    case encodingFailed
    /// Storage data could not be turned back into a value.
    case decodingFailed
}
