import Fluent
import Vapor

final class ChargeStation: Model, @unchecked Sendable {
    static let schema = "chargestation"
    
    @ID(custom: "id")
    var id: Int?

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Field(key: "title")
    var title: String?

    @Field(key: "subtitle")
    var subtitle: String?

    @Field(key: "imageSrc")
    var imageSrc: String?

    @ID(custom: "rating")
    var rating: Int?

    @Field(key: "isFavorite")
    var isFavorite: Bool?

    @Field(key: "phone")
    var phone: String?

    @Field(key: "workTime")
    var workTime: String?

    @Field(key: "parking")
    var parking: String?

    @Children(for: \.$chargeStation)
    var chargers: [Charger]

    init() { }

    init(
        id: Int? = nil,
        latitude: Double,
        longitude: Double,
        title: String? = nil,
        subtitle: String? = nil,
        imageSrc: String? = nil,
        phone: String? = nil,
        workTime: String? = nil,
        parking: String? = nil,
        rating: Int? = nil,
        isFavorite: Bool? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.subtitle = subtitle
        self.imageSrc = imageSrc
        self.phone = phone
        self.workTime = workTime
        self.parking = parking
        self.rating = rating
        self.isFavorite = isFavorite
    }
}