import Foundation

/// The list of known services. Loaded from `services.json` in the package bundle by default.
public struct ServiceCatalog: Sendable, Hashable {
    public let services: [ServiceDefinition]

    public init(services: [ServiceDefinition]) {
        self.services = services
    }

    public init(data: Data) throws {
        struct File: Decodable {
            var services: [ServiceDefinition]
        }
        services = try JSONDecoder().decode(File.self, from: data).services
    }

    /// The catalog shipped with Lokal.
    public static let bundled: ServiceCatalog = {
        guard let url = Bundle.module.url(forResource: "services", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let catalog = try? ServiceCatalog(data: data)
        else {
            preconditionFailure("services.json is missing or invalid; ServiceCatalogTests should have caught this")
        }
        return catalog
    }()

    public func service(id: String) -> ServiceDefinition? {
        services.first { $0.id == id }
    }
}
