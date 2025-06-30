@testable import USkateApiV2
import VaporTesting
import Testing
import Fluent

@Suite("Charge Station Tests with DB", .serialized)
struct ChargerTests: EntityTestable {
    var apiPath: String {
        "api/chargers"
    }

    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("Getting all chargers")
    func testChargers() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, apiPath, 
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )
        }
    }

    @Test("Testing Create unattached charger")
    func testCreateUnattachedCharger() async throws {
        try await withApp { app in
            let newCharger = ChargerDTO(
                plug: 1, 
                state: 0, 
                price: "100"
            )
            var chargerID: Int?
            try await createEntity(
                with: app, 
                andCreator: { 
                    newCharger
                },
                completion: { charger in
                    #expect(charger.price == "100")
                    chargerID = charger.id
                }
            )
            #expect(chargerID != nil)
            guard let chargerID = chargerID else { return }
            try await deleteEntity(with: app, andEntityID: chargerID)
        }
    }

    @Test("Updating a unattached charger")
    func testUpdateUnattachedCharger() async throws {
        try await withApp { app in
            let newCharger = ChargerDTO(
                plug: 1, 
                state: 0, 
                price: "100"
            )
            var chargerID: Int?
            try await createEntity(
                with: app, 
                andCreator: { 
                    newCharger 
                },
                completion: { charger in
                    chargerID = charger.id
                }
            )
            #expect(chargerID != nil)
            guard let chargerID = chargerID else { return }
            try await app.testing().test(.PATCH, "\(apiPath)/\(chargerID)", 
                beforeRequest: { req in
                    let updatedChargerDTO = ChargerDTO(
                        plug: 2, 
                        state: 1, 
                        price: "200"
                    )
                    try req.content.encode(updatedChargerDTO)
                }, 
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let charger = try res.content.decode(ChargerDTO.self)
                    #expect(charger.price == "200")
                }
            )
            try await deleteEntity(with: app, andEntityID: chargerID)
        }
    }

    @Test("Updating an attached charger")
    func testCreateAttachedCharger() async throws {
        try await withApp { app in
            var chargeStationID: Int?
            try await createEntity(
                with: app, 
                apiEntityPath: "api/chargestations", 
                andCreator: {
                    ChargeStationDTO(
                        latitude: 56.3, 
                        longitude: 24.4, 
                        title: "111222", 
                        subtitle: "aergaergaergae", 
                        imageSrc: "https://yandex.ru/favico", 
                        phone: "89211234567",
                        workTime: "45",
                        parking: "raergaergaer", 
                        rating: 4, 
                        isFavorite: true, 
                        chargers: [ChargerDTO(
                            plug: 1, 
                            state: 0, 
                            price: "100"
                        )]
                    )
                }, 
                completion: { chargeStation in
                    chargeStationID = chargeStation.id
                }
            )
            #expect(chargeStationID != nil)
            guard let chargeStationID = chargeStationID else { return }
            var charger: ChargerDTO?
            try await createEntity(
                with: app,
                andCreator: {
                    ChargerDTO(
                        plug: 1, 
                        state: 0, 
                        price: "100", 
                        chargeStationId: chargeStationID
                    )
                },
                completion: { newCharger in
                    charger = newCharger
                }
            )
            #expect(charger?.id != nil)
            guard let chargerID = charger?.id else { return }
            #expect(charger?.chargeStationId != nil)
            #expect(charger?.chargeStationId == chargeStationID)
            try await deleteEntity(with: app, andEntityID: chargerID)
        }
    }
}
