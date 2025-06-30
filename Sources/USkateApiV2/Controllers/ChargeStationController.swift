import Fluent
import Vapor

struct ChargeStationController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.group("chargestations") { chargeStations in
            chargeStations.get(use: index)

            chargeStations.post(use: create)

            chargeStations.group(":id") { chargeStation in
                chargeStation.patch(use: update)
                chargeStation.delete(use: delete)
            }
        }
    }

    func index(req: Request) async throws -> [ChargeStationDTO] {
        let chargeStations = try await ChargeStation.query(on: req.db).sort(\.$id, .descending).all()
        var result = [ChargeStationDTO]()
        for chargeStation in chargeStations {
            let chargers = try await chargeStation.$chargers.get(on: req.db).map { charger in
                ChargerDTO(
                    id: charger.id,
                    plug: charger.plug, 
                    state: charger.state, 
                    price: charger.price
                )
            }
            result.append(
                ChargeStationDTO(
                    id: chargeStation.id,
                    latitude: chargeStation.latitude, 
                    longitude: chargeStation.longitude, 
                    title: chargeStation.title, 
                    subtitle: chargeStation.subtitle, 
                    imageSrc: chargeStation.imageSrc, 
                    phone: chargeStation.phone,
                    workTime: chargeStation.workTime,
                    parking: chargeStation.parking,
                    rating: chargeStation.rating, 
                    isFavorite: chargeStation.isFavorite,
                    chargers: chargers
                )
            )
        }
        return result
    }

    func create(req: Request) async throws -> ChargeStationDTO {
        var chargeStationDTO = try req.content.decode(ChargeStationDTO.self)
        let chargeStation = ChargeStation()
        chargeStation.latitude = chargeStationDTO.latitude
        chargeStation.longitude = chargeStationDTO.longitude
        chargeStation.title = chargeStationDTO.title
        chargeStation.subtitle = chargeStationDTO.subtitle
        chargeStation.imageSrc = chargeStationDTO.imageSrc
        chargeStation.phone = chargeStationDTO.phone
        chargeStation.workTime = chargeStationDTO.workTime
        chargeStation.parking = chargeStationDTO.parking
        chargeStation.rating = chargeStationDTO.rating
        chargeStation.isFavorite = chargeStationDTO.isFavorite
        
        try await chargeStation.create(on: req.db)
        chargeStationDTO.id = chargeStation.id
        return chargeStationDTO
    }

    func update(req: Request) async throws -> ChargeStationDTO {
        guard let chargeStation = try await ChargeStation.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }

        let chargeStationDTO = try req.content.decode(ChargeStationDTO.self)
        chargeStation.latitude = chargeStationDTO.latitude
        chargeStation.longitude = chargeStationDTO.longitude
        chargeStation.title = chargeStationDTO.title
        chargeStation.subtitle = chargeStationDTO.subtitle
        chargeStation.imageSrc = chargeStationDTO.imageSrc
        chargeStation.phone = chargeStationDTO.phone
        chargeStation.workTime = chargeStationDTO.workTime
        chargeStation.parking = chargeStationDTO.parking
        chargeStation.rating = chargeStationDTO.rating
        chargeStation.isFavorite = chargeStationDTO.isFavorite

        try await chargeStation.update(on: req.db)
        return chargeStationDTO
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let chargeStation = try await ChargeStation.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await chargeStation.delete(on: req.db)
        return .noContent
    }
}
