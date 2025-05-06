import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all lists with their IDs and names
  Future<List<Map<String, String>>> getUserListsWithNames(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).collection('lists').get();
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': (doc.data()['name'] ?? doc.id).toString(),
      };
    }).toList();
  }

  // Create or update a list
  Future<void> setList(String userId, String listId, {String? name, List<Map<String, dynamic>>? albums}) async {
    final listRef = _firestore.collection('users').doc(userId).collection('lists').doc(listId);
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (albums != null) data['albums'] = albums;
    await listRef.set(data, SetOptions(merge: true));
  }

  // Fetch all albums from a list
  Future<List<Map<String, dynamic>>> getAlbumsFromList(String userId, String listId) async {
    final snapshot = await _firestore.collection('users').doc(userId).collection('lists').doc(listId).get();
    return List<Map<String, dynamic>>.from(snapshot.data()?['albums'] ?? []);
  }

  // Add or update an album in a list
  Future<void> upsertAlbum(String userId, String listId, Map<String, dynamic> album) async {
    final listRef = _firestore.collection('users').doc(userId).collection('lists').doc(listId);
    final snapshot = await listRef.get();
    final albums = List<Map<String, dynamic>>.from(snapshot.data()?['albums'] ?? []);
    final updatedAlbums = albums.where((existingAlbum) => existingAlbum['id'] != album['id']).toList();
    updatedAlbums.add(album);
    await listRef.update({'albums': updatedAlbums});
  }

  // Delete a list
  Future<void> deleteList(String userId, String listId) async {
    await _firestore.collection('users').doc(userId).collection('lists').doc(listId).delete();
  }

  // Delete an album from a list
  Future<void> deleteAlbum(String userId, String listId, String albumId) async {
    print('Deleting album with ID: $albumId from list with ID: $listId');
    debugPrint('Deleting album with ID: $albumId from list with ID: $listId');
    final listRef = _firestore.collection('users').doc(userId).collection('lists').doc(listId);
    final snapshot = await listRef.get();
    final albums = List<Map<String, dynamic>>.from(snapshot.data()?['albums'] ?? []);
    final updatedAlbums = albums.where((album) => album['id'].toString() != albumId).toList();
    await listRef.update({'albums': updatedAlbums});
  }
}

// Utility function to fetch Discogs image URLs
Future<String> fetchDiscogsImageUrl(String endpoint) async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  final discogsKey = remoteConfig.getString('DISCOGS_KEY');
  final discogsSecret = remoteConfig.getString('DISCOGS_SECRET');

  final url = Uri.parse('https://api.discogs.com/$endpoint');
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Discogs key=$discogsKey, secret=$discogsSecret',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['images'][0]['uri']; // Adjust based on Discogs API response structure
  } else {
    throw Exception('Failed to fetch image URL: ${response.statusCode}');
  }
}