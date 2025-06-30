import Fluent
import Vapor

struct ChargeStationDTO: Content {
    var id: Int?
    var latitude: Double?
    var longitude: Double?
    var title: String?
    var subtitle: String?
    var imageSrc: String?
    var phone: String?
    var workTime: String?
    var parking: String?
    var rating: Int?
    var isFavorite: Bool?
    var chargers: [ChargerDTO]?
}