
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
        var result = [ChargeHistoryItemDTO]()
        for chargeHistoryItem in chargeHistory {
            let chargeStation = try await chargeHistoryItem.$chargeStation.get(on: req.db)
            let chargers = try await chargeStation?.$chargers.get(on: req.db).map { charger in
                ChargerDTO(
                    id: charger.id,
                    plug: charger.plug, 
                    state: charger.state, 
                    price: charger.price
                )
            }
            result.append(
                ChargeHistoryItemDTO(
                    id: chargeHistoryItem.id,
                    chargeDate: chargeHistoryItem.chargeDate, 
                    energyDelivered: chargeHistoryItem.energyDelivered, 
                    duration: chargeHistoryItem.duration, 
                    chargingSpeed: chargeHistoryItem.chargingSpeed, 
                    totalCost: chargeHistoryItem.totalCost,
                    chargeStation: chargeStation.map {
                        ChargeStationDTO(
                            id: $0.id, 
                            latitude: $0.latitude, 
                            longitude: $0.longitude, 
                            title: $0.title, 
                            subtitle: $0.subtitle, 
                            imageSrc: $0.imageSrc, 
                            phone: $0.phone, 
                            workTime: $0.workTime, 
                            parking: $0.parking, 
                            rating: $0.rating, 
                            isFavorite: $0.isFavorite, 
                            chargers: chargers
                        )
                    }
                )
            )
        }
        return result
    }

    func create(req: Request) async throws -> ChargeHistoryItemDTO {
        var chargeHistoryItemDTO = try req.content.decode(ChargeHistoryItemDTO.self)
        let chargeHistoryItem = ChargeHistoryItem(
            chargeDate: chargeHistoryItemDTO.chargeDate, 
            energyDelivered: chargeHistoryItemDTO.energyDelivered, 
            duration: chargeHistoryItemDTO.duration, 
            chargingSpeed: chargeHistoryItemDTO.chargingSpeed, 
            totalCost: chargeHistoryItemDTO.totalCost,
            chargeStationID: chargeHistoryItemDTO.chargeStation?.id
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
        chargeHistoryItem.$chargeStation.id = chargeHistoryItemDTO.chargeStation?.id
        
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
