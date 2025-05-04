import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class OpenAIService {
  final String _apiKey;

  OpenAIService()
      : _apiKey = FirebaseRemoteConfig.instance.getString('OPENAI_API_KEY');

  Future<Map<String, dynamic>> getAlbumMetadataFromImage(String base64Image) async {
    final imageDataUrl = "data:image/jpeg;base64,$base64Image";
    print("Going to send image data URL: $imageDataUrl");
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final headers = {
      "Authorization": "Bearer $_apiKey",
      "Content-Type": "application/json",
    };

    final body = jsonEncode({
      "model": "gpt-4.1",
      "response_format": {"type": "json_object"}, // Corrected format
      "messages": [
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": """
              You are a music metadata extraction assistant. Please return only a JSON object with this format:

              {
                "album_name": string,
                "artist": string,
                "release_year": string
              }
              """
            },
            {
              "type": "image_url",
              "image_url": { "url": imageDataUrl }
            }
          ]
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
        print("Response: ${response.body}");
        return {};
      }
    } catch (e) {
      print("Error fetching album metadata: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getAlbumMetadataFromImageV2(String base64Image) async {
    final url = Uri.parse("https://api.openai.com/v1/images/metadata");

    final headers = {
      "Authorization": "Bearer $_apiKey",
      "Content-Type": "application/json",
    };

    final body = jsonEncode({
      "image": "data:image/jpeg;base64,$base64Image",
      "response_format": {"type": "json"}, // Corrected format
      "model": "gpt-4o",
    });

    print("Going to send image data URL: $body");
    print("Headers: $headers");
    print("URL: $url");

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
        return {};
      }
    } catch (e) {
      print("Error fetching album metadata: $e");
      return {};
    }
  }
}
