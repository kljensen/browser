# curl-impersonate Integration

## Summary of Changes

This PR replaces the standard libcurl with curl-impersonate to enable browser fingerprinting resistance. 
curl-impersonate is a special build of curl that can impersonate Chrome, Edge, Safari & Firefox browsers
by matching their TLS and HTTP/2 handshakes exactly.

## Changes Made

### 1. Submodule Replacement
- **File**: `.gitmodules`
- **Change**: Replaced the curl submodule URL from `https://github.com/curl/curl.git` to 
  `https://github.com/lwthiker/curl.git` (branch: `impersonate-chrome`)
- **Reason**: The curl-impersonate project maintains a fork of curl with patches for browser impersonation

### 2. HTTP Client Integration
- **File**: `src/http/Http.zig`
- **Change**: Added `curl_easy_impersonate(easy, "chrome116", 0)` call in `Connection.init()` 
  immediately after `curl_easy_init()`
- **Reason**: This configures the curl handle to impersonate Chrome 116, setting appropriate:
  - TLS version and cipher suites
  - TLS extensions (SNI, ALPN, etc.)
  - HTTP/2 settings and pseudo-headers order
  - Certificate compression and session ticket settings

### 3. Build Configuration
- **File**: `build.zig`
- **Change**: Added `root ++ "lib/impersonate.c"` to the curl source files list
- **Reason**: The curl-impersonate fork includes this new file that implements the impersonation logic

### 4. Testing
- **File**: `src/http/impersonate_test.zig` (new)
- **Changes**: Added three smoke tests:
  1. TLS fingerprint test - verifies HTTPS connections work with fingerprinting services
  2. HTTP/2 fingerprint test - verifies HTTP/2 connections work properly
  3. Library load test - ensures curl-impersonate loads without errors
- **Reason**: These tests validate that the browser impersonation is working correctly

### 5. Documentation
- **File**: `README.md`
- **Changes**:
  - Updated feature list to mention curl-impersonate instead of libcurl
  - Added explanation of browser fingerprinting feature
  - Added new "Browser Fingerprinting" section explaining TLS and HTTP/2 fingerprinting
- **Reason**: Users need to know about this important anti-detection feature

## Technical Details

### How curl-impersonate Works

curl-impersonate modifies curl's behavior in several ways:

1. **TLS Handshake**: Modifies the Client Hello message to match Chrome's exactly:
   - Cipher suites in the same order
   - TLS extensions in the same order with same values
   - Supported groups (elliptic curves)
   - Signature algorithms

2. **HTTP/2 Settings**: Configures HTTP/2 connection settings to match Chrome:
   - Window size
   - Max concurrent streams
   - Pseudo-headers order
   - ALPS (Application-Layer Protocol Settings)

3. **Additional Features**:
   - Certificate compression
   - TLS session tickets
   - Extension permutation to match Chrome's randomization

### API Usage

The key API function is:
```c
CURLcode curl_easy_impersonate(CURL *curl, const char *target, int default_headers);
```

Parameters:
- `curl`: The curl easy handle
- `target`: Browser to impersonate (e.g., "chrome116", "firefox117", "safari15_5")
- `default_headers`: 0 = don't set default headers (we manage headers ourselves)

This function internally calls `curl_easy_setopt()` multiple times to configure:
- `CURLOPT_HTTP_VERSION`
- `CURLOPT_SSLVERSION`
- `CURLOPT_SSL_CIPHER_LIST`
- `CURLOPT_SSL_EC_CURVES`
- `CURLOPT_SSL_ENABLE_ALPN`
- And several custom options added by curl-impersonate

### Supported Browsers

The curl-impersonate chrome branch supports:
- Chrome 99, 100, 101, 104, 107, 110, 116
- Edge 99, 101
- Safari 15.3, 15.5

We currently use **Chrome 116** as it's one of the most recent versions supported.

## Benefits

1. **Anti-Detection**: Websites using TLS fingerprinting can't distinguish Lightpanda from a real Chrome browser
2. **Reliability**: Reduces the chance of being blocked by anti-bot systems
3. **Better Scraping**: More successful web scraping and automation without detection
4. **API Compatibility**: Maintains full backward compatibility with standard curl API

## Testing

To test the changes:

1. Build the project: `make build`
2. Run all tests: `make test`
3. Run WPT tests: `make wpt`
4. Smoke test with a fingerprinting service:
   ```bash
   ./zig-out/bin/lightpanda fetch --dump https://tls.peet.ws/api/all
   ```

The output should show TLS characteristics matching Chrome 116.

## Known Limitations

1. While TLS and HTTP/2 fingerprints match Chrome, other aspects like:
   - JavaScript runtime fingerprinting (handled by V8 separately)
   - WebGL fingerprinting
   - Canvas fingerprinting
   - Font fingerprinting
   
   These are orthogonal concerns and not affected by this change.

2. The impersonation is static (Chrome 116). Future updates may want to:
   - Make the browser version configurable
   - Randomize between different browser versions
   - Update to newer Chrome versions as curl-impersonate adds support

## Future Improvements

1. Make browser impersonation configurable via command-line flag
2. Add metrics/logging for successful impersonation
3. Update to newer browser versions as they become available in curl-impersonate
4. Consider supporting Firefox impersonation for additional diversity

## References

- curl-impersonate repository: https://github.com/lwthiker/curl-impersonate
- TLS Fingerprinting explanation: https://lwthiker.com/networks/2022/06/17/tls-fingerprinting.html
- HTTP/2 Fingerprinting explanation: https://lwthiker.com/networks/2022/06/17/http2-fingerprinting.html
- Upstream curl fork (chrome): https://github.com/lwthiker/curl/tree/impersonate-chrome
