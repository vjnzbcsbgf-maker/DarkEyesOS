// DarkEyesOS — enforced Tor Browser hardening overrides.
// Applied on top of the OFFICIAL Tor Browser (we do not fork it). Goal: default
// to the "Safest" posture and shut common leak/fingerprint vectors, WITHOUT
// breaking the shared-fingerprint anonymity set that keeps Tor users uniform.
// Keep this conservative: over-customizing a browser makes you MORE unique.

// ---- Security level = Safest (disables JIT, JS on non-HTTPS, etc.) ----
user_pref("browser.security_level.security_slider", 1);
user_pref("extensions.torbutton.security_slider", 1);

// ---- Anti-fingerprinting (already on upstream; enforce it) ----
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.resistFingerprinting.letterboxing", true);

// ---- Kill high-risk APIs ----
user_pref("webgl.disable", true);
user_pref("media.peerconnection.enabled", false);   // WebRTC (IP leak vector)
user_pref("media.navigator.enabled", false);
user_pref("dom.webaudio.enabled", false);
user_pref("media.eme.enabled", false);              // DRM
user_pref("media.gmp-widevinecdm.enabled", false);
user_pref("dom.event.clipboardevents.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("device.sensors.enabled", false);
user_pref("geo.enabled", false);

// ---- No disk traces (amnesic) ----
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.offline.enable", false);
user_pref("browser.sessionstore.privacy_level", 2);
user_pref("browser.privatebrowsing.autostart", true);
user_pref("places.history.enabled", false);
user_pref("signon.rememberSignons", false);
user_pref("browser.formfill.enable", false);

// ---- Telemetry / phone-home off ----
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("browser.ping-centre.telemetry", false);
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.predictor.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);

// ---- HTTPS-only ----
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_ever_enabled", true);

// ---- Safer downloads ----
user_pref("browser.download.manager.addToRecentDocs", false);
