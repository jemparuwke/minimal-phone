import ManagedSettings

/// Extra domains blocked on top of Apple's automatic adult-content filter.
/// Apple's filter already covers these; listing the biggest ones explicitly makes
/// sure they stay blocked even if a site is temporarily misclassified.
enum BlockedDomains {
    /// Apple allows at most 50 extra domains; keep this list under that.
    static let names: [String] = [
        // Largest adult sites.
        "pornhub.com", "xvideos.com", "xnxx.com", "xhamster.com", "youporn.com",
        "redtube.com", "spankbang.com", "eporner.com", "porn.com", "porntrex.com",
        "hqporner.com", "beeg.com", "txxx.com", "tnaflix.com", "motherless.com",
        "youjizz.com", "onlyfans.com", "fansly.com", "chaturbate.com", "stripchat.com",
        "bongacams.com", "cam4.com", "livejasmin.com", "myfreecams.com", "camsoda.com",
        "manyvids.com", "brazzers.com", "rule34.xxx", "e-hentai.org", "nhentai.net",
        "hanime.tv", "literotica.com", "sex.com", "fapello.com", "erome.com",
        "redgifs.com", "coomer.su", "kemono.su",
        // Proxies that load any blocked page through an allowed domain.
        "translate.goog", "web.archive.org", "archive.ph", "archive.today", "archive.is",
    ]

    static var domains: Set<WebDomain> {
        Set(names.map { WebDomain(domain: $0) })
    }
}
