//
//  TwitterManager.swift
//  TwitterMessenger
//
//  Created by Jongwhan Lee on 26/07/2017.
//  Copyright © 2017 Jongwhan Lee. All rights reserved.
//

import Foundation
import Dispatch
import Accounts
import Social
import UIKit
import SafariServices


extension Data {
    
    var rawBytes: [UInt8] {
        return [UInt8](self)
    }
    
    init(bytes: [UInt8]) {
        self.init(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
    }
    
    mutating func append(_ bytes: [UInt8]) {
        self.append(UnsafePointer<UInt8>(bytes), count: bytes.count)
    }
    
}


extension Dictionary {
    
    func filter(_ predicate: (Element) -> Bool) -> Dictionary {
        var filteredDictionary = Dictionary()
        for element in self where predicate(element) {
            filteredDictionary[element.key] = element.value
        }
        return filteredDictionary
    }
    
    var queryString: String {
        var parts = [String]()
        
        for (key, value) in self {
            let query: String = "\(key)=\(value)"
            parts.append(query)
        }
        
        return parts.joined(separator: "&")
    }
    
    func urlEncodedQueryString(using encoding: String.Encoding) -> String {
        var parts = [String]()
        
        for (key, value) in self {
            let keyString = "\(key)".urlEncodedString()
            let valueString = "\(value)".urlEncodedString(keyString == "status")
            let query: String = "\(keyString)=\(valueString)"
            parts.append(query)
        }
        
        return parts.joined(separator: "&")
    }
    
    func stringifiedDictionary() -> Dictionary<String, String> {
        var dict = [String: String]()
        for (key, value) in self {
            dict[String(describing: key)] = String(describing: value)
        }
        return dict
    }
    
}

infix operator +|

func +| <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>) -> Dictionary<K,V> {
    var map = Dictionary<K,V>()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        map[k] = v
    }
    return map
}



public struct HMAC {
    
    internal static func sha1(key: Data, message: Data) -> Data? {
        var key = key.rawBytes
        let message = message.rawBytes
        
        // key
        if key.count > 64 {
            key = SHA1(message: Data(bytes: key)).calculate().rawBytes
        }
        
        if (key.count < 64) {
            key = key + [UInt8](repeating: 0, count: 64 - key.count)
        }
        
        //
        var opad = [UInt8](repeating: 0x5c, count: 64)
        for (idx, _) in key.enumerated() {
            opad[idx] = key[idx] ^ opad[idx]
        }
        var ipad = [UInt8](repeating: 0x36, count: 64)
        for (idx, _) in key.enumerated() {
            ipad[idx] = key[idx] ^ ipad[idx]
        }
        
        let ipadAndMessageHash = SHA1(message: Data(bytes: (ipad + message))).calculate().rawBytes
        let finalHash = SHA1(message: Data(bytes: opad + ipadAndMessageHash)).calculate().rawBytes
        let mac = finalHash
        
        return Data(bytes: UnsafePointer<UInt8>(mac), count: mac.count)
        
    }
    
}


public enum JSON : Equatable, CustomStringConvertible {
    
    case string(String)
    case number(Double)
    case object(Dictionary<String, JSON>)
    case array(Array<JSON>)
    case bool(Bool)
    case null
    case invalid
    
    public init(_ rawValue: Any) {
        switch rawValue {
        case let json as JSON:
            self = json
            
        case let array as [JSON]:
            self = .array(array)
            
        case let dict as [String: JSON]:
            self = .object(dict)
            
        case let data as Data:
            do {
                let object = try JSONSerialization.jsonObject(with: data, options: [])
                self = JSON(object)
            } catch {
                self = .invalid
            }
            
        case let array as [Any]:
            let newArray = array.map { JSON($0) }
            self = .array(newArray)
            
        case let dict as [String: Any]:
            var newDict = [String: JSON]()
            for (key, value) in dict {
                newDict[key] = JSON(value)
            }
            self = .object(newDict)
            
        case let string as String:
            self = .string(string)
            
        case let number as NSNumber:
            self = number.isBoolean ? .bool(number.boolValue) : .number(number.doubleValue)
            
        case _ as Optional<Any>:
            self = .null
            
        default:
            assert(true, "This location should never be reached")
            self = .invalid
        }
        
    }
    
    public var string : String? {
        guard case .string(let value) = self else {
            return nil
        }
        return value
    }
    
    public var integer : Int? {
        guard case .number(let value) = self else {
            return nil
        }
        return Int(value)
    }
    
    public var double : Double? {
        guard case .number(let value) = self else {
            return nil
        }
        return value
    }
    
    public var object : [String: JSON]? {
        guard case .object(let value) = self else {
            return nil
        }
        return value
    }
    
    public var array : [JSON]? {
        guard case .array(let value) = self else {
            return nil
        }
        return value
    }
    
    public var bool : Bool? {
        guard case .bool(let value) = self else {
            return nil
        }
        return value
    }
    
    public subscript(key: String) -> JSON {
        guard case .object(let dict) = self, let value = dict[key] else {
            return .invalid
        }
        return value
    }
    
    public subscript(index: Int) -> JSON {
        guard case .array(let array) = self, array.count > index else {
            return .invalid
        }
        return array[index]
    }
    
    static func parse(jsonData: Data) throws -> JSON {
        do {
            let object = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            return JSON(object)
        } catch {
            throw SwifterError(message: "\(error)", kind: .jsonParseError)
        }
    }
    
    static func parse(string : String) throws -> JSON {
        do {
            guard let data = string.data(using: .utf8, allowLossyConversion: false) else {
                throw SwifterError(message: "Cannot parse invalid string", kind: .jsonParseError)
            }
            return try parse(jsonData: data)
        } catch {
            throw SwifterError(message: "\(error)", kind: .jsonParseError)
        }
    }
    
    func stringify(_ indent: String = "  ") -> String? {
        guard self != .invalid else {
            assert(true, "The JSON value is invalid")
            return nil
        }
        return prettyPrint(indent, 0)
    }
    
    public var description: String {
        guard let string = stringify() else {
            return "<INVALID JSON>"
        }
        return string
    }
    
    private func prettyPrint(_ indent: String, _ level: Int) -> String {
        let currentIndent = (0...level).map({ _ in "" }).joined(separator: indent)
        let nextIndent = currentIndent + "  "
        
        switch self {
        case .bool(let bool):
            return bool ? "true" : "false"
            
        case .number(let number):
            return "\(number)"
            
        case .string(let string):
            return "\"\(string)\""
            
        case .array(let array):
            return "[\n" + array.map { "\(nextIndent)\($0.prettyPrint(indent, level + 1))" }.joined(separator: ",\n") + "\n\(currentIndent)]"
            
        case .object(let dict):
            return "{\n" + dict.map { "\(nextIndent)\"\($0)\" : \($1.prettyPrint(indent, level + 1))"}.joined(separator: ",\n") + "\n\(currentIndent)}"
            
        case .null:
            return "null"
            
        case .invalid:
            assert(true, "This should never be reached")
            return ""
        }
    }
    
}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null):
        return true
        
    case (.bool(let lhsValue), .bool(let rhsValue)):
        return lhsValue == rhsValue
        
    case (.string(let lhsValue), .string(let rhsValue)):
        return lhsValue == rhsValue
        
    case (.number(let lhsValue), .number(let rhsValue)):
        return lhsValue == rhsValue
        
    case (.array(let lhsValue), .array(let rhsValue)):
        return lhsValue == rhsValue
        
    case (.object(let lhsValue), .object(let rhsValue)):
        return lhsValue == rhsValue
        
    default:
        return false
    }
}



extension JSON: ExpressibleByStringLiteral,
    ExpressibleByIntegerLiteral,
    ExpressibleByBooleanLiteral,
    ExpressibleByFloatLiteral,
    ExpressibleByArrayLiteral,
    ExpressibleByDictionaryLiteral,
ExpressibleByNilLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
    
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
    
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
    
    public init(dictionaryLiteral elements: (String, Any)...) {
        let object = elements.reduce([String: Any]()) { $0 + [$1.0: $1.1] }
        self.init(object)
    }
    
    public init(arrayLiteral elements: AnyObject...) {
        self.init(elements)
    }
    
    public init(nilLiteral: ()) {
        self.init(NSNull())
    }
    
}

private func +(lhs: [String: Any], rhs: [String: Any]) -> [String: Any] {
    var lhs = lhs
    for element in rhs {
        lhs[element.key] = element.value
    }
    return lhs
}

private extension NSNumber {
    
    var isBoolean: Bool {
        return NSNumber(value: true).objCType == self.objCType
    }
}

