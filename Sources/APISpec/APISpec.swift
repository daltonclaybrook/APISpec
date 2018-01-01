import Foundation
import HTTP

// MARK: Protocols

public protocol APISpecProviding {
    var title: String { get }
    var description: String { get }
    var version: String { get }
    var contactEmail: String? { get }
    var host: String { get }
    var basePath: String { get }
    var schemes: APISchemes { get }
}

public protocol APITagProviding {
    var name: String { get }
    var description: String { get }
    var operations: [APIOperation] { get }
}

public protocol APISchemaProviding {
    static var schemaName: String { get }
    static var contentType: APIContentType { get }
    static var properties: [APIProperty] { get }
}

// MARK: Helper Models

public enum APIContentType: String {
    case json = "application/json"
    case formData = "multipart/form-data"
}

public struct APISchemes: OptionSet {
    public let rawValue: UInt
    public static let http = APISchemes(rawValue: 1 << 0)
    public static let https = APISchemes(rawValue: 1 << 1)
    public static let none = APISchemes(rawValue: 0)
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

public struct APIOperation {
    public let method: HTTP.Method
    public let path: String
    public let summary: String
    public let description: String?
    public let requestModel: APISchemaProviding.Type?
    public let responses: [APIResponse]
    
    public init(
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

public struct APIProperty {
    public let name: String
    public let type: APISchemaType
    public let isRequired: Bool
    
    public init(name: String, type: APISchemaType, isRequired: Bool = true) {
        self.name = name
        self.type = type
        self.isRequired = isRequired
    }
}

public enum APISchemaType {
    case null
    case boolean
    case object(type: APISchemaProviding.Type)
    indirect case array(itemType: APISchemaType)
    case number(example: Double?)
    case string(example: String?)
    case data
}

public struct APIResponse {
    public let status: HTTP.Status
    public let description: String
    public let model: APISchemaProviding.Type?
    
    public init(status: HTTP.Status, description: String = "", model: APISchemaProviding.Type? = nil) {
        self.status = status
        self.description = description
        self.model = model
    }
}
