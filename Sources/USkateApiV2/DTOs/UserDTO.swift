import Fluent
import Vapor

struct AdminDTO: Content, Authenticatable {
  var username: String = "vapor_admin"
}

struct UserDTO: Content {
    var id: Int?
    var username: String
    var firstname: String
    var lastname: String
    var isActive: Bool

    init(
      id: Int? = nil,
      username: String, 
      firstname: String = "", 
      lastname: String = "", 
      isActive: Bool = false
    ) {
      self.id = id
      self.username = username
      self.firstname = firstname
      self.lastname = lastname
      self.isActive = isActive
    }
}

extension UserDTO: Authenticatable { }

protocol Confirmable: Content, Validatable {
  var username: String { get }
}

extension Confirmable {
  static func validations(_ validations: inout Validations) {
      validations.add(
        "username", 
        as: String.self, 
        is: 
          !.empty && 
          .pattern(#"^\+?\d{1,4}?[-.\s]?\(?\d{1,3}?\)?[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}$"#) && 
          .count(10...20)
      )
    }
}

extension UserDTO {
  struct SignUp: Confirmable {
    let username: String
    let usernameType: UserNameType
    let firstname: String
    let lastname: String
    let email: String?
  }

  struct SignIn: Confirmable {
    let username: String
    let usernameType: UserNameType
  }

  struct RequestConfirm: Content {
    enum Status: String, Codable {
        case signUp
        case signIn
    }

    let hash: String
    let onetimecode: String
    let status: Status
  }
}

struct AdminDTOAuthenticator: AsyncBearerAuthenticator {
    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
       if bearer.token == "vapor_admin" {
           request.auth.login(AdminDTO(username: "vapor_admin"))
       }
   }
}