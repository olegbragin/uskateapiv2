import Fluent
import Vapor

struct ChargerDTO: Content {
    var id: Int?
    var plug: Int
    var state: Int
    var price: String
    var chargeStationId: ChargeStation.IDValue?
}