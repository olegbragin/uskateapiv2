import Fluent
import Vapor

struct ChargerController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.group("chargers") { chargers in
            chargers.get(use: index)

            chargers.post(use: create)

            chargers.group(":id") { charger in
                charger.patch(use: update)
                charger.delete(use: delete)
            }
        }
    }

    func index(req: Request) async throws -> [ChargerDTO] {
        let chargers = try await Charger.query(on: req.db).all()
        return chargers.map {
            ChargerDTO(
                id: $0.id, 
                plug: $0.plug, 
                state: $0.state, 
                price: $0.price, 
                chargeStationId: $0.$chargeStation.id
            )
        }
    }

    func create(req: Request) async throws -> ChargerDTO {
        var chargerDTO = try req.content.decode(ChargerDTO.self)
        let charger = Charger(
            plug: chargerDTO.plug, 
            state: chargerDTO.state, 
            price: chargerDTO.price, 
            chargeStationID: chargerDTO.chargeStationId
        )        
        try await charger.save(on: req.db)
        chargerDTO.id = charger.id
        return chargerDTO
    }

    func update(req: Request) async throws -> ChargerDTO {
        guard let charger = try await Charger.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }

        let chargerDTO = try req.content.decode(ChargerDTO.self)
        charger.plug = chargerDTO.plug
        charger.state = chargerDTO.state
        charger.price = chargerDTO.price
        charger.$chargeStation.id = chargerDTO.chargeStationId
        
        try await charger.update(on: req.db)
        return chargerDTO
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let charger = try await Charger.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await charger.delete(on: req.db)
        return .noContent
    }
}
