import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(
		FileMiddleware(
			publicDirectory: app.directory.publicDirectory,
			defaultFile: "index.html"
		)
	)

	ContentConfiguration.global.use(encoder: CoderFactory.defaultJsonEncoder, for: .json)
    ContentConfiguration.global.use(decoder: CoderFactory.defaultJsonDecoder, for: .json)

    try configureEnvironment(app)

    app.databases.use(
        .postgres(
            configuration: SQLPostgresConfiguration(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
                password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
                database: Environment.get("DATABASE_NAME") ?? "vapor_database",
                tls: .disable
            )
        ), as: .psql
    )

    app.migrations.add(CreateUser())
    app.migrations.add(CreateChargeStation())
    app.migrations.add(CreateChargeHistoryItem())
    app.migrations.add(CreateCharger())
    app.migrations.add(UpdateChargeStation())
    app.migrations.add(UpdateUser())
    app.migrations.add(UserToken.Migration())

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)

    // register routes
    try routes(app)
}
