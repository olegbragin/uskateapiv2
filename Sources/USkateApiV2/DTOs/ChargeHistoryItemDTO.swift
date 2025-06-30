import Fluent
import Vapor

struct ChargeHistoryItemDTO: Content {
    var id: Int?
    var chargeDate: Date
    var energyDelivered: Int
    var duration: Int
    var chargingSpeed: Int
    var totalCost: Decimal
    var chargeStation: ChargeStationDTO?
}