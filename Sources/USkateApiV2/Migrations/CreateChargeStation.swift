import Fluent

struct CreateChargeStation: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("chargestation")
            .field("id", .int, .identifier(auto: true))
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("title", .string)
            .field("subtitle", .string)
            .field("imageSrc", .string)
            .field("chargerType", .string)
            .field("rating", .int)
            .field("isFavorite", .bool)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("chargestation").delete()
    }
}