@testable import USkateApiV2
import VaporTesting
import Testing
import Fluent

@Suite("Charge Station Tests with DB", .serialized)
struct ChargeStationTests: EntityTestable {
    var apiPath: String {
        "api/chargestations"
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

    @Test("Getting all Users")
    func testChargeStation() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, apiPath, 
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )
        }
    }

    @Test("Creating a charge station")
    func testCreateChargeStation() async throws {
        try await withApp { app in
            let newChargeStation = ChargeStationDTO(
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
            var chargeStationID: Int?
            try await createEntity(
                with: app, 
                andCreator: {
                    newChargeStation
                },
                completion: { chargeStation in
                    #expect(chargeStation.title == "111222")
                    chargeStationID = chargeStation.id
                }
            )
            #expect(chargeStationID != nil)
            guard let chargeStationID = chargeStationID else { return }
            try await deleteEntity(with: app, andEntityID: chargeStationID)
        }
    }

    @Test("Updating a charge station")
    func testUpdateChargeStation() async throws {
        try await withApp { app in
            let newChargeStation = ChargeStationDTO(
                latitude: 56.3, 
                longitude: 24.4, 
                title: "111222", 
                subtitle: "aergaergaergae", 
                imageSrc: "https://yandex.ru/favico", 
                phone: "89211234567",
                workTime: "45",
                parking: "raergaergaer", 
                rating: 4, 
                isFavorite: true
            )
            var chargeStationID: Int?
            try await createEntity(
                with: app, 
                andCreator: { 
                    newChargeStation
                },
                completion: { chargeStation in
                    chargeStationID = chargeStation.id
                }
            )
            #expect(chargeStationID != nil)
            guard let chargeStationID = chargeStationID else { return }
            try await app.testing().test(.PATCH, "\(apiPath)/\(chargeStationID)", 
                beforeRequest: { req in
                    let updatedChargeStationDTO = ChargeStationDTO(
                        latitude: 56.3, 
                        longitude: 24.4, 
                        title: "2223334555", 
                        subtitle: "aergaergaergae111111", 
                        imageSrc: "https://vk.com/favico", 
                        phone: "89211234567",
                        workTime: "45",
                        parking: "raergaergaer", 
                        rating: 1, 
                        isFavorite: false
                    )
                    try req.content.encode(updatedChargeStationDTO)
                }, 
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let chargeStation = try res.content.decode(ChargeStationDTO.self)
                    #expect(chargeStation.title == "2223334555")
                }
            )
            try await deleteEntity(with: app, andEntityID: chargeStationID)
        }
    }
}
