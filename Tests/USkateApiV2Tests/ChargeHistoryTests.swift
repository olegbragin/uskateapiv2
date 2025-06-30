@testable import USkateApiV2
import VaporTesting
import Testing
import Fluent

@Suite("Charge history Tests with DB", .serialized)
struct ChargeHistoryItemTests: EntityTestable {
    var apiPath: String {
        "api/chargehistory"
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

    @Test("Getting all charge history")
    func testChargeHistoryItem() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, apiPath, 
                afterResponse: { res in
                    #expect(res.status == .ok)
                }
            )
        }
    }

    @Test("Creating charge history item")
    func testCreateChargeHistoryItem() async throws {
        try await withApp { app in
            var chargeStation: ChargeStationDTO?
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
                completion: { newChargeStation in
                    chargeStation = newChargeStation
                }
            )
            #expect(chargeStation != nil)
            guard let chargeStation = chargeStation else { return }
            var chargeHistoryItemID: Int? 
            try await createEntity(
                with: app, 
                andCreator: {
                    ChargeHistoryItemDTO(
                        chargeDate: Date(), 
                        energyDelivered: 1000, 
                        duration: 34, 
                        chargingSpeed: 34, 
                        totalCost: 45644.7,
                        chargeStation: chargeStation
                    )
                }, 
                completion: { chargeHistoryItem in
                    #expect(chargeHistoryItem.energyDelivered == 1000)
                    chargeHistoryItemID = chargeHistoryItem.id
                }
            )
            #expect(chargeHistoryItemID != nil)
            guard let chargeHistoryItemID = chargeHistoryItemID else { return }
            try await deleteEntity(with: app, andEntityID: chargeHistoryItemID)
            guard let chargeStationID = chargeStation.id else { return }
            try await deleteEntity(with: app, apiEntityPath: "api/chargestations", andEntityID: chargeStationID)
        }
    }

    @Test("Updating charge history item")
    func testUpdateUnattachedCharger() async throws {
        try await withApp { app in
            var chargeStation: ChargeStationDTO?
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
                completion: { newChargeStation in
                    chargeStation = newChargeStation
                }
            )
            #expect(chargeStation != nil)
            guard let chargeStation = chargeStation else { return }
            var chargeHistoryItemID: Int? 
            try await createEntity(
                with: app, 
                andCreator: { 
                    ChargeHistoryItemDTO(
                        chargeDate: Date(), 
                        energyDelivered: 1000, 
                        duration: 34, 
                        chargingSpeed: 34, 
                        totalCost: 45644.7,
                        chargeStation: chargeStation
                    )
                },
                completion: { chargeHistoryItem in
                    chargeHistoryItemID = chargeHistoryItem.id
                }
            )
            #expect(chargeHistoryItemID != nil)
            guard let chargeHistoryItemID = chargeHistoryItemID else { return }
            try await app.testing().test(.PATCH, "\(apiPath)/\(chargeHistoryItemID)", 
                beforeRequest: { req in
                    let updatedChargeHistoryItem = ChargeHistoryItemDTO(
                        chargeDate: Date(), 
                        energyDelivered: 2000, 
                        duration: 34, 
                        chargingSpeed: 34, 
                        totalCost: 45644.7,
                        chargeStation: chargeStation
                    )
                    try req.content.encode(updatedChargeHistoryItem)
                }, 
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let chargeHistoryItemDTO = try res.content.decode(ChargeHistoryItemDTO.self)
                    #expect(chargeHistoryItemDTO.energyDelivered == 2000)
                }
            )
            try await deleteEntity(with: app, andEntityID: chargeHistoryItemID)
            guard let chargeStationID = chargeStation.id else { return }
            try await deleteEntity(with: app, apiEntityPath: "api/chargestations", andEntityID: chargeStationID)
        }
    }
}
