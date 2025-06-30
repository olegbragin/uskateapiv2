import Fluent

struct UpdateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user")
            .field("username", .string, .sql(.default("")), .required)
            .field("usernametype", .string, .sql(.default("phone")), .required)
            .field("email", .string)
            .unique(on: "username")
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user")
            .deleteField("username")
            .deleteField("usernametype")
            .deleteField("email")
            .update()
    }
}