import Foundation

struct CoderFactory {
  static var defaultJsonEncoder: JSONEncoder {
    let encoder = JSONEncoder()
	  encoder.outputFormatting = .sortedKeys
    encoder.dateEncodingStrategy = .iso8601

    return encoder
  }

  static var defaultJsonDecoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    return decoder
  }
}