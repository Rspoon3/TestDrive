//
//  KudoboardLoginService.swift
//  Testing
//
//  Created by Ricky on 3/22/25.
//

import Foundation

final class KudoboardLoginService {
    private let baseURL = "https://www.kudoboard.com"
    private var cookies: [HTTPCookie] = []
    private(set) var csrfToken: String = ""
    private let extractor = CSRFTokenExtractor()
    
    // Store the cookies in a session configuration
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        return URLSession(configuration: configuration)
    }()
    
    // Step 1: Make GET request to login page to get cookies and CSRF token
    func getLoginPage() async throws {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KudoboardError.networkError("Invalid HTTP response")
        }
        
        // Extract cookies from response
        let responseCookies = httpResponse.allCookies()
        self.cookies.append(contentsOf: responseCookies)
        
        // Store cookies in the cookie storage
        HTTPCookieStorage.shared.setCookies(responseCookies, for: url, mainDocumentURL: nil)
        
        // Try to extract CSRF token from response data or cookies
        if let htmlString = String(data: data, encoding: .utf8), let token = extractor.extract(from: htmlString) {
            csrfToken = token
        }
        
        // Look for XSRF-TOKEN in cookies if not found in HTML
        if self.csrfToken.isEmpty {
            for cookie in responseCookies {
                if cookie.name == "XSRF-TOKEN" {
                    if let value = cookie.value.removingPercentEncoding {
                        self.csrfToken = value
                    }
                }
            }
        }
        
        print("GET request completed with status code: \(httpResponse.statusCode)")
        print("Cookies obtained: \(self.cookies.map { $0.name })")
        print("CSRF Token: \(self.csrfToken)")
        
        // Check if we have a token
        if self.csrfToken.isEmpty {
            throw KudoboardError.csrfTokenNotFound
        }
    }
    
    // Step 2: Make POST request to login
    func login(email: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue(csrfToken, forHTTPHeaderField: "X-CSRF-TOKEN")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("text/html,application/xhtml+xml,application/xml", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        // Add cookies to the request
        let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
        for (headerField, value) in cookieHeaders {
            request.setValue(value, forHTTPHeaderField: headerField)
        }
        
        // Prepare login data as form URL encoded (not JSON)
        let loginParams = [
            "email": email,
            "password": password,
            "remember": "1",
            "_token": csrfToken
        ]
        
        let bodyString = loginParams.map { key, value in
            return "\(key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"
        }.joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KudoboardError.networkError("Invalid HTTP response")
        }
        
        print("POST request completed with status code: \(httpResponse.statusCode)")
        
        // Handle the HTML response and extract cookies
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 302 else {
            throw KudoboardError.httpError(httpResponse.statusCode, "HTTP error")
        }
        
        let stringData = String(data: data, encoding: .utf8)
        print("POST request response: \(stringData?.prefix(200) ?? "No data returned")")
        
        // Extract new cookies from the response headers
        if let headerFields = httpResponse.allHeaderFields as? [String: String] {
            let newCookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            if !newCookies.isEmpty {
                self.cookies.append(contentsOf: newCookies)
                
                // Update CSRF token from new cookies
                for cookie in newCookies {
                    if cookie.name == "XSRF-TOKEN" {
                        self.csrfToken = cookie.value.removingPercentEncoding ?? cookie.value
                        print("✅ Updated CSRF token from login response: \(self.csrfToken)")
                    }
                }
                
                // Store cookies in the cookie storage
                HTTPCookieStorage.shared.setCookies(newCookies, for: url, mainDocumentURL: nil)
                print("✅ Updated cookies: \(newCookies.map { $0.name })")
            }
        }
        
        guard let responseHTML = stringData else {
            return
        }
        
        // Validate login success by checking for success indicators in the HTML
        // If we find indications of a successful login in the HTML
        if responseHTML.contains("logout") || responseHTML.contains("dashboard") ||
            !responseHTML.contains("Invalid credentials") {
            print("✅ Login appears successful based on response content")
        } else if responseHTML.contains("Invalid credentials") ||
                    responseHTML.contains("These credentials do not match our records") {
            throw KudoboardError.loginFailed("Invalid credentials")
        }
        
        // Also try to extract a new CSRF token from the HTML
        guard let token = extractor.extract(from: responseHTML) else { return }
        csrfToken = token
        print("✅ Updated CSRF token from HTML: \(self.csrfToken)")
    }
    
    // Step 3: Visit the board page to get a fresh CSRF token
    func visitBoardPage(boardID: String) async throws {
        let url = URL(string: "\(baseURL)/boards/\(boardID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add cookies to request
        let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
        for (headerField, value) in cookieHeaders {
            request.setValue(value, forHTTPHeaderField: headerField)
        }
        
        // Set up other headers for a typical browser request
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KudoboardError.networkError("Invalid HTTP response")
        }
        
        print("Board page visit completed with status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw KudoboardError.httpError(httpResponse.statusCode, "Failed to load board page")
        }
        // Update cookies from response
        let newCookies = httpResponse.allCookies()
        if !newCookies.isEmpty {
            self.cookies = newCookies
            HTTPCookieStorage.shared.setCookies(newCookies, for: url, mainDocumentURL: nil)
            
            // Update CSRF token from cookies
            if let xsrfCookie = newCookies.first(where: { $0.name == "XSRF-TOKEN" }) {
                self.csrfToken = xsrfCookie.value.removingPercentEncoding ?? xsrfCookie.value
                print("✅ Updated CSRF token from board page: \(self.csrfToken)")
            }
        }
        
        // Also try to extract CSRF token from HTML if available
        guard
            let htmlString = String(data: data, encoding: .utf8),
            let token = extractor.extract(from: htmlString)
        else {
            return
        }
        
        csrfToken = token
        print("✅ Updated CSRF token from HTML: \(self.csrfToken)")
    }
    
    // Step 4: Post kudo to the board
    func postKudo(to boardID: String, messageHTML: String) async throws {
        let boundary = "Boundary-\(UUID().uuidString)"
        let url = URL(string: "\(baseURL)/boards/\(boardID)/kudos/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Headers
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://www.kudoboard.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.kudoboard.com/boards/\(boardID)", forHTTPHeaderField: "Referer")
        
        // Add CSRF token both in header and as form field
        print("Using CSRF token for post: \(self.csrfToken)")
        request.setValue(self.csrfToken, forHTTPHeaderField: "X-CSRF-TOKEN")
        
        // Add all cookies from storage
        let cookieHeaders = HTTPCookie.requestHeaderFields(with: self.cookies)
        for (headerField, value) in cookieHeaders {
            request.setValue(value, forHTTPHeaderField: headerField)
        }
        
        // Debug logging
        print("Sending POST with cookies: \(self.cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; "))")
        
        // Body
        var body = Data()
        
        func appendFormField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Include the CSRF token as a form field (important for Laravel)
        appendFormField(name: "_token", value: self.csrfToken)
        appendFormField(name: "message", value: messageHTML)
        appendFormField(name: "recipients", value: "[]")
        appendFormField(name: "hashtags", value: "")
        appendFormField(name: "custom_fields", value: "{}")
        appendFormField(name: "is_private", value: "0")
        appendFormField(name: "has_user_created_gif", value: "0")
        appendFormField(name: "video_self_recorded", value: "0")
        appendFormField(name: "terms_of_service", value: "1")
        appendFormField(name: "is_orphan", value: "0")
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KudoboardError.networkError("Invalid HTTP response")
        }
        
        print("POST kudos completed with status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 302 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Success response: \(responseString)")
            }
        } else {
            let responseText = String(data: data, encoding: .utf8) ?? "No body"
            print("Failed response: \(responseText)")
            throw KudoboardError.httpError(httpResponse.statusCode, responseText)
        }
    }
}
