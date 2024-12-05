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

    func processReceiptText(_ text: String, completion: @escaping (Receipt?) -> Void) {
        // Define the function schema with updated fields
        let function = Function(
            name: "extract_receipt_details",
            description: "Extracts details from a receipt text.",
            parameters: Function.Parameters(
                type: "object",
                properties: [
                    "storeName": .init(type: "string"),
                    "date": .init(type: "string"),
                    "total": .init(type: "number"),
                    "paymentType": .init(type: "string"),
                    "discountsTotal": .init(type: "number"),
                    "currency": .init(type: "string"),
                    "items": .init(
                        type: "array",
                        items: Function.PropertyDetails(
                            type: "object",
                            properties: [
                                "name": Function.PropertyDetails(type: "string"),
                                "category": Function.PropertyDetails(type: "string"),
                                "quantity": Function.PropertyDetails(type: "number"),
                                "price": Function.PropertyDetails(type: "number"),
                                "total": Function.PropertyDetails(type: "number")
                            ],
                            required: ["name", "quantity", "price", "total"]
                        )
                    )
                ],
                required: ["storeName", "date", "total", "items", "discountsTotal", "currency"]
            )
        )

        let prompt = """
        Extract all receipt details from the following OCR text. The details should include:
        - Store Name: Identify the most probable store name. If the name seems incorrect, infer a logical name or a known brand.
        - Date: Extract the date and time in ISO 8601 format (e.g., YYYY-MM-DDTHH:mm:ssZ), ensuring it includes both the date and time.
        - Total Amount: Identify the total amount paid, ensuring it's the final sum after discounts and taxes.
        - Items: List all purchased items with their quantities and prices. Correct misinterpreted item names to the closest logical or brand names.
        - Payment Type: Identify the payment method (e.g., credit card, cash, etc.) based on keywords in the text.
        - Discounts: Identify all discounts, including those with minus signs or hyphens before or after the number, and ensure they are subtracted from the total amount. Examples are 30 - or 30- would both be counted as discount due to the minus after the number. -30 as well. Also try to identify contextual following numbers after for example a word that indicates discounts!
        - For discounts assume that words like trophy, Bon, Rabatt, Discount, etc are discounts!
        - Make sure for the totalDiscounts to sum up all discounts you find! So all that match the above point.
        - For quantity take into account that it's not always whole numbers, they might be grams or other sort of quantity on the receipt, just take the one that is written OR add up all occurences.
        - Make sure to take the price that it says on the receipt, don't multiply it for quantitiy adjustment! (There should ALWAYS be a number on the receipt reflecting that!)
        
        - Make sure the currency is the official sign or abrev.
        - If no currency is available you can infer a currency from country/context or just provide dollar sign    

        Note: The OCR text may be disorganized or contain errors due to scanning issues. Use context and logical inference to reorganize and interpret the data accurately.
        - Look for patterns like numerical values next to "total," "subtotal," "discount," or item names.
        - If discounts are inconsistently formatted (e.g., "-5.00" or "5.00-"), treat them all as valid discounts and ensure they are properly applied.
        - Infer missing or ambiguous information when possible, but note it explicitly as inferred.

        Here's the OCR receipt text:
        """

        
        // Prepare the request
        let request = StructuredRequest(
            model: "gpt-4o-mini",
            messages: [
                .init(role: "user", content: "\(prompt) \(text)")
            ],
            functions: [function],
            function_call: .init(name: "extract_receipt_details"),
            temperature: 0.0,
            max_tokens: 500
        )

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid API URL")
            completion(nil)
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
                    completion(nil)
                    return
                }

                guard let data = data else {
                    print("No data received")
                    completion(nil)
                    return
                }

                // Parse response
                do {
                    let decoder = JSONDecoder()
                    let apiResponse = try decoder.decode(APIResponse.self, from: data)

                    // Extract and parse function call arguments
                    if let functionCall = apiResponse.choices.first?.message.function_call,
                       let argumentsData = functionCall.arguments.data(using: .utf8) {
                        let receiptResponse = try decoder.decode(ReceiptDTO.self, from: argumentsData)

                        // Convert to domain model
                        let items = receiptResponse.items.map {
                            Item(
                                name: $0.name,
                                category: $0.category,
                                quantity: $0.quantity,
                                price: $0.price,
                                total: $0.total
                            )
                        }
                        
                        

                        let receipt = Receipt(
                            date: ISO8601DateFormatter().date(from: receiptResponse.date),
                            items: items,
                            total: receiptResponse.total,
                            paymentType: receiptResponse.paymentType ?? "Unknown",
                            discountsTotal: receiptResponse.discountsTotal ?? 0.0,
                            storeName: receiptResponse.storeName,
                            currency: receiptResponse.currency
                        )



                        completion(receipt)
                    } else {
                        print("No function call arguments found in the response")
                        completion(nil)
                    }
                } catch {
                    print("Parsing error: \(error)")
                    completion(nil)
                }
            }

            task.resume()
        } catch {
            print("JSON encoding error: \(error)")
            completion(nil)
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

