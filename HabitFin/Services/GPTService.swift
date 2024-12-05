import Foundation

class GPTService {
    private let apiKey: String

    init() {
        // Retrieve the API key from Info.plist
        guard let apiKey = Bundle.main.infoDictionary?["GPT_API_KEY"] as? String else {
            fatalError("GPT API Key is missing. Please ensure it is configured in the Config.xcconfig file and Info.plist.")
        }
        self.apiKey = apiKey
    }

    func processReceiptText(_ text: String, completion: @escaping ([Item]) -> Void) {
        // Define the function schema
        let function = Function(
            name: "extract_purchased_items",
            description: "Extracts purchased items from a receipt text.",
            parameters: Function.Parameters(
                type: "object",
                properties: [
                    "items": .init(
                        type: "array",
                        items: Function.PropertyDetails(
                            type: "object",
                            properties: [
                                "name": Function.PropertyDetails(type: "string"),
                                "category": Function.PropertyDetails(type: "string"),
                                "quantity": Function.PropertyDetails(type: "integer"),
                                "price": Function.PropertyDetails(type: "number"),
                                "total": Function.PropertyDetails(type: "number"),
                                "discount": Function.PropertyDetails(type: "number")
                            ],
                            required: ["name", "quantity", "price", "total"]
                        )
                    )
                ],
                required: ["items"]
            )
        )



        // Prepare the request
        let request = StructuredRequest(
            model: "gpt-4o-mini",
            messages: [
                .init(role: "user", content: "Extract purchased items from the following receipt text: \(text)")
            ],
            functions: [function],
            function_call: .init(name: "extract_purchased_items"),
            temperature: 0.0,
            max_tokens: 500
        )

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid API URL")
            completion([])
            return
        }

        do {
            let jsonData = try JSONEncoder().encode(request)

            // Create URLRequest
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = jsonData

            // Perform network request
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    completion([])
                    return
                }

                guard let data = data else {
                    print("No data received")
                    completion([])
                    return
                }

                // Parse response
                do {
                    let decoder = JSONDecoder()
                    let apiResponse = try decoder.decode(APIResponse.self, from: data)

                    // Extract and parse function call arguments
                    if let functionCall = apiResponse.choices.first?.message.function_call,
                       let argumentsData = functionCall.arguments.data(using: .utf8) {
                        let itemsResponse = try decoder.decode(ItemsResponse.self, from: argumentsData)

                        // Convert to domain model
                        let items = itemsResponse.items.map {
                            Item(
                                name: $0.name,
                                category: $0.category,
                                quantity: $0.quantity,
                                price: $0.price,
                                total: $0.total,
                                discount: $0.discount ?? 0
                            )
                        }

                        completion(items)
                    } else {
                        print("No function call arguments found in the response")
                        completion([])
                    }
                } catch {
                    print("Parsing error: \(error)")
                    completion([])
                }
            }

            task.resume()
        } catch {
            print("JSON encoding error: \(error)")
            completion([])
        }
    }
}

// Supporting structures
struct StructuredRequest: Codable {
    let model: String
    let messages: [Message]
    let functions: [Function]
    let function_call: FunctionCall
    let temperature: Double
    let max_tokens: Int
}

struct Message: Codable {
    let role: String
    let content: String
}

struct Function: Codable {
    let name: String
    let description: String
    let parameters: Parameters

    struct Parameters: Codable {
        let type: String
        let properties: [String: Property]
        let required: [String]

        struct Property: Codable {
            let type: String
            let items: PropertyDetails?
            let properties: [String: PropertyDetails]?
            let required: [String]?
            let `default`: Double?

            init(type: String, items: PropertyDetails? = nil, properties: [String: PropertyDetails]? = nil, required: [String]? = nil, default: Double? = nil) {
                self.type = type
                self.items = items
                self.properties = properties
                self.required = required
                self.default = `default`
            }
        }
    }

    struct PropertyDetails: Codable {
        let type: String
        let properties: [String: PropertyDetails]?
        let required: [String]?

        init(type: String, properties: [String: PropertyDetails]? = nil, required: [String]? = nil) {
            self.type = type
            self.properties = properties
            self.required = required
        }
    }
}



struct FunctionCall: Codable {
    let name: String
}

struct APIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: MessageContent
}

struct MessageContent: Codable {
    let function_call: FunctionCallArguments?
}

struct FunctionCallArguments: Codable {
    let arguments: String
}

struct ItemsResponse: Codable {
    let items: [ItemDTO]
}

