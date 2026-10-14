import ManagedSettings

/// Extra domains blocked on top of Apple's automatic adult-content filter.
/// Apple's filter already covers these; listing the biggest ones explicitly makes
/// sure they stay blocked even if a site is temporarily misclassified.
enum BlockedDomains {
    static let names: [String] = [
        "pornhub.com", "xvideos.com", "xnxx.com", "xhamster.com", "xhamster.desi",
        "youporn.com", "redtube.com", "tube8.com", "spankbang.com", "eporner.com",
        "porn.com", "porntrex.com", "hqporner.com", "beeg.com", "txxx.com",
        "tnaflix.com", "motherless.com", "youjizz.com", "thumbzilla.com", "pornone.com",
        "onlyfans.com", "fansly.com", "chaturbate.com", "stripchat.com", "bongacams.com",
        "cam4.com", "livejasmin.com", "myfreecams.com", "camsoda.com", "manyvids.com",
        "brazzers.com", "bangbros.com", "realitykings.com", "naughtyamerica.com", "rule34.xxx",
        "e-hentai.org", "nhentai.net", "hanime.tv", "literotica.com", "sex.com",
        "efukt.com", "heavy-r.com", "fapello.com", "erome.com", "redgifs.com",
    ]

    static var domains: Set<WebDomain> {
        Set(names.map { WebDomain(domain: $0) })
    }
}
