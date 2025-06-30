@testable import USkateApiV2
import VaporTesting
import Testing
import Fluent

@Suite("Authentication Tests", .serialized)
struct AuthenticationTests: EntityTestable {
    var apiPath: String {
        "api/users"
    }

    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("Test Sign Out")
    func testSignOut() async throws {
        try await withApp { app in
            try await signUpUser(
                app: app, 
                afterSignUp: { userID, token in
                    try await app.testing().test(.DELETE, "\(apiPath)/signout", 
                        beforeRequest: { req in
                            req.headers.bearerAuthorization = .init(token: token)
                        }, 
                        afterResponse: { res in
                            #expect(res.status == .noContent)
                        }
                    )

                    try await deleteEntity(
                        with: app, 
                        executeAsAdmin: true,
                        andEntityID: userID
                    )
                }
            )
        }
    }

    @Test("Test Sign In")
    func testSignIn() async throws {
        try await withApp { app in
            try await signUpUser(
                app: app, 
                afterSignUp: { userID, token in
                    try await app.testing().test(.DELETE, "\(apiPath)/signout", 
                        beforeRequest: { req in
                            req.headers.bearerAuthorization = .init(token: token)
                        }, 
                        afterResponse: { res in
                            #expect(res.status == .noContent)
                        }
                    )

                    var oneTimeCode: String?
                    var hash: String?

                    try await app.testing().test(.POST, "api/users/signin", 
                        beforeRequest: { req in
                            let newUser = UserDTO.SignIn(
                                username: "+79211234567",
                                usernameType: .phone
                            )
                            try req.content.encode(newUser)
                        }, 
                        afterResponse: { res in
                            #expect(res.status == .ok)
                            let confirm = try res.content.decode(UserDTO.RequestConfirm.self)
                            oneTimeCode = confirm.onetimecode
                            hash = confirm.hash
                        }
                    )

                    #expect(hash != nil)
                    #expect(oneTimeCode != nil)
                    
                    guard let oneTimeCode = oneTimeCode, let hash = hash else { return }

                    var token: String?
                    try await app.testing().test(.POST, "api/users/confirm", 
                        beforeRequest: { req in
                            let confirm = UserDTO.RequestConfirm(
                                hash: hash, 
                                onetimecode: oneTimeCode, 
                                status: .signIn
                            )
                            try req.content.encode(confirm)
                        }, 
                        afterResponse: { res in
                            #expect(res.status == .ok)
                            let userToken = try res.content.decode(UserTokenDTO.self)
                            token = userToken.value
                        }
                    )

                    #expect(token != nil)

                    guard let token = token else { return }

                    var userID: Int?
                    try await app.testing().test(.GET, "api/users/me", 
                        beforeRequest: { req in
                            req.headers.bearerAuthorization = .init(token: token)
                        }, 
                        afterResponse: { res in
                            #expect(res.status == .ok)
                            let user = try res.content.decode(UserDTO.self)
                            userID = user.id
                        }
                    )

                    #expect(userID != nil)
                    guard let userID = userID else { return }
                    try await deleteEntity(with: app, andEntityID: userID)
                }
            )
        }
    }

    func testUsers_Unauthorized() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "api/users", 
                afterResponse: { res in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    private func signUpUser(app: Application, afterSignUp: (Int, String) async throws -> Void) async throws {
        var oneTimeCode: String?
        var hash: String?

        try await app.testing().test(.POST, "api/users/signup", 
            beforeRequest: { req in
                let newUser = UserDTO.SignUp(
                    username: "+79211234567",
                    usernameType: UserNameType.phone,
                    firstname: "Kate", 
                    lastname: "Bragina",
                    email: "egergagr@aergerge.com"
                )
                try req.content.encode(newUser)
            }, 
            afterResponse: { res in
                #expect(res.status == .ok)
                let confirm = try res.content.decode(UserDTO.RequestConfirm.self)
                oneTimeCode = confirm.onetimecode
                hash = confirm.hash
            }
        )
        #expect(hash != nil)
        #expect(oneTimeCode != nil)

        guard let oneTimeCode = oneTimeCode, let hash = hash else { return }
        var token: String?

        try await app.testing().test(.POST, "api/users/confirm", 
            beforeRequest: { req in
                let confirm = UserDTO.RequestConfirm(
                    hash: hash, 
                    onetimecode: oneTimeCode, 
                    status: .signUp
                )
                try req.content.encode(confirm)
            }, 
            afterResponse: { res in
                #expect(res.status == .ok)
                let userToken = try res.content.decode(UserTokenDTO.self)
                token = userToken.value
            }
        )

        #expect(token != nil)
        guard let token = token else { return }
        var userID: Int?

        try await app.testing().test(.GET, "api/users/me", 
            beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserDTO.self)
                userID = user.id
            }
        )
        #expect(userID != nil)
        guard let userID = userID else { return }

        try await afterSignUp(userID, token)
    }
}
