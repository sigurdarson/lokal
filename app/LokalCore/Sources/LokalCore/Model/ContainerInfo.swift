/// A running container reported by the Docker Engine API (Docker Desktop or OrbStack).
public struct ContainerInfo: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let image: String
    /// Host ports published by this container.
    public let publishedPorts: [UInt16]

    public init(id: String, name: String, image: String, publishedPorts: [UInt16]) {
        self.id = id
        self.name = name
        self.image = image
        self.publishedPorts = publishedPorts
    }
}
