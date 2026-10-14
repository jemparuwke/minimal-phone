import Foundation
import NetworkExtension

/// Family-safe encrypted DNS resolvers. Each blocks pornography for the whole phone
/// (every app and browser), because adult domains simply stop resolving.
enum DNSProvider: String, CaseIterable, Identifiable {
    case cleanBrowsingAdult
    case adGuardFamily
    case cloudflareFamily

    var id: String { rawValue }

    var name: String {
        switch self {
        case .cleanBrowsingAdult: return "CleanBrowsing"
        case .adGuardFamily: return "AdGuard Family"
        case .cloudflareFamily: return "Cloudflare Family"
        }
    }

    var summary: String {
        switch self {
        case .cleanBrowsingAdult:
            return "Blokuje porno i wymusza bezpieczne wyszukiwanie w Google i Bing. Polecany."
        case .adGuardFamily:
            return "Blokuje porno, wymusza bezpieczne wyszukiwanie i tryb ograniczony YouTube. Najostrzejszy."
        case .cloudflareFamily:
            return "Blokuje porno i złośliwe strony. Najszybszy, bez wymuszania SafeSearch."
        }
    }

    /// DNS-over-HTTPS endpoint.
    var serverURL: URL {
        switch self {
        case .cleanBrowsingAdult: return URL(string: "https://doh.cleanbrowsing.org/doh/adult-filter/")!
        case .adGuardFamily: return URL(string: "https://family.adguard-dns.com/dns-query")!
        case .cloudflareFamily: return URL(string: "https://family.cloudflare-dns.com/dns-query")!
        }
    }

    /// Bootstrap addresses of the same resolver (IPv4 + IPv6).
    var servers: [String] {
        switch self {
        case .cleanBrowsingAdult:
            return ["185.228.168.10", "185.228.169.11", "2a0d:2a00:1::1", "2a0d:2a00:2::1"]
        case .adGuardFamily:
            return ["94.140.14.15", "94.140.15.16", "2a10:50c0::bad1:ff", "2a10:50c0::bad2:ff"]
        case .cloudflareFamily:
            return ["1.1.1.3", "1.0.0.3", "2606:4700:4700::1113", "2606:4700:4700::1003"]
        }
    }

    func makeSettings() -> NEDNSSettings {
        let settings = NEDNSOverHTTPSSettings(servers: servers)
        settings.serverURL = serverURL
        return settings
    }
}
