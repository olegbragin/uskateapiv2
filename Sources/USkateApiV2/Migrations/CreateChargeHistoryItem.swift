import Fluent

struct CreateChargeHistoryItem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("chargehistoryitem")
            .field("id", .int, .identifier(auto: true))
            .field("chargeDate", .datetime, .required)
            .field("energyDelivered", .int, .required)
            .field("duration", .int, .required)
            .field("chargingSpeed", .int, .required)
            .field("totalCost", .sql(unsafeRaw: "NUMERIC(7,2)"), .required)
            .field("chargestation_id", .int, .foreignKey("chargestation", .key(.id), onDelete: .noAction, onUpdate: .setNull))
            .unique(on: "chargestation_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("chargehistoryitem").delete()
    }
}