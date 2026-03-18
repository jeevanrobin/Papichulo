# Papichulo Code Review – Issues & Recommendations

## 1) External geocode calls can hang indefinitely
- **Where:** `backend/server.js` (`geocodeAddress`, `reverseGeocode`, `searchLocations`)
- **Problem:** `fetch` is used without timeouts/retries. If Google/OSM is slow or blocked, the request can hang, tying up the Node worker and delaying all callers.
- **Fix:** Wrap fetch with `AbortController` timeout (e.g., 5–8s) and add a small capped retry for transient failures; fail fast with a clear 5xx code.

## 2) Hard‑coded India bias for search results
- **Where:** `backend/server.js` (`searchLocations` sets `countryBias = 'in'`)
- **Problem:** Blocks users outside India and prevents cross‑border address entry; also makes automated tests location‑dependent.
- **Fix:** Make country bias configurable via environment variable or request param; default to no restriction.

## 3) OpenStreetMap tiles used without attribution/rate‑limit plan
- **Where:** `lib/screens/home/location_picker_sheet.dart` (`_showMapPinDialog` `TileLayer`)
- **Problem:** OSM requires attribution and discourages hitting the public tile server from production apps; risk of being blocked and licensing non‑compliance.
- **Fix:** Add proper attribution text; move tile URL to config and use an account/keyed tile provider or self‑hosted tiles with caching.

## 4) Header search icon is non‑functional
- **Where:** `lib/screens/home/home_screen.dart` (`_focusSearch` only scrolls)
- **Problem:** Clicking search does nothing useful; users can’t focus/type search from the header.
- **Fix:** Wire the icon to a `FocusNode` on the search field (or open a search sheet). Remove until functional if not planned.

## 5) Saved addresses load asynchronously without gating UI
- **Where:** `lib/main.dart` (`AddressService.instance.loadAddresses()` not awaited)
- **Problem:** Header shows “Set location” on first frame even when a saved address exists; may trigger extra geolocation prompts and flicker.
- **Fix:** Await address loading before `runApp` (or gate with a splash/FutureBuilder) so initial UI reflects saved state.

## 6) High‑accuracy geolocation requested on web every mount
- **Where:** `lib/screens/home/home_screen.dart` (`_detectHeaderLocation` uses `LocationAccuracy.high`, no throttling)
- **Problem:** On web, high accuracy can be slow, battery‑heavy, and repeatedly prompt the user; adds latency to header render.
- **Fix:** Use `LocationAccuracy.medium` for header chip, cache last known location, and skip repeat requests within a session unless user taps “Use current location.”

## 7) Error feedback from API client is vague
- **Where:** `lib/services/order_api_service.dart` → `ApiClient.request`
- **Problem:** Network failures collapse into “Unable to reach backend” without status/path; hard to debug and handle correctly. No retry for idempotent GETs.
- **Fix:** Include status code/path in thrown errors; add limited retry for GET; surface user‑friendly messages (e.g., “Delivery service unavailable, retrying…”).

## 8) Checkout blocked when geocode backend unavailable
- **Where:** `lib/screens/cart/cart_drawer.dart` (`_showCheckoutDialog`, address field `readOnly`, requires reverse geocode/map)
- **Problem:** If geocode fails, users cannot type an address because the field is read‑only; order flow is hard‑blocked.
- **Fix:** Allow manual address entry when geocode fails or when user toggles “Enter address manually”; cache last `deliveryConfig` to avoid repeat fetch failures.

## 9) Minor code quality nits (duplicate imports)
- **Where:** `lib/screens/home/set_delivery_location_dialog.dart`, `lib/screens/home/home_header_widgets.dart` (double `flutter/material.dart` import)
- **Problem:** Noise and tiny hot‑reload overhead; lowers clarity.
- **Fix:** Remove duplicate imports.

