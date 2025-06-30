import Fluent

struct UpdateChargeStation: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("chargestation")
            .deleteField("chargerType")
            .update()
        
        try await database.schema("chargestation")
            .field("phone", .string)
            .field("workTime", .string)
            .field("parking", .string)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("chargestation")
            .field("chargerType", .string)
            .update()

        try await database.schema("chargestation")
            .deleteField("phone")
            .deleteField("workTime")
            .deleteField("parking")
            .update()
    }
}