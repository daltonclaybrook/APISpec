import Foundation
import HTTP
import Random
import Vapor

extension APISchemaType {
    var typeName: String {
        switch self {
        case .null:
            return "null"
        case .boolean:
            return "boolean"
        case .object:
            return "object"
        case .array:
            return "array"
        case .number:
            return "number"
        case .string:
            return "string"
        case .data:
            return "string"
        }
    }
    
    var format: String? {
        switch self {
        case .data:
            return "binary"
        default:
            return nil
        }
    }
    
    var ref: String? {
        switch self {
        case .object(let type):
            return "#/definitions/\(type.schemaName)"
        default:
            return nil
        }
    }
    
    var example: Any? {
        switch self {
        case .boolean:
            return makeRandom(min: 0, max: 1) % 2 == 0
        case .number(let example):
            return example
        case .string(let example):
            return example
        default:
            return nil
        }
    }
    
    var itemsType: APISchemaType? {
        switch self {
        case .array(let itemType):
            return itemType
        default:
            return nil
        }
    }
}

extension APISchemes {
    var allSchemeStrings: [String] {
        var schemeStrings: [String] = []
        if contains(.http) { schemeStrings.append("http") }
        if contains(.https) { schemeStrings.append("https") }
        return schemeStrings
    }
}

extension APIResponse {
    public static func ok(description: String = Status.ok.reasonPhrase, model: APISchemaProviding.Type? = nil) -> APIResponse {
        return APIResponse(status: .ok, description: description, model: model)
    }
    public static func created(description: String = Status.created.reasonPhrase, model: APISchemaProviding.Type? = nil) -> APIResponse {
        return APIResponse(status: .created, description: description, model: model)
    }
    public static func badRequest(description: String = Status.badRequest.reasonPhrase, model: APISchemaProviding.Type? = nil) -> APIResponse {
        return APIResponse(status: .badRequest, description: description, model: model)
    }
    public static func unauthorized(description: String = Status.unauthorized.reasonPhrase, model: APISchemaProviding.Type? = nil) -> APIResponse {
        return APIResponse(status: .unauthorized, description: description, model: model)
    }
    public static func notFound(description: String = Status.badRequest.reasonPhrase, model: APISchemaProviding.Type? = nil) -> APIResponse {
        return APIResponse(status: .notFound, description: description, model: model)
    }
    public static func forbidden(description: String = Status.forbidden.reasonPhrase, model: APISchemaProviding.Type? = nil) -> APIResponse {
        return APIResponse(status: .forbidden, description: description, model: model)
    }
}

extension APIOperation {
    public static func get(
        _ path: String,
        summary: String,
        description: String? = nil,
        responses: [APIResponse] = [ .ok() ]
        ) -> APIOperation {
        return APIOperation(
            method: .get,
            path: path,
            summary: summary,
            description: description,
            requestModel: nil,
            responses: responses
        )
    }
    
    public static func post(
        _ path: String,
        summary: String,
        description: String? = nil,
        requestModel: APISchemaProviding.Type? = nil,
        responses: [APIResponse] = [ .ok() ]
        ) -> APIOperation {
        return APIOperation(
            method: .post,
            path: path,
            summary: summary,
            description: description,
            requestModel: requestModel,
            responses: responses
        )
    }
    
    public static func put(
        _ path: String,
        summary: String,
        description: String? = nil,
        requestModel: APISchemaProviding.Type? = nil,
        responses: [APIResponse] = [ .ok() ]
        ) -> APIOperation {
        return APIOperation(
            method: .put,
            path: path,
            summary: summary,
            description: description,
            requestModel: requestModel,
            responses: responses
        )
    }
    
    public static func patch(
        _ path: String,
        summary: String,
        description: String? = nil,
        requestModel: APISchemaProviding.Type? = nil,
        responses: [APIResponse] = [ .ok() ]
        ) -> APIOperation {
        return APIOperation(
            method: .patch,
            path: path,
            summary: summary,
            description: description,
            requestModel: requestModel,
            responses: responses
        )
    }
    
    public static func delete(
        _ path: String,
        summary: String,
        description: String? = nil,
        responses: [APIResponse] = [ .ok() ]
        ) -> APIOperation {
        return APIOperation(
            method: .delete,
            path: path,
            summary: summary,
            description: description,
            responses: responses
        )
    }
    
    var allSchemaProviders: [APISchemaProviding.Type] {
        var providers: [APISchemaProviding.Type] = []
        if let request = requestModel {
            providers.append(request)
        }
        
        let responseProviders = responses.flatMap { $0.model }
        providers.append(contentsOf: responseProviders)
        return providers
    }
}

extension APISpecProviding {
    public var version: String {
        return "1.0"
    }
    public var contactEmail: String? {
        return nil
    }
    public var basePath: String {
        return "/"
    }
}

extension APISpecProviding {
    public func generateAPISpecResponse(with tagProviders: [APITagProviding]) throws -> Response {
        let data = try generateAPISpecJSONData(with: tagProviders)
        let headers: [HeaderKey: String] = [
            .contentType: "application/json"
        ]
        return Response(status: .ok, headers: headers, body: data)
    }
    
