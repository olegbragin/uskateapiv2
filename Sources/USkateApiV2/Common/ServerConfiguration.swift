import Vapor
import NIOSSL

func configureEnvironment(_ app: Application) throws {
    // Enable TLS.
    switch app.environment {
        case .testing, .development:
            break
        default: 
            try app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
                certificateChain: [
                    .certificate(.init(
                        file: "/etc/letsencrypt/live/sharenergy.online/fullchain.pem",
                        format: .pem
                    ))
                ],
                privateKey: .privateKey(.init(file: "/etc/letsencrypt/live/sharenergy.online/privkey.pem", format: .pem))
            )
    }
}