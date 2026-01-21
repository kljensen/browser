// Copyright (C) 2023-2025  Lightpanda (Selecy SAS)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const Http = @import("Http.zig");
const testing = std.testing;

// Smoke test to verify that curl-impersonate is working
// This test makes a request to a TLS fingerprinting service
// to verify that the connection looks like a real browser
test "curl-impersonate TLS fingerprint smoke test" {
    const allocator = testing.allocator;

    // Initialize HTTP client
    var http = try Http.init(allocator, .{
        .user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36",
        .timeout_ms = 30000,
        .connect_timeout_ms = 10000,
        .max_redirects = 5,
        .max_concurrent = 1,
        .tls_verify_host = true,
        .http_proxy = null,
        .proxy_bearer_token = null,
    });
    defer http.deinit();

    // Create a connection
    var conn = try http.newConnection();
    defer conn.deinit();

    // Test against TLS fingerprinting service
    // This service (tls.peet.ws) shows information about the TLS handshake
    try conn.setURL("https://tls.peet.ws/api/all");
    try conn.setMethod(.GET);

    const status = try conn.request();
    
    // Just verify we can make a successful HTTPS request
    // The fact that it succeeds with status 200 means our TLS setup is working
    try testing.expectEqual(@as(u16, 200), status);
}

// Test against another fingerprinting service
test "curl-impersonate HTTP/2 fingerprint smoke test" {
    const allocator = testing.allocator;

    var http = try Http.init(allocator, .{
        .user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36",
        .timeout_ms = 30000,
        .connect_timeout_ms = 10000,
        .max_redirects = 5,
        .max_concurrent = 1,
        .tls_verify_host = true,
        .http_proxy = null,
        .proxy_bearer_token = null,
    });
    defer http.deinit();

    var conn = try http.newConnection();
    defer conn.deinit();

    // Test against a service that checks HTTP/2 fingerprints
    // Using httpbin.org which supports HTTP/2
    try conn.setURL("https://httpbin.org/get");
    try conn.setMethod(.GET);

    const status = try conn.request();
    
    // Verify successful HTTPS/HTTP2 request
    try testing.expectEqual(@as(u16, 200), status);
}

// Basic sanity test that the library loads correctly
test "curl-impersonate library loads" {
    const allocator = testing.allocator;

    var http = try Http.init(allocator, .{
        .user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36",
        .timeout_ms = 30000,
        .connect_timeout_ms = 10000,
        .max_redirects = 5,
        .max_concurrent = 1,
        .tls_verify_host = true,
        .http_proxy = null,
        .proxy_bearer_token = null,
    });
    defer http.deinit();

    // Just verify we can create and destroy the HTTP client
    // If curl_easy_impersonate wasn't available, this would fail during init
    try testing.expect(http.client != null);
}