/// If `rhs` is not `nil`, assign it to `lhs`.
infix operator ??= : AssignmentPrecedence // { associativity right precedence 90 assignment } // matches other assignment operators

/// If `rhs` is not `nil`, assign it to `lhs`.
func ??=<T>(lhs: inout T?, rhs: T?) {
    guard let rhs = rhs else { return }
    lhs = rhs
}

extension Scanner {
    #if os(macOS) || os(iOS)
    func scanString(string: String) -> String? {
        var buffer: NSString?
        scanString(string, into: &buffer)
        return buffer as String?
    }
    func scanUpToString(_ string: String) -> String? {
        var buffer: NSString?
        scanUpTo(string, into: &buffer)
        return buffer as String?
    }
    #endif
    
    #if os(Linux)
    var isAtEnd: Bool {
    // This is the same check being done inside NSScanner.swift to
    // determine if the scanner is at the end.
    return scanLocation == string.utf16.count
    }
    #endif
}



struct SHA1 {
    
    var message: Data
    
    /** Common part for hash calculation. Prepare header data. */
    func prepare(_ len:Int = 64) -> Data {
        var tmpMessage: Data = self.message
        
        // Step 1. Append Padding Bits
        tmpMessage.append([0x80]) // append one bit (Byte with one bit) to message
        
        // append "0" bit until message length in bits ≡ 448 (mod 512)
        while tmpMessage.count % len != (len - 8) {
            tmpMessage.append([0x00])
        }
        
        return tmpMessage
    }
    
    func calculate() -> Data {
        
        //var tmpMessage = self.prepare()
        let len = 64
        let h: [UInt32] = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]
        
        var tmpMessage: Data = self.message
        
        // Step 1. Append Padding Bits
        tmpMessage.append([0x80]) // append one bit (Byte with one bit) to message
        
        // append "0" bit until message length in bits ≡ 448 (mod 512)
        while tmpMessage.count % len != (len - 8) {
            tmpMessage.append([0x00])
        }
        
        // hash values
        var hh = h
        
        // append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
        tmpMessage.append((self.message.count * 8).bytes(64 / 8))
        
        // Process the message in successive 512-bit chunks:
        let chunkSizeBytes = 512 / 8 // 64
        var leftMessageBytes = tmpMessage.count
        var i = 0;
        while i < tmpMessage.count {
            
            let chunk = tmpMessage.subdata(in: i..<i+min(chunkSizeBytes, leftMessageBytes))
            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
            // Extend the sixteen 32-bit words into eighty 32-bit words:
            var M = [UInt32](repeating: 0, count: 80)
            for x in 0..<M.count {
                switch (x) {
                case 0...15:
                    let le: UInt32 = chunk.withUnsafeBytes { $0[x] }
                    M[x] = le.bigEndian
                    break
                default:
                    M[x] = rotateLeft(M[x-3] ^ M[x-8] ^ M[x-14] ^ M[x-16], n: 1)
                    break
                }
            }
            
            var A = hh[0], B = hh[1], C = hh[2], D = hh[3], E = hh[4]
            
            // Main loop
            for j in 0...79 {
                var f: UInt32 = 0
                var k: UInt32 = 0
                
                switch j {
                case 0...19:
                    f = (B & C) | ((~B) & D)
                    k = 0x5A827999
                    break
                case 20...39:
                    f = B ^ C ^ D
                    k = 0x6ED9EBA1
                    break
                case 40...59:
                    f = (B & C) | (B & D) | (C & D)
                    k = 0x8F1BBCDC
                    break
                case 60...79:
                    f = B ^ C ^ D
                    k = 0xCA62C1D6
                    break
                default:
                    break
                }
                
                let temp = (rotateLeft(A,n: 5) &+ f &+ E &+ M[j] &+ k) & 0xffffffff
                E = D
                D = C
                C = rotateLeft(B, n: 30)
                B = A
                A = temp
                
            }
            
            hh[0] = (hh[0] &+ A) & 0xffffffff
            hh[1] = (hh[1] &+ B) & 0xffffffff
            hh[2] = (hh[2] &+ C) & 0xffffffff
            hh[3] = (hh[3] &+ D) & 0xffffffff
            hh[4] = (hh[4] &+ E) & 0xffffffff
            
            i = i + chunkSizeBytes
            leftMessageBytes -= chunkSizeBytes
        }
        
        // Produce the final hash value (big-endian) as a 160 bit number:
        var mutableBuff = Data()
        hh.forEach {
            var i = $0.bigEndian
            let numBytes = MemoryLayout.size(ofValue: i) / MemoryLayout<UInt8>.size
            withUnsafePointer(to: &i) { ptr in
                ptr.withMemoryRebound(to: UInt8.self, capacity: numBytes) { ptr in
                    let buffer = UnsafeBufferPointer(start: ptr,
                                                     count: numBytes)
                    mutableBuff.append(buffer)
                }
            }
        }
        
        return mutableBuff
    }
}


extension String {
    
    internal func indexOf(_ sub: String) -> Int? {
        guard let range = self.range(of: sub), !range.isEmpty else {
            return nil
        }
        return self.characters.distance(from: self.startIndex, to: range.lowerBound)
    }
    
    internal subscript (r: Range<Int>) -> String {
        get {
            let startIndex = self.characters.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.characters.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
            return self[startIndex..<endIndex]
        }
    }
    
    
    func urlEncodedString(_ encodeAll: Bool = false) -> String {
        var allowedCharacterSet: CharacterSet = .urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\n:#/?@!$&'()*+,;=")
        if !encodeAll {
            allowedCharacterSet.insert(charactersIn: "[]")
        }
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
    
    var queryStringParameters: Dictionary<String, String> {
        var parameters = Dictionary<String, String>()
        
        let scanner = Scanner(string: self)
        
        var key: String?
        var value: String?
        
        while !scanner.isAtEnd {
            key = scanner.scanUpToString("=")
            _ = scanner.scanString(string: "=")
            
            value = scanner.scanUpToString("&")
            _ = scanner.scanString(string: "&")
            
            if let key = key, let value = value {
                parameters.updateValue(value, forKey: key)
            }
        }
        
        return parameters
    }
}



extension Notification.Name {
    static let SwifterCallbackNotification: Notification.Name = Notification.Name(rawValue: "SwifterCallbackNotificationName")
}

// MARK: - Twitter URL
public enum TwitterURL {
    case api
    case upload
    case stream
    case userStream
    case siteStream
    case oauth
    
    var url: URL {
        switch self {
        case .api:          return URL(string: "https://api.twitter.com/1.1/")!
        case .upload:       return URL(string: "https://upload.twitter.com/1.1/")!
        case .stream:       return URL(string: "https://stream.twitter.com/1.1/")!
        case .userStream:   return URL(string: "https://userstream.twitter.com/1.1/")!
        case .siteStream:   return URL(string: "https://sitestream.twitter.com/1.1/")!
        case .oauth:        return URL(string: "https://api.twitter.com/")!
        }
    }
    
}

public class Swifter {
    
    // MARK: - Types
    
    public typealias SuccessHandler = (JSON) -> Void
    public typealias CursorSuccessHandler = (JSON, _ previousCursor: String?, _ nextCursor: String?) -> Void
    public typealias JSONSuccessHandler = (JSON, _ response: HTTPURLResponse) -> Void
    public typealias FailureHandler = (_ error: Error) -> Void
    
    internal struct CallbackNotification {
        static let optionsURLKey = "SwifterCallbackNotificationOptionsURLKey"
    }
    
    internal struct DataParameters {
        static let dataKey = "SwifterDataParameterKey"
        static let fileNameKey = "SwifterDataParameterFilename"
    }
    
    // MARK: - Properties
    
    public var client: SwifterClientProtocol
    
    // MARK: - Initializers
    
    public init(consumerKey: String, consumerSecret: String, appOnly: Bool = false) {
        self.client = appOnly
            ? AppOnlyClient(consumerKey: consumerKey, consumerSecret: consumerSecret)
            : OAuthClient(consumerKey: consumerKey, consumerSecret: consumerSecret)
    }
    
    public init(consumerKey: String, consumerSecret: String, oauthToken: String, oauthTokenSecret: String) {
        self.client = OAuthClient(consumerKey: consumerKey, consumerSecret: consumerSecret , accessToken: oauthToken, accessTokenSecret: oauthTokenSecret)
    }
    
    #if os(macOS) || os(iOS)
    public init(account: ACAccount) {
        self.client = AccountsClient(account: account)
    }
    #endif
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - JSON Requests
    
