import Foundation
import Vapor
import VaporToOpenAPI

struct OpenApiController: RouteCollection {

	// MARK: Internal

	func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.get("swagger", "swagger.json", use: self.swagger).excludeFromOpenAPI()

        // Generate a Stoplight page with the OpenAPI documentation
        routes.stoplightDocumentation(
            "stoplight",
            openAPIPath: "api/swagger/swagger.json"
        )
    }

    @Sendable
    func swagger(req: Request) async throws -> OpenAPIObject {
        req.application.routes.openAPI(
            info: InfoObject(
                title: "Swagger Petstore - OpenAPI 3.0",
                description: "This is a sample Charge Station Server based on the OpenAPI 3.0.1 specification.",
                termsOfService: URL(string: "http://swagger.io/terms/"),
                contact: ContactObject(
                    email: "apiteam@swagger.io"
                ),
                license: LicenseObject(
                    name: "Apache 2.0",
                    url: URL(string: "http://www.apache.org/licenses/LICENSE-2.0.html")
                ),
                version: Version(1, 0, 17)
            ),
            externalDocs: ExternalDocumentationObject(
                description: "Find out more about Swagger",
                url: URL(string: "http://swagger.io")!
            )
        )
    }
}