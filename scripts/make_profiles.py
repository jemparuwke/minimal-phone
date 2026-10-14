#!/usr/bin/env python3
"""Writes the encrypted-DNS configuration profiles in Profiles/.

These are a fallback for people who cannot build the app with a paid Apple
developer account: installing one blocks pornography for the whole phone,
no app required.

Usage: python3 scripts/make_profiles.py
"""
import plistlib
import uuid
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "Profiles"
NAMESPACE = uuid.UUID("5b0e7a7e-6d1c-4c1a-9a51-3c1f0f6e2b77")

PROVIDERS = [
    {
        "slug": "cleanbrowsing-family",
        "name": "CleanBrowsing Family Filter",
        "url": "https://doh.cleanbrowsing.org/doh/family-filter/",
        "servers": ["185.228.168.168", "185.228.169.168", "2a0d:2a00:1::", "2a0d:2a00:2::"],
        "blurb": "Blokuje porno, VPN-y i proxy, wymusza bezpieczne wyszukiwanie i tryb ograniczony YouTube.",
    },
    {
        "slug": "cleanbrowsing-adult",
        "name": "CleanBrowsing Adult Filter",
        "url": "https://doh.cleanbrowsing.org/doh/adult-filter/",
        "servers": ["185.228.168.10", "185.228.169.11", "2a0d:2a00:1::1", "2a0d:2a00:2::1"],
        "blurb": "Blokuje porno i wymusza bezpieczne wyszukiwanie w Google i Bing.",
    },
    {
        "slug": "adguard-family",
        "name": "AdGuard DNS Family",
        "url": "https://family.adguard-dns.com/dns-query",
        "servers": ["94.140.14.15", "94.140.15.16", "2a10:50c0::bad1:ff", "2a10:50c0::bad2:ff"],
        "blurb": "Blokuje porno, wymusza bezpieczne wyszukiwanie i tryb ograniczony YouTube.",
    },
    {
        "slug": "cloudflare-family",
        "name": "Cloudflare for Families",
        "url": "https://family.cloudflare-dns.com/dns-query",
        "servers": ["1.1.1.3", "1.0.0.3", "2606:4700:4700::1113", "2606:4700:4700::1003"],
        "blurb": "Blokuje porno i złośliwe strony.",
    },
]


def stable_uuid(name):
    return str(uuid.uuid5(NAMESPACE, name)).upper()


def profile(provider):
    identifier = f"pl.minimal.dns.{provider['slug']}"
    return {
        "PayloadContent": [
            {
                "DNSSettings": {
                    "DNSProtocol": "HTTPS",
                    "ServerURL": provider["url"],
                    "ServerAddresses": provider["servers"],
                    # iOS 26+: never fall back to the unfiltered system resolver.
                    "AllowFailover": False,
                },
                "PayloadDisplayName": f"{provider['name']} (DNS over HTTPS)",
                "PayloadIdentifier": f"{identifier}.dns",
                "PayloadType": "com.apple.dnsSettings.managed",
                "PayloadUUID": stable_uuid(identifier + ".dns"),
                "PayloadVersion": 1,
            }
        ],
        "PayloadDescription": (
            f"Szyfrowany rodzinny DNS ({provider['name']}) dla całego iPhone’a. "
            f"{provider['blurb']}"
        ),
        "PayloadDisplayName": f"Minimal · filtr DNS ({provider['name']})",
        "PayloadIdentifier": identifier,
        "PayloadOrganization": "Minimal",
        "PayloadRemovalDisallowed": False,
        "PayloadScope": "System",
        "PayloadType": "Configuration",
        "PayloadUUID": stable_uuid(identifier),
        "PayloadVersion": 1,
        "TargetDeviceType": 1,
    }


def main():
    OUT.mkdir(exist_ok=True)
    for provider in PROVIDERS:
        path = OUT / f"Minimal-DNS-{provider['slug']}.mobileconfig"
        with path.open("wb") as handle:
            plistlib.dump(profile(provider), handle, sort_keys=True)
        print(f"wrote {path.relative_to(OUT.parent)}")


if __name__ == "__main__":
    main()
