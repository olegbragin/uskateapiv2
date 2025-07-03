import Fluent

struct CreateCharger: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("charger")
            .field("id", .int, .identifier(auto: true))
            .field("plug", .int, .required)
            .field("state", .int, .required)
            .field("price", .string, .required)
            .field("chargestation_id", .int, .foreignKey("chargestation", .key(.id), onDelete: .noAction, onUpdate: .setNull))
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("charger").delete()
    }
}
