
import Fluent
import Vapor

struct ChargeHistoryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")

        api.group("chargehistory") { chargeHistory in
            chargeHistory.get(use: index)

            chargeHistory.post(use: create)

            chargeHistory.group(":id") { chargeHistoryItem in
                chargeHistoryItem.patch(use: update)
                chargeHistoryItem.delete(use: delete)
            }
        }
    }

    func index(req: Request) async throws -> [ChargeHistoryItemDTO] {
        let chargeHistory = try await ChargeHistoryItem.query(on: req.db).all()
        return chargeHistory.map {
            ChargeHistoryItemDTO(
                chargeDate: $0.chargeDate, 
                energyDelivered: $0.energyDelivered, 
                duration: $0.duration, 
                chargingSpeed: $0.chargingSpeed, 
                totalCost: $0.totalCost,
                chargeStationId: $0.$chargeStation.id
            )
        }
    }

    func create(req: Request) async throws -> ChargeHistoryItemDTO {
        var chargeHistoryItemDTO = try req.content.decode(ChargeHistoryItemDTO.self)
        let chargeHistoryItem = ChargeHistoryItem(
            chargeDate: chargeHistoryItemDTO.chargeDate, 
            energyDelivered: chargeHistoryItemDTO.energyDelivered, 
            duration: chargeHistoryItemDTO.duration, 
            chargingSpeed: chargeHistoryItemDTO.chargingSpeed, 
            totalCost: chargeHistoryItemDTO.totalCost,
            chargeStationID: chargeHistoryItemDTO.chargeStationId
        )        
        try await chargeHistoryItem.save(on: req.db)
        chargeHistoryItemDTO.id = chargeHistoryItem.id
        return chargeHistoryItemDTO
    }

    func update(req: Request) async throws -> ChargeHistoryItemDTO {
        guard let chargeHistoryItem = try await ChargeHistoryItem.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }

        let chargeHistoryItemDTO = try req.content.decode(ChargeHistoryItemDTO.self)
        chargeHistoryItem.chargeDate = chargeHistoryItemDTO.chargeDate
        chargeHistoryItem.energyDelivered = chargeHistoryItemDTO.energyDelivered
        chargeHistoryItem.duration = chargeHistoryItemDTO.duration
        chargeHistoryItem.chargingSpeed = chargeHistoryItemDTO.chargingSpeed
        chargeHistoryItem.totalCost = chargeHistoryItemDTO.totalCost
        chargeHistoryItem.$chargeStation.id = chargeHistoryItemDTO.chargeStationId
        
        try await chargeHistoryItem.update(on: req.db)
        return chargeHistoryItemDTO
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let chargeHistoryItem = try await ChargeHistoryItem.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await chargeHistoryItem.delete(on: req.db)
        return .noContent
    }
}
