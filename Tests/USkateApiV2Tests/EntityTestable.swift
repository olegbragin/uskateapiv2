@testable import USkateApiV2
import VaporTesting
import Testing
import Fluent

protocol EntityTestable {
    var apiPath: String { get }
    var isProtected: Bool { get }

    func createEntity<TEntity: Content>(
        with app: Application, 
        apiEntityPath: String?,
        andCreator newEntity: () -> TEntity, 
        completion: (TEntity) async throws -> ()
    ) async throws
    func deleteEntity(
        with app: Application,
        apiEntityPath: String?,
        executeAsAdmin: Bool,
        andEntityID entityID: Int
    ) async throws
}

extension EntityTestable {
    var isProtected: Bool {
        false
    }

    func createEntity<TEntity: Content>(
        with app: Application,
        apiEntityPath: String? = nil,
        andCreator newEntity: () -> TEntity, 
        completion: (TEntity) async throws -> ()
    ) async throws {
        try await app.testing().test(.POST, apiEntityPath ?? apiPath, 
            beforeRequest: { req in 
                if isProtected {
                    req.headers.bearerAuthorization = .init(token: "vapor_admin")
                }
                try req.content.encode(newEntity())
            }, 
            afterResponse: { res async throws in
                #expect(res.status == .ok)
                let entity = try res.content.decode(TEntity.self)
                try await completion(entity)
            }
        )
    } 

    func deleteEntity(
        with app: Application,
        apiEntityPath: String? = nil,
        executeAsAdmin: Bool = false,
        andEntityID entityID: Int
    ) async throws {
        try await app.testing().test(.DELETE, "\(apiEntityPath ?? apiPath)/\(entityID)", 
            beforeRequest: { req in
                if executeAsAdmin || isProtected {
                    req.headers.bearerAuthorization = .init(token: "vapor_admin")
                }
            }, 
            afterResponse: { res in
                #expect(res.status == .noContent)
            }
        )
    }
}