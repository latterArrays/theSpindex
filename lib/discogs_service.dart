import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscogsService {
  final String _firebaseFunctionUrl =
      'https://proxydiscogs-oozhjhvasa-uc.a.run.app';

  Future<List<Map<String, dynamic>>> searchAlbums(
    String searchText
  ) async {
    final queryParameters = {
      'endpoint': 'database/search', // Specify the Discogs API endpoint
      'q': searchText, // Search query
      'type': 'release', // Optional: Specify the type of search
    };

    final uri = Uri.parse(_firebaseFunctionUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
      } else {
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error fetching album results: $e");
    }

    return [];
  }

  Future<String?> getAlbumArt(String title, String artist) async {
    final queryParameters = {
      'endpoint': 'database/search', // Specify the Discogs API endpoint
      'q': '$title $artist', // Search query
      'type': 'release', // Optional: Specify the type of search
    };

    final uri = Uri.parse(_firebaseFunctionUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response: $data");
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['cover_image']; // Return the first result's cover image URL
        }
      } else {
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error fetching album art: $e");
    }

    return null; // Return null if no album art is found
  }

  Future<Map<String, dynamic>?> fetchAlbumDetails(int releaseId) async {
    final queryParameters = {
      'endpoint': 'releases/$releaseId', // Specify the Discogs API endpoint
    };

    final uri = Uri.parse(_firebaseFunctionUrl).replace(queryParameters: queryParameters);

    print("Fetching album details from: $uri");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Album details: $data");
        return Map<String, dynamic>.from(data);
      } else {
        print(
          "Error fetching album details: ${response.statusCode} - ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print("Error fetching album details: $e");
    }

    return null; // Return null if something went wrong
  }

  Future<List<Map<String, dynamic>>> getTrackList(int releaseId) async {
    final queryParameters = {
      'endpoint': 'releases/$releaseId', // Specify the Discogs API endpoint
    };

    final uri = Uri.parse(_firebaseFunctionUrl).replace(queryParameters: queryParameters);
    print("Fetching track list from: $uri");
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Track list: $data");
        if (data['tracklist'] != null && data['tracklist'] is List) {
          return List<Map<String, dynamic>>.from(data['tracklist']);
        }
      } else {
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error fetching track list: $e");
    }

    return [];
  }
}
