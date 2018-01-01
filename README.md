# APISpec
APISpec enables Swift Vapor developers to write API docs in Swift, then export those docs to OpenAPI 3.0 JSON.

To build a spec, you must make your types conform to these three protocols:
* **APISpecProviding** - This type represents your spec root. Typically your `Droplet` will conform to this type.
* **APITagProviding** - This type represents the various sections of your spec, known in OpenAPI as "Tags," and is typically comprised of Controllers. Conformers are responsible for vending `APIOperations`, which represent endpoints your API exposes. If your controller conforms to `ResourceRepresentable`, and your `Resource` Model conforms to `APISchemaProviding`, you can generate `APIOperations` from your resource. Otherwise, you must generate `APIOperations` manually.
* **APISchemaProviding** - A main component of your API contract is your schema. API request/response data must conform to a predictable schema in order for client/server communications to be meaningful. Typically, your Models will conform to this type.

## Examples
### APISpecProviding

```swift
extension Droplet: APISpecProviding {
    public var title: String {
        return "Petworld API"
    }
    public var description: String {
        return "The is the API server for Petworld."
    }
    public var host: String {
        return "api.petworld.com"
    }
    public var schemes: APISchemes {
        return .https
    }
    public var contactEmail: String? {
        return "daltonclaybrook@gmail.com"
    }
}
```

### APITagProviding - 

```swift
extension PetController: APITagProviding {
    var name: String {
        return "pets"
    }
    var description: String {
        return "Pets have various characteristics such as `name` and `owner`."
    }
    var operations: [APIOperation] {
        // You can generate APIOperations from a Resource where Model conforms to `APISchemaProviding`
        return makeResource().makeAPIOperations(withPath: "/pets")
    }
}
```

### APISchemaProviding

```swift
extension Pet: APISchemaProviding {
    static var schemaName: String {
        return "Pet"
    }
    static var properties: [APIProperty] {
        return [
            APIProperty(name: "name", type: .string(example: "Sparky")),
            APIProperty(name: "age", type: .number(example: 3)),
            APIProperty(name: "owner", type: .object(type: Owner.self), isRequired: false)
        ]
    }
}
```

## Generating the JSON
Once you have defined your spec using the various protocols, you can generate OpenAPI JSON which can be used by various tools, such as Swagger UI. Assuming your `Droplet` conforms to `APISpecProviding`, your Routes file might include something like this:

```swift
import APISpec

extension Droplet {
    func setupRoutes() throws {
        // ... setup other routes

        let tagProviders: [APITagProviding] = [
            petController
        ]
        
        self.get("/docs.json") { _ in
            return try self.generateAPISpecResponse(with: tagProviders)
        }
    }
}
```