    @discardableResult
    internal func jsonRequest(path: String, baseURL: TwitterURL, method: HTTPMethodType, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler? = nil, downloadProgress: JSONSuccessHandler? = nil, success: JSONSuccessHandler? = nil, failure: HTTPRequest.FailureHandler? = nil) -> HTTPRequest {
        let jsonDownloadProgressHandler: HTTPRequest.DownloadProgressHandler = { data, _, _, response in
            
            guard let _ = downloadProgress else { return }
            
            guard let jsonResult = try? JSON.parse(jsonData: data) else {
                let jsonString = String(data: data, encoding: .utf8)
                let jsonChunks = jsonString!.components(separatedBy: "\r\n")
                
                for chunk in jsonChunks where !chunk.utf16.isEmpty {
                    guard let chunkData = chunk.data(using: .utf8), let jsonResult = try? JSON.parse(jsonData: chunkData) else { continue }
                    downloadProgress?(jsonResult, response)
                }
                return
            }
            
            downloadProgress?(jsonResult, response)
        }
        
        let jsonSuccessHandler: HTTPRequest.SuccessHandler = { data, response in
            
            DispatchQueue.global(qos: .utility).async {
                do {
                    let jsonResult = try JSON.parse(jsonData: data)
                    DispatchQueue.main.async {
                        success?(jsonResult, response)
                    }
                } catch {
                    DispatchQueue.main.async {
                        failure?(error)
                    }
                }
            }
        }
        
        if method == .GET {
            return self.client.get(path, baseURL: baseURL, parameters: parameters, uploadProgress: uploadProgress, downloadProgress: jsonDownloadProgressHandler, success: jsonSuccessHandler, failure: failure)
        } else {
            return self.client.post(path, baseURL: baseURL, parameters: parameters, uploadProgress: uploadProgress, downloadProgress: jsonDownloadProgressHandler, success: jsonSuccessHandler, failure: failure)
        }
    }
    
    @discardableResult
    internal func getJSON(path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler? = nil, downloadProgress: JSONSuccessHandler? = nil, success: JSONSuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        return self.jsonRequest(path: path, baseURL: baseURL, method: .GET, parameters: parameters, uploadProgress: uploadProgress, downloadProgress: downloadProgress, success: success, failure: failure)
    }
    
    @discardableResult
    internal func postJSON(path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler? = nil, downloadProgress: JSONSuccessHandler? = nil, success: JSONSuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        return self.jsonRequest(path: path, baseURL: baseURL, method: .POST, parameters: parameters, uploadProgress: uploadProgress, downloadProgress: downloadProgress, success: success, failure: failure)
    }
    
}


internal class AccountsClient: SwifterClientProtocol {
    
    var credential: Credential?
    
    init(account: ACAccount) {
        self.credential = Credential(account: account)
    }
    
    func get(_ path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler?, downloadProgress: HTTPRequest.DownloadProgressHandler?, success: HTTPRequest.SuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)
        
        let stringifiedParameters = parameters.stringifiedDictionary()
        
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, url: url, parameters: stringifiedParameters)!
        socialRequest.account = self.credential!.account!
        
        let request = HTTPRequest(request: socialRequest.preparedURLRequest())
        request.parameters = parameters
        request.downloadProgressHandler = downloadProgress
        request.successHandler = success
        request.failureHandler = failure
        
        request.start()
        return request
    }
    
    func post(_ path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler?, downloadProgress: HTTPRequest.DownloadProgressHandler?, success: HTTPRequest.SuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)
        
        var params = parameters
        
        var postData: Data?
        var postDataKey: String?
        
        if let keyString = params[Swifter.DataParameters.dataKey] as? String {
            postDataKey = keyString
            postData = params[postDataKey!] as? Data
            
            params.removeValue(forKey: Swifter.DataParameters.dataKey)
            params.removeValue(forKey: postDataKey!)
        }
        
        var postDataFileName: String?
        if let fileName = params[Swifter.DataParameters.fileNameKey] as? String {
            postDataFileName = fileName
            params.removeValue(forKey: fileName)
        }
        
        let stringifiedParameters = params.stringifiedDictionary()
        
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: url, parameters: stringifiedParameters)!
        socialRequest.account = self.credential!.account!
        
        if let data = postData {
            let fileName = postDataFileName ?? "media.jpg"
            socialRequest.addMultipartData(data, withName: postDataKey!, type: "application/octet-stream", filename: fileName)
        }
        
        let request = HTTPRequest(request: socialRequest.preparedURLRequest())
        request.parameters = parameters
        request.downloadProgressHandler = downloadProgress
        request.successHandler = success
        request.failureHandler = failure
        
        request.start()
        return request
    }
    
}


internal class AppOnlyClient: SwifterClientProtocol  {
    
    var consumerKey: String
    var consumerSecret: String
    
    var credential: Credential?
    
    let dataEncoding: String.Encoding = .utf8
    
    init(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }
    
    func get(_ path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler?, downloadProgress: HTTPRequest.DownloadProgressHandler?, success: HTTPRequest.SuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)
        
        let request = HTTPRequest(url: url!, method: .GET, parameters: parameters)
        request.downloadProgressHandler = downloadProgress
        request.successHandler = success
        request.failureHandler = failure
        request.dataEncoding = self.dataEncoding
        
        if let bearerToken = self.credential?.accessToken?.key {
            request.headers = ["Authorization": "Bearer \(bearerToken)"];
        }
        
        request.start()
        return request
    }
    
    func post(_ path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler?, downloadProgress: HTTPRequest.DownloadProgressHandler?, success: HTTPRequest.SuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)
        
        let request = HTTPRequest(url: url!, method: .POST, parameters: parameters)
        request.downloadProgressHandler = downloadProgress
        request.successHandler = success
        request.failureHandler = failure
        request.dataEncoding = self.dataEncoding
        
        if let bearerToken = self.credential?.accessToken?.key {
            request.headers = ["Authorization": "Bearer \(bearerToken)"];
        } else {
            let basicCredentials = AppOnlyClient.base64EncodedCredentials(withKey: self.consumerKey, secret: self.consumerSecret)
            request.headers = ["Authorization": "Basic \(basicCredentials)"];
            request.encodeParameters = true
        }
        
        request.start()
        return request
    }
    
    class func base64EncodedCredentials(withKey key: String, secret: String) -> String {
        let encodedKey = key.urlEncodedString()
        let encodedSecret = secret.urlEncodedString()
        let bearerTokenCredentials = "\(encodedKey):\(encodedSecret)"
        guard let data = bearerTokenCredentials.data(using: .utf8) else {
            return ""
        }
        return data.base64EncodedString(options: [])
    }
    
}



public extension Swifter {
    
    public typealias TokenSuccessHandler = (Credential.OAuthAccessToken?, URLResponse) -> Void
    
    /**
     Begin Authorization with a Callback URL.
     - OS X only
     */
    #if os(macOS)
    public func authorize(with callbackURL: URL, success: TokenSuccessHandler?, failure: FailureHandler? = nil) {
    self.postOAuthRequestToken(with: callbackURL, success: { token, response in
    var requestToken = token!
    
    NotificationCenter.default.addObserver(forName: .SwifterCallbackNotification, object: nil, queue: .main) { notification in
    NotificationCenter.default.removeObserver(self)
    let url = notification.userInfo![CallbackNotification.optionsURLKey] as! URL
    let parameters = url.query!.queryStringParameters
    requestToken.verifier = parameters["oauth_verifier"]
    
    self.postOAuthAccessToken(with: requestToken, success: { accessToken, response in
    self.client.credential = Credential(accessToken: accessToken!)
    success?(accessToken!, response)
    }, failure: failure)
    }
    
    let authorizeURL = URL(string: "oauth/authorize", relativeTo: TwitterURL.oauth.url)
    let queryURL = URL(string: authorizeURL!.absoluteString + "?oauth_token=\(token!.key)")!
    NSWorkspace.shared().open(queryURL)
    }, failure: failure)
    }
    #endif
    
    /**
     Begin Authorization with a Callback URL
     
     - Parameter presentFromViewController: The viewController used to present the SFSafariViewController.
     The UIViewController must inherit SFSafariViewControllerDelegate
     
     */
    
