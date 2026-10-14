import Foundation

/// Which shield the build can offer. Set with `MINIMAL_EDITION` in Config/Signing.xcconfig.
enum Edition {
    /// Full: Screen Time API + DNS settings (needs a paid Apple Developer account).
    /// Free: free Apple ID — the shield is set up through iOS Settings and a DNS profile.
    static let isFull: Bool = (Bundle.main.object(forInfoDictionaryKey: "MinimalEdition") as? String) != "Free"
}
