import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }

        func prepare(on database: any Database) async throws {
            try await database.schema("usertoken")
                .field("id", .int, .identifier(auto: true))
                .field("value", .string, .required)
                .field("user_id", .int, .required, .references("user", "id"))
                .unique(on: "value")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("usertoken").delete()
        }
    }
}