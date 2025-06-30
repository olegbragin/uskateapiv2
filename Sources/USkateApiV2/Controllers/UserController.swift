import Fluent
import Vapor
import VaporToOpenAPI

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.group("users") { users in
            users.post("signin", use: signIn)
            users.post("signup", use: signUp)
            users.post("confirm", use: confirm)

            let tokenProtected = 
                users
                    .grouped(AdminDTOAuthenticator())
                    .grouped(UserToken.authenticator())
            tokenProtected
                .get(use: index)
                .openAPI(
					summary: "Get all users list",
					description: "This can only be done by the logged in user.",
					body: .type(UserDTO.self),
					contentType: .application(.json),
					response: .type(UserDTO.self),
					responseContentType: .application(.json)
				)
            tokenProtected.get("me", use: me)
            tokenProtected.delete("signout", use: signOut)
            tokenProtected.post(use: create)
            tokenProtected.group(":id") { user in
                user.get(use: info)
                user.patch(use: update)
                user.delete(use: delete)
                
            }
        }
    }

    func me(req: Request) async throws -> UserDTO {
        guard let token = try? req.auth.require(UserToken.self) else {
            throw Abort(.unauthorized)
        }
        let user = try await token.$user.get(on: req.db)
        return UserDTO(
            id: user.id, 
            username: user.username, 
            firstname: user.firstname, 
            lastname: user.lastname, 
            isActive: user.isActive
        )
    }

    func info(req: Request) async throws -> UserDTO {
        guard req.auth.has(AdminDTO.self) || req.auth.has(UserToken.self) else {
            throw Abort(.unauthorized)
        }
        guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }

        return UserDTO(
            id: user.id, 
            username: user.username, 
            firstname: user.firstname, 
            lastname: user.lastname, 
            isActive: user.isActive
        )
    }

    func index(req: Request) async throws -> [UserDTO] {
        guard req.auth.has(AdminDTO.self) || req.auth.has(UserToken.self) else {
            throw Abort(.unauthorized)
        }
        return try await User.query(on: req.db).all().map {
            UserDTO(
                id: $0.id,
                username: $0.username,
                firstname: $0.firstname, 
                lastname: $0.lastname, 
                isActive: $0.isActive
            )
        }
    }

    func create(req: Request) async throws -> UserDTO {
        guard req.auth.has(AdminDTO.self) || req.auth.has(UserToken.self) else {
            throw Abort(.unauthorized)
        }
        var userDTO = try req.content.decode(UserDTO.self)
        let user = User(
            username: userDTO.username,
            firstname: userDTO.firstname, 
            lastname: userDTO.lastname,
            isActive: userDTO.isActive
        )        
        try await user.save(on: req.db)
        userDTO.id = user.id
        return userDTO
    }

    func update(req: Request) async throws -> UserDTO {
        guard req.auth.has(AdminDTO.self) || req.auth.has(UserToken.self) else {
            throw Abort(.unauthorized)
        }
        guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }

        let userDTO = try req.content.decode(UserDTO.self)
        user.firstname = userDTO.firstname
        user.lastname = userDTO.lastname
        user.isActive = userDTO.isActive
        
        try await user.update(on: req.db)
        return userDTO
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard req.auth.has(AdminDTO.self) || req.auth.has(UserToken.self) else {
            throw Abort(.unauthorized)
        }
        try await req.db.transaction { transaction in
            guard
                let user = try await User.find(req.parameters.get("id"), on: transaction),
                let userID = user.id
            else { throw Abort(.notFound) }
            guard let userToken = try await UserToken.query(on: transaction).filter(\.$user.$id == userID).first() else {
                try await user.delete(on: transaction)
                return
            }
            try await userToken.delete(on: transaction)
            try await user.delete(on: transaction)
        }
        return .noContent
    }
}

// MARK: Security

extension UserController {
    func signUp(req: Request) async throws -> UserDTO.RequestConfirm {
        try UserDTO.SignUp.validate(content: req)
        let signUp = try req.content.decode(UserDTO.SignUp.self)
        let onetimecode = generateRandomCode()
        let requestConfirm = [
            "username": signUp.username,
            "usernametype": signUp.usernameType.rawValue,
            "onetimecode": onetimecode,
            "firstname": signUp.firstname,
            "lastname": signUp.lastname,
            "email": signUp.email ?? ""
        ]
        let securityHash = try CoderFactory.defaultJsonEncoder.encode(requestConfirm).base64EncodedString()
        return UserDTO.RequestConfirm(
            hash: securityHash, 
            onetimecode: onetimecode,
            status: .signUp
        )
    }

    func signIn(req: Request) async throws -> UserDTO.RequestConfirm {
        try UserDTO.SignIn.validate(content: req)
        let signIn = try req.content.decode(UserDTO.SignIn.self)
        let onetimecode = generateRandomCode()
        let requestConfirm = [
            "username": signIn.username,
            "usernametype": signIn.usernameType.rawValue,
            "onetimecode": onetimecode
        ]
        let securityHash = try CoderFactory.defaultJsonEncoder.encode(requestConfirm).base64EncodedString()
        return UserDTO.RequestConfirm(
            hash: securityHash, 
            onetimecode: onetimecode,
            status: .signIn
        )
    }

    func confirm(req: Request) async throws -> UserTokenDTO {
        let requestConfirm = try req.content.decode(UserDTO.RequestConfirm.self)
        guard let hashData = Data(base64Encoded: requestConfirm.hash) else {
            throw Abort(.badRequest)
        }
        let hashObject = try CoderFactory.defaultJsonDecoder.decode([String: String].self, from: hashData)
        guard 
            let onetimecode = hashObject["onetimecode"], onetimecode == requestConfirm.onetimecode,
            let username = hashObject["username"]
        else { throw Abort(.unauthorized) }
        switch requestConfirm.status {
            case .signUp:
                let user = User(
                    username: username,
                    firstname: hashObject["firstname"] ?? "",
                    lastname: hashObject["lastname"] ?? "",
                    isActive: true,
                    email: hashObject["email"]
                )        
                try await user.save(on: req.db)
                let token = try user.generateToken()
                try await token.save(on: req.db)
                return UserTokenDTO(
                    value: token.value
                )
            case .signIn:
                guard
                    let user = try await User.query(on: req.db).filter(\.$username == username).first(),
                    let userId = user.id 
                else { throw Abort(.unauthorized) }
                guard let token = try await UserToken.query(on: req.db).filter(\.$user.$id == userId).first() else {
                    let token = try user.generateToken()
                    try await token.save(on: req.db)
                    return UserTokenDTO(
                        value: token.value
                    )
                }
                return UserTokenDTO(
                    value: token.value
                )
        }
    }

    func signOut(req: Request) async throws -> HTTPStatus {
        let userToken = try req.auth.require(UserToken.self)        
        try await userToken.delete(on: req.db)
        return .noContent
    }

    private func generateRandomCode() -> String {
        [UInt8].random(count: 6, in: 0..<10).map(String.init).joined(separator: "")
    }
}

extension Array where Element: FixedWidthInteger {
    public static func random(count: Int, in range: Range<Element>) -> [Element] {
        var array: [Element] = .init(repeating: 0, count: count)
        (0..<count).forEach { array[$0] = Element.random(in: range) }
        return array
    }
}