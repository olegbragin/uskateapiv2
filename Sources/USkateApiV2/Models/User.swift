import Fluent
import Vapor

enum UserNameType: String, Codable {
    case phone
}

final class User: Model, @unchecked Sendable {
    static let schema = "user"
    
    @ID(custom: "id")
    var id: Int?

    @Field(key: "firstname")
    var firstname: String

    @Field(key: "lastname")
    var lastname: String

    @Field(key: "username")
    var username: String

    @Field(key: "usernametype")
    var usernametype: String

    @Field(key: "email")
    var email: String?

    @Boolean(key: "isActive")
    var isActive: Bool

    init() { }

    init(
        id: Int? = nil, 
        username: String, 
        usernameType: String = "phone", 
        firstname: String, 
        lastname: String, 
        isActive: Bool = false,
        email: String? = nil
    ) {
        self.id = id
        self.username = username
        self.usernametype = usernameType
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.isActive = isActive
    }
}

extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64, 
            userID: self.requireID()
        )
    }
}