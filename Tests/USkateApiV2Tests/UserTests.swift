@testable import USkateApiV2
import VaporTesting
import Testing
import Fluent

@Suite("User Tests with DB", .serialized)
struct UserTests: EntityTestable {
    var apiPath: String {
        "api/users"
    }

    var isProtected: Bool {
        true
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

    @Test("Getting all Users")
    func testUsers() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, apiPath, 
                beforeRequest: { req in 
                    req.headers.bearerAuthorization = .init(token: "vapor_admin") 
                }, 
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )
        }
    }

    @Test("Creating a User")
    func testCreateUser() async throws {
        try await withApp { app in
            let newUser = UserDTO(
                username: "key",
                firstname: "Kate", 
                lastname: "Bragina", 
                isActive: false
            )
            var userID: Int?
            try await createEntity(
                with: app, 
                andCreator: {
                    newUser
                }, completion: { user in
                    userID = user.id
                    #expect(user.id != nil)
                    #expect(user.firstname == "Kate")
                }
            )
            #expect(userID != nil)
            guard let userID = userID else { return }
            try await deleteEntity(with: app, andEntityID: userID)
        }
    }

    @Test("Updating a User")
    func testUpdateUser() async throws {
        try await withApp { app in
            let newUser = UserDTO(
                username: "keyf",
                firstname: "Kate", 
                lastname: "Bragina", 
                isActive: false
            )
            var userID: Int?
            try await createEntity(
                with: app, 
                andCreator: {
                    newUser
                },
                completion: { user in
                    userID = user.id
                }
            )
            #expect(userID != nil)
            guard let userID = userID else { return }
            try await app.testing().test(.PATCH, "\(apiPath)/\(userID)", 
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: "vapor_admin")
                    let updatedUser = UserDTO(
                        username: "key",
                        firstname: "Oleg", 
                        lastname: "Bragin", 
                        isActive: true
                    )
                    try req.content.encode(updatedUser)
                }, 
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let user = try res.content.decode(UserDTO.self)
                    #expect(user.isActive == true)
                    #expect(user.firstname == "Oleg")
                }
            )
            try await deleteEntity(with: app, andEntityID: userID)
        }
    }
}
