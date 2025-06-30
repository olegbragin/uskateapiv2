import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user")
            .field("id", .int, .identifier(auto: true))
            .field("firstname", .string, .required)
            .field("lastname", .string, .required)
            .field("isActive", .bool)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user").delete()
    }
}