    public func generateAPISpecJSONData(with tagProviders: [APITagProviding]) throws -> Data {
        var rootObject: [String: Any] = [:]
        rootObject["openapi"] = "3.0.0"
        rootObject["info"] = [
            "title": title,
            "description": description,
            "version": version,
            "contact": [ "email": contactEmail ]
        ]
        rootObject["host"] = host
        rootObject["basePath"] = basePath
        rootObject["schemes"] = schemes.allSchemeStrings
        rootObject["tags"] = tagProviders.map {
            return [
                "name": $0.name,
                "description": $0.description
            ]
        }
        rootObject["paths"] = generatePathsDict(with: tagProviders)
        rootObject["definitions"] = generateDefinitionsDict(with: tagProviders)
        
        return try JSONSerialization.data(withJSONObject: rootObject, options: .prettyPrinted)
    }
    
    // MARK: Private
    
    private func generatePathsDict(with tagProviders: [APITagProviding]) -> [String: Any] {
        return tagProviders.reduce([String: Any]()) { result, tagProvider in
            return tagProvider.operations.reduce(result) { result, operation in
                var result = result
                var pathDict = (result[operation.path] as? [String: Any]) ?? [:]
                let methodKey = operation.method.description.lowercased()
                
                var operationDict: [String: Any] = [
                    "summary": operation.summary,
                    "description": operation.description ?? "",
                    "operationId": "\(operation.path)+\(methodKey)",
                    "tags": [tagProvider.name]
                ]
                if let requestProvider = operation.requestModel {
                    operationDict["requestBody"] = requestProvider.generateContentDict()
                }
                operationDict["responses"] = operation.responses.generateResponsesDict()
                
                pathDict[methodKey] = operationDict
                result[operation.path] = pathDict
                return result
            }
        }
    }
    
    private func generateDefinitionsDict(with tagProviders: [APITagProviding]) -> [String: Any] {
        let allSchemaProviders = tagProviders
            .flatMap { $0.operations }
            .flatMap { $0.allSchemaProviders }
        return allSchemaProviders.generateDefinitionsDict()
    }
}

extension Array where Element == APISchemaProviding.Type {
    func generateDefinitionsDict() -> [String: Any] {
        return reduce([String: Any]()) { result, provider in
            var result = result
            result[provider.schemaName] = provider.generateDict()
            return result
        }
    }
}

extension APISchemaProviding {
    public static var contentType: APIContentType {
        return .json
    }
    
    static func generateDict() -> [String: Any] {
        var result: [String: Any] = [:]
        result["type"] = "object"
        result["required"] = properties.flatMap { $0.isRequired ? $0.name : nil }
        result["properties"] = properties.reduce([String: Any]()) { result, property in
            var result = result
            result[property.name] = property.generateDict()
            return result
        }
        return result
    }
    
    static func generateContentDict() -> [String: Any] {
        return [
            "content": [
                contentType.rawValue: [
                    "schema": [
                        "$ref": "#/definitions/\(schemaName)"
                    ]
                ]
            ]
        ]
    }
}

extension APIProperty {
    func generateDict() -> [String: Any] {
        var result: [String: Any] = [:]
        result["type"] = type.typeName
        if let format = type.format {
            result["format"] = format
        }
        if let ref = type.ref {
            result["$ref"] = ref
        }
        if let example = type.example {
            result["example"] = example
        }
        if let itemsType = type.itemsType {
            result["items"] = [
                "type": itemsType.typeName
            ]
        }
        return result
    }
}

extension APIResponse {
    func generateDict() -> [String: Any] {
        var result: [String: Any] = [:]
        result["description"] = description
        if let model = model {
            result.merge(model.generateContentDict(), uniquingKeysWith: { $1 })
        }
        return result
    }
}

extension Array where Element == APIResponse {
    func generateResponsesDict() -> [String: Any] {
        return reduce([String: Any]()) { result, response in
            var result = result
            result["\(response.status.statusCode)"] = response.generateDict()
            return result
        }
    }
}

extension Resource where Model: APISchemaProviding {
    public func makeAPIOperations(
        withPath path: String,
        storeModel: APISchemaProviding.Type? = nil,
        updateModel: APISchemaProviding.Type? = nil
    ) -> [APIOperation] {
        var operations: [APIOperation] = []
        if index != nil {
            operations.append(.get(path, summary: "Fetch all \(Model.schemaName)s", responses: [
                .ok(description: "Array of \(Model.schemaName)s", model: Model.self)
            ]))
        }
        if store != nil {
            let model: APISchemaProviding.Type = storeModel ?? Model.self
            operations.append(.post(path, summary: "Create a \(Model.schemaName)", requestModel: model, responses: [
                .created(model: Model.self)
            ]))
        }
        if show != nil {
            operations.append(.get(path + "/{id}", summary: "Fetch a \(Model.schemaName) by id", responses: [
                .ok(model: Model.self),
                .notFound()
            ]))
        }
        if update != nil {
            let model: APISchemaProviding.Type = updateModel ?? Model.self
            operations.append(.patch(path + "/{id}", summary: "Update a \(Model.schemaName)", requestModel: model, responses: [
                .ok(model: Model.self),
                .notFound()
            ]))
        }
        if replace != nil {
            let model: APISchemaProviding.Type = storeModel ?? Model.self
            operations.append(.put(path + "/{id}", summary: "Replace a \(Model.schemaName)", requestModel: model, responses: [
                .ok(model: Model.self),
                .notFound()
            ]))
        }
        if destroy != nil {
            operations.append(.delete(path + "/{id}", summary: "Delete a \(Model.schemaName)", responses: [
                .ok(),
                .notFound()
            ]))
        }
        return operations
    }
}
