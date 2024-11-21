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
        let request = StructuredRequest(
            model: "gpt-4o-mini",
            messages: [
                .init(role: "user", content: """
                Extract all purchased items from the receipt text. 
                Provide the response in the following JSON format. If discount is not provided set it to 0!:
                {
                    "items": [
                        {
                            "name": "Item Name",
                            "category": "Item Category",
                            "quantity": 1,
                            "price": 2.99,
                            "total": 5.98,
                            "discount": 1.00
                        }
                    ]
                }
                
                Receipt Text:
                \(text)
                """)
            ],
            temperature: 0.0,
            max_tokens: 500,
            response_format: .init(type: "json_object")
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
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Request JSON: \(jsonString)")
            }
            
            // Perform network request
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                // Detailed error handling
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("Status Code: \(httpResponse.statusCode)")
                    
                    // Print response headers
                    print("Response Headers: \(httpResponse.allHeaderFields)")
                }
                
                // Ensure we have data
                guard let data = data else {
                    print("No data received")
                    completion([])
                    return
                }
                
                // Print raw response data
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw Response: \(responseString)")
                }
                
                // Parse response
                do {
                    let decoder = JSONDecoder()
                    let apiResponse = try decoder.decode(APIResponse.self, from: data)
                    
                    // Extract and parse content
                    if let content = apiResponse.choices.first?.message.content,
                       let contentData = content.data(using: .utf8) {
                        let itemsResponse = try decoder.decode(ItemsResponse.self, from: contentData)
                        
                        // Convert to domain model
                        let items = itemsResponse.items.map {
                            Item(name: $0.name, category: $0.category, quantity: $0.quantity, price: $0.price, total: $0.total, discount: $0.discount )
                        }
                        
                        completion(items)
                    } else {
                        print("No content found in the response")
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

// Existing struct definitions remain the same as in your previous code
struct StructuredRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
    let response_format: ResponseFormat
}

struct Message: Codable {
    let role: String
    let content: String
}

struct ResponseFormat: Codable {
    let type: String
}

struct APIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: MessageContent
}

struct MessageContent: Codable {
    let content: String?
}

struct ItemsResponse: Codable {
    let items: [ItemDTO]
}
