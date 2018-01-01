import Foundation
import HTTP

// MARK: Protocols

protocol APISpecProviding {
    var title: String { get }
    var description: String { get }
    var version: String { get }
    var contactEmail: String? { get }
    var host: String { get }
    var basePath: String { get }
    var schemes: APISchemes { get }
}

protocol APITagProviding {
    var name: String { get }
    var description: String { get }
    var operations: [APIOperation] { get }
}

protocol APISchemaProviding {
    static var schemaName: String { get }
    static var contentType: APIContentType { get }
    static var properties: [APIProperty] { get }
}

// MARK: Helper Models

enum APIContentType: String {
    case json = "application/json"
    case formData = "multipart/form-data"
}

struct APISchemes: OptionSet {
    let rawValue: UInt
    static let http = APISchemes(rawValue: 1 << 0)
    static let https = APISchemes(rawValue: 1 << 1)
    static let none = APISchemes(rawValue: 0)
    
    init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    var allSchemeStrings: [String] {
        var schemeStrings: [String] = []
        if contains(.http) { schemeStrings.append("http") }
        if contains(.https) { schemeStrings.append("https") }
        return schemeStrings
    }
}

struct APIOperation {
    let method: HTTP.Method
    let path: String
    let summary: String
    let description: String?
    let requestModel: APISchemaProviding.Type?
    let responses: [APIResponse]
    
    init(
        method: HTTP.Method,
        path: String,
        summary: String,
        description: String? = nil,
        requestModel: APISchemaProviding.Type? = nil,
        responses: [APIResponse]
        ) {
        self.method = method
        self.path = path
        self.summary = summary
        self.description = description
        self.requestModel = requestModel
        self.responses = responses
    }
}

struct APIProperty {
    let name: String
    let type: APISchemaType
    let isRequired: Bool
    
    init(name: String, type: APISchemaType, isRequired: Bool = true) {
        self.name = name
        self.type = type
        self.isRequired = isRequired
    }
}

enum APISchemaType {
    case null
    case boolean
    case object(type: APISchemaProviding.Type)
    indirect case array(itemType: APISchemaType)
    case number(example: Double?)
    case string(example: String?)
    case data
}

struct APIResponse {
    let status: HTTP.Status
    let description: String
    let model: APISchemaProviding.Type?
    
    init(status: HTTP.Status, description: String = "", model: APISchemaProviding.Type? = nil) {
        self.status = status
        self.description = description
        self.model = model
    }
}