    #if os(iOS)
    public func authorize(with callbackURL: URL, presentFrom presentingViewController: UIViewController? , success: TokenSuccessHandler?, failure: FailureHandler? = nil) {
        self.postOAuthRequestToken(with: callbackURL, success: { token, response in
            var requestToken = token!
            NotificationCenter.default.addObserver(forName: .SwifterCallbackNotification, object: nil, queue: .main) { notification in
                NotificationCenter.default.removeObserver(self)
                presentingViewController?.presentedViewController?.dismiss(animated: true, completion: nil)
                let url = notification.userInfo![CallbackNotification.optionsURLKey] as! URL
                
                let parameters = url.query!.queryStringParameters
                requestToken.verifier = parameters["oauth_verifier"]
                
                self.postOAuthAccessToken(with: requestToken, success: { accessToken, response in
                    self.client.credential = Credential(accessToken: accessToken!)
                    success?(accessToken!, response)
                }, failure: failure)
            }
            
            let authorizeURL = URL(string: "oauth/authorize", relativeTo: TwitterURL.oauth.url)
            let queryURL = URL(string: authorizeURL!.absoluteString + "?oauth_token=\(token!.key)")!
            
            if #available(iOS 9.0, *) , let delegate = presentingViewController as? SFSafariViewControllerDelegate {
                let safariView = SFSafariViewController(url: queryURL)
                safariView.delegate = delegate
                presentingViewController?.present(safariView, animated: true, completion: nil)
            } else {
                UIApplication.shared.openURL(queryURL)
            }
        }, failure: failure)
    }
    #endif
    
    public class func handleOpenURL(_ url: URL) {
        let notification = Notification(name: .SwifterCallbackNotification, object: nil, userInfo: [CallbackNotification.optionsURLKey: url])
        NotificationCenter.default.post(notification)
    }
    
    public func authorizeAppOnly(success: TokenSuccessHandler?, failure: FailureHandler?) {
        self.postOAuth2BearerToken(success: { json, response in
            if let tokenType = json["token_type"].string {
                if tokenType == "bearer" {
                    let accessToken = json["access_token"].string
                    
                    let credentialToken = Credential.OAuthAccessToken(key: accessToken!, secret: "")
                    
                    self.client.credential = Credential(accessToken: credentialToken)
                    
                    success?(credentialToken, response)
                } else {
                    let error = SwifterError(message: "Cannot find bearer token in server response", kind: .invalidAppOnlyBearerToken)
                    failure?(error)
                }
            } else if case .object = json["errors"] {
                let error = SwifterError(message: json["errors"]["message"].string!, kind: .responseError(code: json["errors"]["code"].integer!))
                failure?(error)
            } else {
                let error = SwifterError(message: "Cannot find JSON dictionary in response", kind: .invalidJSONResponse)
                failure?(error)
            }
            
        }, failure: failure)
    }
    
    public func postOAuth2BearerToken(success: JSONSuccessHandler?, failure: FailureHandler?) {
        let path = "oauth2/token"
        
        var parameters = Dictionary<String, Any>()
        parameters["grant_type"] = "client_credentials"
        
        self.jsonRequest(path: path, baseURL: .oauth, method: .POST, parameters: parameters, success: success, failure: failure)
    }
    
    public func invalidateOAuth2BearerToken(success: TokenSuccessHandler?, failure: FailureHandler?) {
        let path = "oauth2/invalidate_token"
        
        self.jsonRequest(path: path, baseURL: .oauth, method: .POST, parameters: [:], success: { json, response in
            if let accessToken = json["access_token"].string {
                self.client.credential = nil
                let credentialToken = Credential.OAuthAccessToken(key: accessToken, secret: "")
                success?(credentialToken, response)
            } else {
                success?(nil, response)
            }
        }, failure: failure)
    }
    
    public func postOAuthRequestToken(with callbackURL: URL, success: @escaping TokenSuccessHandler, failure: FailureHandler?) {
        let path = "oauth/request_token"
        let parameters: [String: Any] =  ["oauth_callback": callbackURL.absoluteString]
        
        self.client.post(path, baseURL: .oauth, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: { data, response in
            let responseString = String(data: data, encoding: .utf8)!
            let accessToken = Credential.OAuthAccessToken(queryString: responseString)
            success(accessToken, response)
        }, failure: failure)
    }
    
    public func postOAuthAccessToken(with requestToken: Credential.OAuthAccessToken, success: @escaping TokenSuccessHandler, failure: FailureHandler?) {
        if let verifier = requestToken.verifier {
            let path =  "oauth/access_token"
            let parameters: [String: Any] = ["oauth_token": requestToken.key, "oauth_verifier": verifier]
            
            self.client.post(path, baseURL: .oauth, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: { data, response in
                
                let responseString = String(data: data, encoding: .utf8)!
                let accessToken = Credential.OAuthAccessToken(queryString: responseString)
                success(accessToken, response)
                
            }, failure: failure)
        } else {
            let error = SwifterError(message: "Bad OAuth response received from server", kind: .badOAuthResponse)
            failure?(error)
        }
    }
    
}


public protocol SwifterClientProtocol {
    
    var credential: Credential? { get set }
    
