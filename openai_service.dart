import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  final List<Map<String, String>> messages = [];

  // 🔹 Groq API (text/chat)
  static const groqApiKey = "myapi_key"; // Replace with your Groq API key
  static const groqApiUrl =
      " my groq_api_url"; // Replace with your Groq API URL";

  // 🔹 Stability AI API (image)
  static const stabilityApiKey =
      "my_stability_api_key"; // Replace with your Stability AI API key
  static const stabilityApiUrl =
      "my_stability_api_url"; // Replace with your Stability AI API URL

  /// Decide if the prompt is art/image related
  Future<String?> isArtPromptAPI(String prompt) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $groqApiKey',
    };

    final body = jsonEncode({
      "model": "llama-3.3-70b-versatile",
      "messages": [
        {
          "role": "system",
          "content":
              "Reply only 'yes' if this is art/image related, otherwise 'no'.",
        },
        {"role": "user", "content": prompt},
      ],
      "temperature": 0.2,
    });

    try {
      final response = await http.post(
        Uri.parse(groqApiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['choices']?[0]?['message']?['content']?.toString().trim() ??
            "";

        if (reply.toLowerCase().startsWith("yes")) {
          return await bingAPI(prompt, isImage: true); // image
        } else {
          return await bingAPI(prompt, isImage: false); // text
        }
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Handle Text (Groq) & Image (StabilityAI)
  Future<String> bingAPI(String prompt, {bool isImage = false}) async {
    messages.add({"role": "user", "content": prompt});

    if (isImage) {
      // 🔹 Stability AI Image Generation
      final headers = {
        "Authorization": "Bearer $stabilityApiKey",
        "Accept": "application/json",
      };

      final body = {
        "prompt": prompt,
        "output_format": "url", // ✅ get image URL directly
      };

      try {
        final response = await http.post(
          Uri.parse(stabilityApiUrl),
          headers: headers,
          body: body,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final imageUrl = data["image"] ?? data["artifacts"]?[0]?["url"];

          if (imageUrl != null) {
            print("Stability AI Image URL: $imageUrl");
            return imageUrl; // ✅ return only URL
          } else {
            return "No image returned.";
          }
        } else {
          return "Error from Stability: ${response.statusCode}";
        }
      } catch (e) {
        return "Error: $e";
      }
    }

    // 🔹 Groq Text Chat
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $groqApiKey',
    };

    final body = jsonEncode({
      "model": "llama-3.3-70b-versatile",
      "messages": messages,
      "temperature": 0.7,
    });

    try {
      final response = await http.post(
        Uri.parse(groqApiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['choices']?[0]?['message']?['content']?.toString().trim() ??
            "";
        messages.add({"role": "assistant", "content": reply});
        return reply;
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
