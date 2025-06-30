import Vapor

struct UserTokenDTO: Content, Authenticatable {
  let value: String
}