    @discardableResult
    func get(_ path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler?, downloadProgress: HTTPRequest.DownloadProgressHandler?, success: HTTPRequest.SuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest
    
    @discardableResult
    func post(_ path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler?, downloadProgress: HTTPRequest.DownloadProgressHandler?, success: HTTPRequest.SuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest
    
}


public class Credential {
    
    public struct OAuthAccessToken {
        
        public internal(set) var key: String
        public internal(set) var secret: String
        public internal(set) var verifier: String?
        
        public internal(set) var screenName: String?
        public internal(set) var userID: String?
        
        public init(key: String, secret: String) {
            self.key = key
            self.secret = secret
        }
        
        public init(queryString: String) {
            var attributes = queryString.queryStringParameters
            
            self.key = attributes["oauth_token"]!
            self.secret = attributes["oauth_token_secret"]!
            
            self.screenName = attributes["screen_name"]
            self.userID = attributes["user_id"]
        }
        
    }
    
    public internal(set) var accessToken: OAuthAccessToken?
    
    #if os(macOS) || os(iOS)
    public internal(set) var account: ACAccount?
    
    public init(account: ACAccount) {
        self.account = account
    }
    #endif
    
    public init(accessToken: OAuthAccessToken) {
        self.accessToken = accessToken
    }
    
}


public struct SwifterError: Error {
    
    public enum ErrorKind: CustomStringConvertible {
        case invalidAppOnlyBearerToken
        case responseError(code: Int)
        case invalidJSONResponse
        case badOAuthResponse
        case urlResponseError(status: Int, headers: [AnyHashable: Any], errorCode: Int)
        case jsonParseError
        
        public var description: String {
            switch self {
            case .invalidAppOnlyBearerToken:
                return "invalidAppOnlyBearerToken"
            case .invalidJSONResponse:
                return "invalidJSONResponse"
            case .responseError(let code):
                return "responseError(code: \(code))"
            case .badOAuthResponse:
                return "badOAuthResponse"
            case .urlResponseError(let code, let headers, let errorCode):
                return "urlResponseError(status: \(code), headers: \(headers), errorCode: \(errorCode)"
            case .jsonParseError:
                return "jsonParseError"
            }
        }
        
    }
    
    public var message: String
    public var kind: ErrorKind
    
    public var localizedDescription: String {
        return "[\(kind.description)] - \(message)"
    }
    
}


public extension Swifter {
    
    /**
     GET    friendships/no_retweets/ids
     
     Returns a collection of user_ids that the currently authenticated user does not want to receive retweets from. Use POST friendships/update to set the "no retweets" status for a given user account on behalf of the current user.
     */
    public func listOfNoRetweetsFriends(stringifyIDs: Bool = true, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friendships/no_retweets/ids.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["stringify_ids"] = stringifyIDs
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     GET    friends/ids
     Returns Users (*: user IDs for followees)
     
     Returns a cursored collection of user IDs for every user the specified user is following (otherwise known as their "friends").
     
     At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 5,000 user IDs and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information.
     
     This method is especially powerful when used in conjunction with GET users/lookup, a method that allows you to convert user IDs into full user objects in bulk.
     */
    public func getUserFollowingIDs(for userTag: UserTag, cursor: String? = nil, stringifyIDs: Bool? = nil, count: Int? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friends/ids.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["cursor"] ??= cursor
        parameters["stringify_ids"] ??= stringifyIDs
        parameters["count"] ??= count
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["ids"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     GET    followers/ids
     
     Returns a cursored collection of user IDs for every user following the specified user.
     
     At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 5,000 user IDs and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information.
     
     This method is especially powerful when used in conjunction with GET users/lookup, a method that allows you to convert user IDs into full user objects in bulk.
     */
    public func getUserFollowersIDs(for userTag: UserTag, cursor: String? = nil, stringifyIDs: Bool? = nil, count: Int? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "followers/ids.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["cursor"] ??= cursor
        parameters["stringify_ids"] ??= stringifyIDs
        parameters["count"] ??= count
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["ids"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     GET    friendships/incoming
     
     Returns a collection of numeric IDs for every user who has a pending request to follow the authenticating user.
     */
    public func getIncomingPendingFollowRequests(cursor: String? = nil, stringifyIDs: String? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friendships/incoming.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["cursor"] ??= cursor
        parameters["stringify_ids"] ??= stringifyIDs
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["ids"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     GET    friendships/outgoing
     
     Returns a collection of numeric IDs for every protected user for whom the authenticating user has a pending follow request.
     */
    public func getOutgoingPendingFollowRequests(cursor: String? = nil, stringifyIDs: String? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friendships/outgoing.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["cursor"] ??= cursor
        parameters["stringify_ids"] ??= stringifyIDs
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["ids"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     POST   friendships/create
     
     Allows the authenticating users to follow the user specified in the ID parameter.
     
     Returns the befriended user in the requested format when successful. Returns a string describing the failure condition when unsuccessful. If you are already friends with the user a HTTP 403 may be returned, though for performance reasons you may get a 200 OK message even if the friendship already exists.
     
     Actions taken in this method are asynchronous and changes will be eventually consistent.
     */
    public func followUser(for userTag: UserTag, follow: Bool? = nil, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friendships/create.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["follow"] ??= follow
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json)
        }, failure: failure)
    }
    
    /**
     POST	friendships/destroy
     
     Allows the authenticating user to unfollow the user specified in the ID parameter.
     
     Returns the unfollowed user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.
     
     Actions taken in this method are asynchronous and changes will be eventually consistent.
     */
    public func unfollowUser(for userTag: UserTag, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friendships/destroy.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json)
        }, failure: failure)
    }
    
    /**
     POST	friendships/update
     
     Allows one to enable or disable retweets and device notifications from the specified user.
     */
    public func updateFriendship(with userTag: UserTag, device: Bool? = nil, retweets: Bool? = nil, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friendships/update.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["device"] ??= device
        parameters["retweets"] ??= retweets
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json)
        }, failure: failure)
    }
    
    /**
     GET    friendships/show
     
     Returns detailed information about the relationship between two arbitrary users.
     */
    public func showFriendship(between sourceTag: UserTag, and targetTag: UserTag, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friendships/show.json"
        
        var parameters = Dictionary<String, Any>()
        switch sourceTag {
        case .id:           parameters["source_id"] = sourceTag.value
        case .screenName:   parameters["source_screen_name"] = sourceTag.value
        }
        
        switch targetTag {
        case .id:           parameters["target_id"] = targetTag.value
        case .screenName:   parameters["target_screen_name"] = targetTag.value
        }
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json)
        }, failure: failure)
    }
    
    /**
     GET    friends/list
     
     Returns a cursored collection of user objects for every user the specified user is following (otherwise known as their "friends").
     
     At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 20 users and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information.
     */
    public func getUserFollowing(for userTag: UserTag, cursor: String? = nil, count: Int? = nil, skipStatus: Bool? = nil, includeUserEntities: Bool? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "friends/list.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["cursor"] ??= cursor
        parameters["count"] ??= count
        parameters["skip_status"] ??= skipStatus
        parameters["include_user_entities"] ??= includeUserEntities
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["users"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     GET    followers/list
     
     Returns a cursored collection of user objects for users following the specified user.
     
     At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 20 users and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information.
     */
    public func getUserFollowers(for userTag: UserTag, cursor: String? = nil, count: Int? = nil, skipStatus: Bool? = nil, includeUserEntities: Bool? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "followers/list.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["cursor"] ??= cursor
        parameters["count"] ??= count
        parameters["skip_status"] ??= skipStatus
        parameters["include_user_entities"] ??= includeUserEntities
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["users"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     GET    friendships/lookup
     
     Returns the relationships of the authenticating user to the comma-separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none.
     */
    public func lookupFriendship(with usersTag: UsersTag, success: SuccessHandler? = nil, failure: FailureHandler?) {
        let path = "friendships/lookup.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[usersTag.key] = usersTag.value
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in            
            success?(json)
        }, failure: failure)
    }
    
}




public enum HTTPMethodType: String {
    case OPTIONS
    case GET
    case HEAD
    case POST
    case PUT
    case DELETE
    case TRACE
    case CONNECT
}

public class HTTPRequest: NSObject, URLSessionDataDelegate {
    
    public typealias UploadProgressHandler = (_ bytesWritten: Int, _ totalBytesWritten: Int, _ totalBytesExpectedToWrite: Int) -> Void
    public typealias DownloadProgressHandler = (Data, _ totalBytesReceived: Int, _ totalBytesExpectedToReceive: Int, HTTPURLResponse) -> Void
    public typealias SuccessHandler = (Data, HTTPURLResponse) -> Void
    public typealias FailureHandler = (Error) -> Void
    
    internal struct DataUpload {
        var data: Data
        var parameterName: String
        var mimeType: String?
        var fileName: String?
    }
    
    let url: URL
    let HTTPMethod: HTTPMethodType
    
    var request: URLRequest?
    var dataTask: URLSessionDataTask!
    
    var headers: Dictionary<String, String> = [:]
    var parameters: Dictionary<String, Any>
    var encodeParameters: Bool
    
    var uploadData: [DataUpload] = []
    
    var dataEncoding: String.Encoding = .utf8
    
    var timeoutInterval: TimeInterval = 60
    
    var HTTPShouldHandleCookies: Bool = false
    
    var response: HTTPURLResponse!
    var responseData: Data = Data()
    
    var uploadProgressHandler: UploadProgressHandler?
    var downloadProgressHandler: DownloadProgressHandler?
    var successHandler: SuccessHandler?
    var failureHandler: FailureHandler?
    
    public init(url: URL, method: HTTPMethodType = .GET, parameters: Dictionary<String, Any> = [:]) {
        self.url = url
        self.HTTPMethod = method
        self.parameters = parameters
        self.encodeParameters = false
    }
    
    public init(request: URLRequest) {
        self.request = request
        self.url = request.url!
        self.HTTPMethod = HTTPMethodType(rawValue: request.httpMethod!)!
        self.parameters = [:]
        self.encodeParameters = true
    }
    
    public func start() {
        
        
        if request == nil {
            self.request = URLRequest(url: self.url)
            self.request!.httpMethod = self.HTTPMethod.rawValue
            self.request!.timeoutInterval = self.timeoutInterval
            self.request!.httpShouldHandleCookies = self.HTTPShouldHandleCookies
            
            for (key, value) in headers {
                self.request!.setValue(value, forHTTPHeaderField: key)
            }
            
            let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.dataEncoding.rawValue))
            
            let nonOAuthParameters = self.parameters.filter { key, _ in !key.hasPrefix("oauth_") }
            
            if !self.uploadData.isEmpty {
                let boundary = "----------HTTPRequestBoUnDaRy"
                
                let contentType = "multipart/form-data; boundary=\(boundary)"
                self.request!.setValue(contentType, forHTTPHeaderField:"Content-Type")
                
                var body = Data()
                
                for dataUpload: DataUpload in self.uploadData {
                    let multipartData = HTTPRequest.mulipartContent(with: boundary, data: dataUpload.data, fileName: dataUpload.fileName, parameterName: dataUpload.parameterName, mimeType: dataUpload.mimeType)
                    body.append(multipartData)
                }
                
                for (key, value): (String, Any) in nonOAuthParameters {
                    body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                    body.append("\(value)".data(using: .utf8)!)
                }
                
                body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
                
                self.request!.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
                self.request!.httpBody = body
            } else if !nonOAuthParameters.isEmpty {
                if self.HTTPMethod == .GET || self.HTTPMethod == .HEAD || self.HTTPMethod == .DELETE {
                    let queryString = nonOAuthParameters.urlEncodedQueryString(using: self.dataEncoding)
                    self.request!.url = self.url.append(queryString: queryString)
                    self.request!.setValue("application/x-www-form-urlencoded; charset=\(String(describing: charset))", forHTTPHeaderField: "Content-Type")
                } else {
                    var queryString = ""
                    if self.encodeParameters {
                        queryString = nonOAuthParameters.urlEncodedQueryString(using: self.dataEncoding)
                        self.request!.setValue("application/x-www-form-urlencoded; charset=\(String(describing: charset))", forHTTPHeaderField: "Content-Type")
                    } else {
                        queryString = nonOAuthParameters.queryString
                    }
                    
                    if let data = queryString.data(using: self.dataEncoding) {
                        self.request!.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
                        self.request!.httpBody = data
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
            self.dataTask = session.dataTask(with: self.request!)
            self.dataTask.resume()
            
            #if os(iOS)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            #endif
        }
    }
    
    public func stop() {
        self.dataTask.cancel()
    }
    
    public func add(multipartData data: Data, parameterName: String, mimeType: String?, fileName: String?) -> Void {
        let dataUpload = DataUpload(data: data, parameterName: parameterName, mimeType: mimeType, fileName: fileName)
        self.uploadData.append(dataUpload)
    }
    
    private class func mulipartContent(with boundary: String, data: Data, fileName: String?, parameterName: String,  mimeType mimeTypeOrNil: String?) -> Data {
        let mimeType = mimeTypeOrNil ?? "application/octet-stream"
        let fileNameContentDisposition = fileName != nil ? "filename=\"\(String(describing: fileName))\"" : ""
        let contentDisposition = "Content-Disposition: form-data; name=\"\(parameterName)\"; \(fileNameContentDisposition)\r\n"
        
        var tempData = Data()
        tempData.append("--\(boundary)\r\n".data(using: .utf8)!)
        tempData.append(contentDisposition.data(using: .utf8)!)
        tempData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        tempData.append(data)
        tempData.append("\r\n".data(using: .utf8)!)
        return tempData
    }
    
    // MARK: - URLSessionDataDelegate
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #if os(iOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        #endif
        
        defer {
            session.finishTasksAndInvalidate()
        }
        
        if let error = error {
            self.failureHandler?(error)
            return
        }
        
        guard self.response.statusCode >= 400 else {
            self.successHandler?(self.responseData, self.response)
            return
        }
        let responseString = String(data: responseData, encoding: dataEncoding)!
        let errorCode = HTTPRequest.responseErrorCode(for: responseData) ?? 0
        let localizedDescription = HTTPRequest.description(for: response.statusCode, response: responseString)
        
        let error = SwifterError(message: localizedDescription, kind: .urlResponseError(status: response.statusCode, headers: response.allHeaderFields, errorCode: errorCode))
        self.failureHandler?(error)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.responseData.append(data)
        
        let expectedContentLength = Int(self.response!.expectedContentLength)
        let totalBytesReceived = self.responseData.count
        
        guard !data.isEmpty else { return }
        self.downloadProgressHandler?(data, totalBytesReceived, expectedContentLength, self.response)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response as? HTTPURLResponse
        self.responseData.count = 0
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.uploadProgressHandler?(Int(bytesSent), Int(totalBytesSent), Int(totalBytesExpectedToSend))
    }
    
    // MARK: - Error Responses
    
    class func responseErrorCode(for data: Data) -> Int? {
        guard let code = JSON(data)["errors"].array?.first?["code"].integer else {
            return nil
        }
        return code
    }
    
    class func description(for status: Int, response string: String) -> String {
        var s = "HTTP Status \(status)"
        
        let description: String
        
        // http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
        // https://dev.twitter.com/overview/api/response-codes
        switch(status) {
        case 400:	description = "Bad Request"
        case 401:	description = "Unauthorized"
        case 402:	description = "Payment Required"
        case 403:	description = "Forbidden"
        case 404:	description = "Not Found"
        case 405:	description = "Method Not Allowed"
        case 406:	description = "Not Acceptable"
        case 407:	description = "Proxy Authentication Required"
        case 408:	description = "Request Timeout"
        case 409:	description = "Conflict"
        case 410:	description = "Gone"
        case 411:	description = "Length Required"
        case 412:	description = "Precondition Failed"
        case 413:	description = "Payload Too Large"
        case 414:	description = "URI Too Long"
        case 415:	description = "Unsupported Media Type"
        case 416:	description = "Requested Range Not Satisfiable"
        case 417:	description = "Expectation Failed"
        case 420:	description = "Enhance Your Calm"
        case 422:	description = "Unprocessable Entity"
        case 423:	description = "Locked"
        case 424:	description = "Failed Dependency"
        case 425:	description = "Unassigned"
        case 426:	description = "Upgrade Required"
        case 427:	description = "Unassigned"
        case 428:	description = "Precondition Required"
        case 429:	description = "Too Many Requests"
        case 430:	description = "Unassigned"
        case 431:	description = "Request Header Fields Too Large"
        case 432:	description = "Unassigned"
        case 500:	description = "Internal Server Error"
        case 501:	description = "Not Implemented"
        case 502:	description = "Bad Gateway"
        case 503:	description = "Service Unavailable"
        case 504:	description = "Gateway Timeout"
        case 505:	description = "HTTP Version Not Supported"
        case 506:	description = "Variant Also Negotiates"
        case 507:	description = "Insufficient Storage"
        case 508:	description = "Loop Detected"
        case 509:	description = "Unassigned"
        case 510:	description = "Not Extended"
        case 511:	description = "Network Authentication Required"
        default:    description = ""
        }
        
        if !description.isEmpty {
            s = s + ": " + description + ", Response: " + string
        }
        
        return s
    }
}


internal class OAuthClient: SwifterClientProtocol  {
    
    struct OAuth {
        static let version = "1.0"
        static let signatureMethod = "HMAC-SHA1"
    }
    
    var consumerKey: String
    var consumerSecret: String
    
    var credential: Credential?
    
    let dataEncoding: String.Encoding = .utf8
    
    init(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }
    
    init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        
        let credentialAccessToken = Credential.OAuthAccessToken(key: accessToken, secret: accessTokenSecret)
        self.credential = Credential(accessToken: credentialAccessToken)
    }
    
    func get(_ path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler?, downloadProgress: HTTPRequest.DownloadProgressHandler?, success: HTTPRequest.SuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)!
        
        let request = HTTPRequest(url: url, method: .GET, parameters: parameters)
        request.headers = ["Authorization": self.authorizationHeader(for: .GET, url: url, parameters: parameters, isMediaUpload: false)]
        request.downloadProgressHandler = downloadProgress
        request.successHandler = success
        request.failureHandler = failure
        request.dataEncoding = self.dataEncoding
        
        request.start()
        return request
    }
    
    func post(_ path: String, baseURL: TwitterURL, parameters: Dictionary<String, Any>, uploadProgress: HTTPRequest.UploadProgressHandler?, downloadProgress: HTTPRequest.DownloadProgressHandler?, success: HTTPRequest.SuccessHandler?, failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)!
        
        var parameters = parameters
        var postData: Data?
        var postDataKey: String?
        
        if let key: Any = parameters[Swifter.DataParameters.dataKey] {
            if let keyString = key as? String {
                postDataKey = keyString
                postData = parameters[postDataKey!] as? Data
                
                parameters.removeValue(forKey: Swifter.DataParameters.dataKey)
                parameters.removeValue(forKey: postDataKey!)
            }
        }
        
        var postDataFileName: String?
        if let fileName: Any = parameters[Swifter.DataParameters.fileNameKey] {
            if let fileNameString = fileName as? String {
                postDataFileName = fileNameString
                parameters.removeValue(forKey: fileNameString)
            }
        }
        
        let request = HTTPRequest(url: url, method: .POST, parameters: parameters)
        request.headers = ["Authorization": self.authorizationHeader(for: .POST, url: url, parameters: parameters, isMediaUpload: postData != nil)]
        request.downloadProgressHandler = downloadProgress
        request.successHandler = success
        request.failureHandler = failure
        request.dataEncoding = self.dataEncoding
        request.encodeParameters = postData == nil
        
        if let postData = postData {
            let fileName = postDataFileName ?? "media.jpg"
            request.add(multipartData: postData, parameterName: postDataKey!, mimeType: "application/octet-stream", fileName: fileName)
        }
        
        request.start()
        return request
    }
    
    func authorizationHeader(for method: HTTPMethodType, url: URL, parameters: Dictionary<String, Any>, isMediaUpload: Bool) -> String {
        var authorizationParameters = Dictionary<String, Any>()
        authorizationParameters["oauth_version"] = OAuth.version
        authorizationParameters["oauth_signature_method"] =  OAuth.signatureMethod
        authorizationParameters["oauth_consumer_key"] = self.consumerKey
        authorizationParameters["oauth_timestamp"] = String(Int(Date().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = UUID().uuidString
        
        authorizationParameters["oauth_token"] ??= self.credential?.accessToken?.key
        
        for (key, value) in parameters where key.hasPrefix("oauth_") {
            authorizationParameters.updateValue(value, forKey: key)
        }
        
        let combinedParameters = authorizationParameters +| parameters
        
        let finalParameters = isMediaUpload ? authorizationParameters : combinedParameters
        
        authorizationParameters["oauth_signature"] = self.oauthSignature(for: method, url: url, parameters: finalParameters, accessToken: self.credential?.accessToken)
        
        let authorizationParameterComponents = authorizationParameters.urlEncodedQueryString(using: self.dataEncoding).components(separatedBy: "&").sorted()
        
        var headerComponents = [String]()
        for component in authorizationParameterComponents {
            let subcomponent = component.components(separatedBy: "=")
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        
        return "OAuth " + headerComponents.joined(separator: ", ")
    }
    
    func oauthSignature(for method: HTTPMethodType, url: URL, parameters: Dictionary<String, Any>, accessToken token: Credential.OAuthAccessToken?) -> String {
        let tokenSecret = token?.secret.urlEncodedString() ?? ""
        let encodedConsumerSecret = self.consumerSecret.urlEncodedString()
        let signingKey = "\(encodedConsumerSecret)&\(tokenSecret)"
        let parameterComponents = parameters.urlEncodedQueryString(using: dataEncoding).components(separatedBy: "&").sorted()
        let parameterString = parameterComponents.joined(separator: "&")
        let encodedParameterString = parameterString.urlEncodedString()
        let encodedURL = url.absoluteString.urlEncodedString()
        let signatureBaseString = "\(method)&\(encodedURL)&\(encodedParameterString)"
        
        let key = signingKey.data(using: .utf8)!
        let msg = signatureBaseString.data(using: .utf8)!
        let sha1 = HMAC.sha1(key: key, message: msg)!
        return sha1.base64EncodedString(options: [])
    }
    
}


public enum UserTag {
    case id(String)
    case screenName(String)
    
    var key: String {
        switch self {
        case .id:           return "user_id"
        case .screenName:   return "screen_name"
        }
    }
    
    var value: String {
        switch self {
        case .id(let id):           return id
        case .screenName(let user): return user
        }
    }
}

public enum UsersTag {
    case id([String])
    case screenName([String])
    
    var key: String {
        switch self {
        case .id:           return "user_id"
        case .screenName:   return "screen_name"
        }
    }
    
    var value: String {
        switch self {
        case .id(let id):           return id.joined(separator: ",")
        case .screenName(let user): return user.joined(separator: ",")
        }
    }
}

public enum ListTag {
    case id(String)
    case slug(String, owner: UserTag)
    
    var key: String {
        switch self {
        case .id:   return "list_id"
        case .slug: return "slug"
        }
    }
    
    var value: String {
        switch self {
        case .id(let id):           return id
        case .slug(let slug, _):    return slug
        }
    }
    
}


public extension Swifter {
    
    /**
     GET    account/settings
     
     Returns settings (including current trend, geo and sleep time information) for the authenticating user.
     */
    public func getAccountSettings(success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "account/settings.json"
        
        self.getJSON(path: path, baseURL: .api, parameters: [:], success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     GET	account/verify_credentials
     
     Returns an HTTP 200 OK response code and a representation of the requesting user if authentication was successful; returns a 401 status code and an error message if not. Use this method to test if supplied user credentials are valid.
     */
    public func verifyAccountCredentials(includeEntities: Bool? = nil, skipStatus: Bool? = nil, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "account/verify_credentials.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["include_entities"] ??= includeEntities
        parameters["skip_status"] ??= skipStatus
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST	account/settings
     
     Updates the authenticating user's settings.
     */
    public func updateAccountSettings(trendLocationWOEID: String? = nil, sleepTimeEnabled: Bool? = nil, startSleepTime: Int? = nil, endSleepTime: Int? = nil, timeZone: String? = nil, lang: String? = nil, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        assert(trendLocationWOEID != nil || sleepTimeEnabled != nil || startSleepTime != nil || endSleepTime != nil || timeZone != nil || lang != nil, "At least one or more should be provided when executing this request")
        
        let path = "account/settings.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["trend_location_woeid"] ??= trendLocationWOEID
        parameters["sleep_time_enabled"] ??= sleepTimeEnabled
        parameters["start_sleep_time"] ??= startSleepTime
        parameters["end_sleep_time"] ??= endSleepTime
        parameters["time_zone"] ??= timeZone
        parameters["lang"] ??= lang
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST	account/update_profile
     
     Sets values that users are able to set under the "Account" tab of their settings page. Only the parameters specified will be updated.
     */
    public func updateUserProfile(name: String? = nil, url: String? = nil, location: String? = nil, description: String? = nil, includeEntities: Bool? = nil, skipStatus: Bool? = nil, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        assert(name != nil || url != nil || location != nil || description != nil || includeEntities != nil || skipStatus != nil)
        
        let path = "account/update_profile.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["name"] ??= name
        parameters["url"] ??= url
        parameters["location"] ??= location
        parameters["description"] ??= description
        parameters["include_entities"] ??= includeEntities
        parameters["skip_status"] ??= skipStatus
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST	account/update_profile_background_image
     
     Updates the authenticating user's profile background image. This method can also be used to enable or disable the profile background image. Although each parameter is marked as optional, at least one of image, tile or use must be provided when making this request.
     */
    public func updateProfileBackground(using imageData: Data, title: String? = nil, includeEntities: Bool? = nil, use: Bool? = nil, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        assert(title != nil || use != nil, "At least one of image, tile or use must be provided when making this request")
        
        let path = "account/update_profile_background_image.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["image"] = imageData.base64EncodedString(options: [])
        parameters["title"] ??= title
        parameters["include_entities"] ??= includeEntities
        parameters["use"] ??= use
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST	account/update_profile_colors
     
     Sets one or more hex values that control the color scheme of the authenticating user's profile page on twitter.com. Each parameter's value must be a valid hexidecimal value, and may be either three or six characters (ex: #fff or #ffffff).
     */
    public func updateProfileColors(backgroundColor: String? = nil, linkColor: String? = nil, sidebarBorderColor: String? = nil, sidebarFillColor: String? = nil, textColor: String? = nil, includeEntities: Bool? = nil, skipStatus: Bool? = nil, success: SuccessHandler? = nil, failure: @escaping FailureHandler) {
        let path = "account/update_profile_colors.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["profile_background_color"] ??= backgroundColor
        parameters["profile_link_color"] ??= linkColor
        parameters["profile_sidebar_link_color"] ??= sidebarBorderColor
        parameters["profile_sidebar_fill_color"] ??= sidebarFillColor
        parameters["profile_text_color"] ??= textColor
        parameters["include_entities"] ??= includeEntities
        parameters["skip_status"] ??= skipStatus
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST	account/update_profile_image
     
     Updates the authenticating user's profile image. Note that this method expects raw multipart data, not a URL to an image.
     
     This method asynchronously processes the uploaded file before updating the user's profile image URL. You can either update your local cache the next time you request the user's information, or, at least 5 seconds after uploading the image, ask for the updated URL using GET users/show.
     */
    public func updateProfileImage(using imageData: Data, includeEntities: Bool? = nil, skipStatus: Bool? = nil, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "account/update_profile_image.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["image"] = imageData.base64EncodedString(options: [])
        parameters["include_entities"] ??= includeEntities
        parameters["skip_status"] ??= skipStatus
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     GET    blocks/list
     
     Returns a collection of user objects that the authenticating user is blocking.
     */
    public func getBlockedUsers(includeEntities: Bool? = nil, skipStatus: Bool? = nil, cursor: String? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "blocks/list.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["include_entities"] ??= includeEntities
        parameters["skip_status"] ??= skipStatus
        parameters["cursor"] ??= cursor
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["users"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     GET    blocks/ids
     
     Returns an array of numeric user ids the authenticating user is blocking.
     */
    public func getBlockedUsersIDs(stringifyIDs: String? = nil, cursor: String? = nil, success: CursorSuccessHandler? = nil, failure: @escaping FailureHandler) {
        let path = "blocks/ids.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["stringify_ids"] ??= stringifyIDs
        parameters["cursor"] ??= cursor
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["ids"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     POST	blocks/create
     
     Blocks the specified user from following the authenticating user. In addition the blocked user will not show in the authenticating users mentions or timeline (unless retweeted by another user). If a follow or friend relationship exists it is destroyed.
     */
    public func blockUser(for userTag: UserTag, includeEntities: Bool? = nil, skipStatus: Bool? = nil, success: SuccessHandler? = nil, failure: @escaping FailureHandler) {
        let path = "blocks/create.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["include_entities"] ??= includeEntities
        parameters["skip_status"] ??= skipStatus
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST	blocks/destroy
     
     Un-blocks the user specified in the ID parameter for the authenticating user. Returns the un-blocked user in the requested format when successful. If relationships existed before the block was instated, they will not be restored.
     */
    public func unblockUser(for userTag: UserTag, includeEntities: Bool? = nil, skipStatus: Bool? = nil, success: SuccessHandler? = nil, failure: @escaping FailureHandler) {
        let path = "blocks/destroy.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["include_entities"] ??= includeEntities
        parameters["skip_status"] ??= skipStatus
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     GET    users/lookup
     
     Returns fully-hydrated user objects for up to 100 users per request, as specified by comma-separated values passed to the user_id and/or screen_name parameters.
     
     This method is especially useful when used in conjunction with collections of user IDs returned from GET friends/ids and GET followers/ids.
     
     GET users/show is used to retrieve a single user object.
     
     There are a few things to note when using this method.
     
     - You must be following a protected user to be able to see their most recent status update. If you don't follow a protected user their status will be removed.
     - The order of user IDs or screen names may not match the order of users in the returned array.
     - If a requested user is unknown, suspended, or deleted, then that user will not be returned in the results list.
     - If none of your lookup criteria can be satisfied by returning a user object, a HTTP 404 will be thrown.
     - You are strongly encouraged to use a POST for larger requests.
     */
    public func lookupUsers(for usersTag: UsersTag, includeEntities: Bool? = nil, success: SuccessHandler? = nil, failure: @escaping FailureHandler) {
        let path = "users/lookup.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[usersTag.key] = usersTag.value
        parameters["include_entities"] ??= includeEntities
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     GET    users/show
     
     Returns a variety of information about the user specified by the required user_id or screen_name parameter. The author's most recent Tweet will be returned inline when possible. GET users/lookup is used to retrieve a bulk collection of user objects.
     
     You must be following a protected user to be able to see their most recent Tweet. If you don't follow a protected user, the users Tweet will be removed. A Tweet will not always be returned in the current_status field.
     */
    public func showUser(for userTag: UserTag, includeEntities: Bool? = nil, success: SuccessHandler? = nil, failure: @escaping FailureHandler) {
        let path = "users/show.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        parameters["include_entities"] ??= includeEntities
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     GET    users/search
     
     Provides a simple, relevance-based search interface to public user accounts on Twitter. Try querying by topical interest, full name, company name, location, or other criteria. Exact match searches are not supported.
     
     Only the first 1,000 matching results are available.
     */
    public func searchUsers(using query: String, page: Int?, count: Int?, includeEntities: Bool?, success: SuccessHandler? = nil, failure: @escaping FailureHandler) {
        let path = "users/search.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["q"] = query
        parameters["page"] ??= page
        parameters["count"] ??= count
        parameters["include_entities"] ??= includeEntities
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST   account/remove_profile_banner
     
     Removes the uploaded profile banner for the authenticating user. Returns HTTP 200 upon success.
     */
    public func removeProfileBanner(success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "account/remove_profile_banner.json"
        
        self.postJSON(path: path, baseURL: .api, parameters: [:], success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST    account/update_profile_banner
     
     Uploads a profile banner on behalf of the authenticating user. For best results, upload an <5MB image that is exactly 1252px by 626px. Images will be resized for a number of display options. Users with an uploaded profile banner will have a profile_banner_url node in their Users objects. More information about sizing variations can be found in User Profile Images and Banners and GET users/profile_banner.
     
     Profile banner images are processed asynchronously. The profile_banner_url and its variant sizes will not necessary be available directly after upload.
     
     If providing any one of the height, width, offset_left, or offset_top parameters, you must provide all of the sizing parameters.
     
     HTTP Response Codes
     200, 201, 202	Profile banner image succesfully uploaded
     400	Either an image was not provided or the image data could not be processed
     422	The image could not be resized or is too large.
     */
    public func updateProfileBanner(using imageData: Data, width: Int? = nil, height: Int? = nil, offsetLeft: Int? = nil, offsetTop: Int? = nil, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "account/update_profile_banner.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["banner"] = imageData.base64EncodedString
        parameters["width"] ??= width
        parameters["height"] ??= height
        parameters["offset_left"] ??= offsetLeft
        parameters["offset_top"] ??= offsetTop
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     GET    users/profile_banner
     
     Returns a map of the available size variations of the specified user's profile banner. If the user has not uploaded a profile banner, a HTTP 404 will be served instead. This method can be used instead of string manipulation on the profile_banner_url returned in user objects as described in User Profile Images and Banners.
     */
    public func getProfileBanner(for userTag: UserTag, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "users/profile_banner.json"
        let parameters: [String: Any] = [userTag.key: userTag.value]
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST   mutes/users/create
     
     Mutes the user specified in the ID parameter for the authenticating user.
     
     Returns the muted user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.
     
     Actions taken in this method are asynchronous and changes will be eventually consistent.
     */
    public func muteUser(for userTag: UserTag, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "mutes/users/create.json"
        let parameters: [String: Any] = [userTag.key: userTag.value]
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in success?(json) }, failure: failure)
    }
    
    /**
     POST   mutes/users/destroy
     
     Un-mutes the user specified in the ID parameter for the authenticating user.
     
     Returns the unmuted user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.
     
     Actions taken in this method are asynchronous and changes will be eventually consistent.
     */
    public func unmuteUser(for userTag: UserTag, success: SuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "mutes/users/destroy.json"
        
        var parameters = Dictionary<String, Any>()
        parameters[userTag.key] = userTag.value
        
        self.postJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json)
        }, failure: failure)
    }
    
    /**
     GET    mutes/users/ids
     
     Returns an array of numeric user ids the authenticating user has muted.
     */
    public func getMuteUsersIDs(cursor: String? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "mutes/users/ids.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["cursor"] ??= cursor
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["ids"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
    /**
     GET    mutes/users/list
     
     Returns an array of user objects the authenticating user has muted.
     */
    public func getMuteUsers(cursor: String? = nil, includeEntities: Bool? = nil, skipStatus: Bool? = nil, success: CursorSuccessHandler? = nil, failure: FailureHandler? = nil) {
        let path = "mutes/users/list.json"
        
        var parameters = Dictionary<String, Any>()
        parameters["include_entities"] ??= includeEntities
        parameters["skip_status"] ??= skipStatus
        parameters["cursor"] ??= cursor
        
        self.getJSON(path: path, baseURL: .api, parameters: parameters, success: { json, _ in
            success?(json["users"], json["previous_cursor_str"].string, json["next_cursor_str"].string)
        }, failure: failure)
    }
    
}

extension URL {
    
    func append(queryString: String) -> URL {
        guard !queryString.utf16.isEmpty else {
            return self
        }
        
        var absoluteURLString = self.absoluteString
        
        if absoluteURLString.hasSuffix("?") {
            absoluteURLString = absoluteURLString[0..<absoluteURLString.utf16.count]
        }
        
        let urlString = absoluteURLString + (absoluteURLString.range(of: "?") != nil ? "&" : "?") + queryString
        return URL(string: urlString)!
    }
    
}


func rotateLeft(_ v:UInt16, n:UInt16) -> UInt16 {
    return ((v << n) & 0xFFFF) | (v >> (16 - n))
}

func rotateLeft(_ v:UInt32, n:UInt32) -> UInt32 {
    return ((v << n) & 0xFFFFFFFF) | (v >> (32 - n))
}

func rotateLeft(_ x:UInt64, n:UInt64) -> UInt64 {
    return (x << n) | (x >> (64 - n))
}

func rotateRight(_ x:UInt16, n:UInt16) -> UInt16 {
    return (x >> n) | (x << (16 - n))
}

func rotateRight(_ x:UInt32, n:UInt32) -> UInt32 {
    return (x >> n) | (x << (32 - n))
}

func rotateRight(_ x:UInt64, n:UInt64) -> UInt64 {
    return ((x >> n) | (x << (64 - n)))
}

func reverseBytes(_ value: UInt32) -> UInt32 {
    let tmp1 = ((value & 0x000000FF) << 24) | ((value & 0x0000FF00) << 8)
    let tmp2 = ((value & 0x00FF0000) >> 8)  | ((value & 0xFF000000) >> 24)
    return tmp1 | tmp2
}


extension Int {
    
    public func bytes(_ totalBytes: Int = MemoryLayout<Int>.size) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }
    
}

func arrayOfBytes<T>(_ value:T, length: Int? = nil) -> [UInt8] {
    let totalBytes = length ?? (MemoryLayout<T>.size * 8)
    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value
    
    let bytesPointer = valuePointer.withMemoryRebound(to: UInt8.self, capacity: 1) { $0 }
    var bytes = [UInt8](repeating: 0, count: totalBytes)
    for j in 0..<min(MemoryLayout<T>.size,totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }
    
    valuePointer.deinitialize()
    valuePointer.deallocate(capacity: 1)
    
    return bytes
}


class TwiterManager {
    
}
