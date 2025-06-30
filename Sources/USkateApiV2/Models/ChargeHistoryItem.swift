import Fluent
import Vapor

final class ChargeHistoryItem: Model, @unchecked Sendable {
    static let schema = "chargehistoryitem"
    
    @ID(custom: "id")
    var id: Int?

    @Field(key: "chargeDate")
    var chargeDate: Date

    @Field(key: "energyDelivered")
    var energyDelivered: Int

    @Field(key: "duration")
    var duration: Int

    @Field(key: "chargingSpeed")
    var chargingSpeed: Int

    @Field(key: "totalCost")
    var totalCost: Decimal

    @OptionalParent(key: "chargestation_id")
    var chargeStation: ChargeStation?

    init() { }

    init(
        id: Int? = nil, 
        chargeDate: Date, 
        energyDelivered: Int,
        duration: Int,
        chargingSpeed: Int,
        totalCost: Decimal,
        chargeStationID: ChargeStation.IDValue? = nil
    ) {
        self.id = id
        self.chargeDate = chargeDate
        self.energyDelivered = energyDelivered
        self.duration = duration
        self.chargingSpeed = chargingSpeed
        self.totalCost = totalCost
        self.$chargeStation.id = chargeStationID
    }
}