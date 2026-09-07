// DarkEyesOS I2P Browser — hardened Firefox ESR prefs, wired to the I2P proxy.
// Conservative hardening (like our Tor Browser policy) without breaking I2P.

// ---- Route everything through the I2P HTTP proxy (i2pd 127.0.0.1:4444) ----
user_pref("network.proxy.type", 1);
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", 4444);
user_pref("network.proxy.ssl", "127.0.0.1");
user_pref("network.proxy.ssl_port", 4444);
user_pref("network.proxy.share_proxy_settings", true);
// Resolve hostnames through the proxy (no clearnet DNS leak for .i2p).
user_pref("network.proxy.socks_remote_dns", true);
user_pref("network.proxy.no_proxies_on", "");
// Do not fall back to a direct connection if the proxy fails (fail-closed).
user_pref("network.proxy.failover_direct", false);
user_pref("network.proxy.allow_hijacking_localhost", true);

// ---- Anti-fingerprinting / privacy ----
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.firstparty.isolate", true);
user_pref("webgl.disable", true);
user_pref("media.peerconnection.enabled", false);   // WebRTC off (IP leak)
user_pref("geo.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("beacon.enabled", false);

// ---- No disk traces (amnesic) ----
user_pref("browser.cache.disk.enable", false);
user_pref("browser.privatebrowsing.autostart", true);
user_pref("places.history.enabled", false);
user_pref("signon.rememberSignons", false);

// ---- Telemetry / phone-home off ----
user_pref("toolkit.telemetry.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.predictor.enabled", false);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.startup.homepage", "http://127.0.0.1:7070");  // i2pd console
user_pref("browser.captivePortal.enabled", false);
user_pref("network.captive-portal-service.enabled", false);
