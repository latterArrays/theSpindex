import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'dart:convert'; // Import for jsonDecode
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'discogs_service.dart';
import 'openai_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs
import 'dart:io' as io; // Alias for dart:io
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import for Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for dart:html (web only)
import 'unsupported_html_stub.dart'
    if (dart.library.html) 'dart:html'
    as html; // Alias for dart:html

class SetFavoriteAlbumButton extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> album;

  SetFavoriteAlbumButton({required this.userId, required this.album});

  @override
  _SetFavoriteAlbumButtonState createState() => _SetFavoriteAlbumButtonState();
}

class _SetFavoriteAlbumButtonState extends State<SetFavoriteAlbumButton> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    final favoriteAlbum = userDoc.data()?['favoriteAlbum'];
    if (favoriteAlbum == widget.album['title']) {
      setState(() {
        _isFavorite = true;
      });
    }
  }

  Future<void> _setFavoriteAlbum() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'favoriteAlbum': widget.album['title'],
            'favoriteAlbumCoverUrl': widget.album['coverUrl'],
          });
      setState(() {
        _isFavorite = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favorite album set to ${widget.album['title']}!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set favorite album: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.favorite, color: _isFavorite ? Colors.red : Colors.grey),
      label: Text('Set Favorite'),
      onPressed: () async {
        await _setFavoriteAlbum();
        if (mounted) {
          setState(() {
            _isFavorite = true; // Update the heart color to red
          });
        }
        Navigator.pop(context); // Dismiss the modal after setting favorite
      },
    );
  }
}

class GalleryPage extends StatefulWidget {
  final String userId;

  GalleryPage({required this.userId});

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final PageStorageBucket _bucket = PageStorageBucket();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _firebaseFunctionUrl =
      'https://proxydiscogs-oozhjhvasa-uc.a.run.app?endpoint=';

  final String _firebaseStorageUrl =
      "https://us-central1-thespindex-d6b69.cloudfunctions.net/proxyFirebaseStorage";
  String? _selectedListId;
  List<Map<String, dynamic>> _albums = [];

  List<Map<String, String>> _listNames = [];
  bool _loading = true;
  bool _isProcessing = false; // Add a state variable to track processing status

  final List<Color> _colors = List.generate(20, (index) => _randomColor());

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  static Color _randomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  String getProxiedUrl(String firebaseStorageUrl) {
    return '$_firebaseStorageUrl?url=$firebaseStorageUrl';
  }

  void _showAddAlbumModal() {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          title: Text("Add New Album"),
          content: Container(
            width: screenWidth * 0.9, // Set the width to 80% of the screen
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: "Smart Search (Artist, Album, Year, etc.)",
                  ),
                  onSubmitted: (value) async {
                    // Trigger the search action when "Enter" is pressed
                    await _handleManualSearch(searchController.text);
                  },
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: Size(180, 40)),
                    onPressed: () async {
                      await _handleManualSearch(searchController.text);
                    },
                    icon: Icon(Icons.search),
                    label: Text("Search"),
                  ),
                  SizedBox(height: 8), // Add spacing between buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: Size(180, 40)),
                    onPressed: _handleImageSearch,
                    icon: Icon(Icons.camera_alt),
                    label: Text("Image Search"),
                  ),
                  SizedBox(height: 8), // Add spacing between buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: Size(180, 40)),
                    onPressed: () {
                      Navigator.pop(context); // Close the current modal
                      _showManualAddAlbumModal(); // Open the manual modal
                    },
                    icon: Icon(Icons.upload_file),
                    label: Text("Manual Upload"),
                  ),
                  SizedBox(height: 8), // Add spacing between buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: Size(180, 40)),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.cancel),
                    label: Text("Cancel"),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleManualSearch(String query) async {
    // Close the search modal
    Navigator.pop(context);

    // Show the spinner
    setState(() {
      _isProcessing = true;
    });

    try {
      // Perform the search using the Discogs service
      final discogsService = DiscogsService();
      final results = await discogsService.searchAlbums(query);

      // Show results or an error message
      if (results.isNotEmpty) {
        if (mounted) {
          _showDiscogsResultsModal(results);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No results found on Discogs. Try refining your search!",
              ),
            ),
          );
        }
      }
    } finally {
      // Hide the spinner
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleImageSearch() async {
    final ImagePicker picker = ImagePicker();

    // Close the "Add New Album" modal first
    Navigator.pop(context);

    // Show a dialog to let the user choose between camera and gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Select Image Source"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text("Take a Picture"),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text("Choose from Gallery"),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) {
      // User canceled the dialog
      return;
    }

    // Set the state to show the spinner immediately
    setState(() {
      _isProcessing = true;
    });

    // Allow the user to capture or pick an image
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) {
      // User canceled the image picker
      if (mounted) {
        setState(() {
          _isProcessing = false; // Hide the spinner if no image is selected
        });
      }
      return;
    }

    try {
      Uint8List? imageBytes;

      if (kIsWeb) {
        // For web, read the image as bytes directly
        imageBytes = await image.readAsBytes();
      } else if (io.Platform.isAndroid || io.Platform.isIOS) {
        // For mobile platforms, compress the image
        imageBytes = await FlutterImageCompress.compressWithFile(
          image.path,
          format: CompressFormat.jpeg, // Convert to JPEG
          quality: 90, // Adjust quality as needed
        );
      }

      if (imageBytes == null || imageBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to process the image.")),
          );
        }
        return;
      }

      // Encode the image to a base64 string
      final base64Image = base64Encode(imageBytes);

      // Send the base64-encoded image to OpenAI for metadata extraction
      final openAIService = OpenAIService();
      final response = await openAIService.getAlbumMetadataFromImage(
        base64Image,
      );

      // Extract metadata from the response
      final metadata = response['choices']?[0]?['message']?['content'];
      if (metadata == null || metadata.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Could not extract metadata from the image. Try a manual search!",
              ),
            ),
          );
        }
        return;
      }

      // Parse metadata as JSON
      final parsedMetadata = jsonDecode(metadata) as Map<String, dynamic>;
      final albumTitle = parsedMetadata['album_name'] ?? '';
      final artist = parsedMetadata['artist'] ?? '';
      final year = parsedMetadata['release_year'] ?? '';

      // Perform the initial search using all metadata
      final discogsService = DiscogsService();
      List<Map<String, dynamic>> results = await discogsService.searchAlbums(
        "$albumTitle $artist $year",
      );

      // Retry with artist + title if few results
      if (results.length < 6 && artist.isNotEmpty) {
        debugPrint("Retrying with artist and title...");
        results = await discogsService.searchAlbums("$albumTitle $artist");
      }

      // Retry with just the title if still few results
      if (results.length < 4) {
        debugPrint("Retrying with just the title...");
        results = await discogsService.searchAlbums(albumTitle);
      }

      // Show results or an error message
      if (results.isNotEmpty) {
        if (mounted) {
          _showDiscogsResultsModal(results);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No results found on Discogs using your image. Try a manual search!",
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false; // Hide the loading spinner
        });
      }
    }
  }

  void _showDiscogsResultsModal(List<Map<String, dynamic>> results) {
    if (!mounted) return; // Ensure the widget is still active
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Select an Album"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  height: 400, // Fixed height for the grid
                  child: GridView(
                    shrinkWrap: true, // Keep this
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    children:
                        results.map((album) {
                          return GestureDetector(
                            onTap: () async {
                              // Fetch detailed information from Discogs by ID
                              final discogsId =
                                  album['id']; // Get the Discogs ID
                              final discogsService = DiscogsService();
                              final albumDetails = await discogsService
                                  .fetchAlbumDetails(discogsId);

                              final albumUri =
                                  albumDetails?['uri'] ?? 'NOT FOUND';
                              final artistName =
                                  albumDetails?['artists']?[0]?['name'] ??
                                  'Unknown Artist';

                              // Save the metadata
                              final selectedAlbum = {
                                'id': album['id'],
                                'title': album['title'],
                                'artist': artistName,
                                'year': album['year'],
                                'genre': album['genre'],
                                'coverUrl':
                                    album['cover_image'], // Use the URL directly
                                'url': albumUri,
                              };
                              debugPrint(
                                "Album Search Result Image URL: $album['cover_image']",
                              );
                              debugPrint("Selected Album: $selectedAlbum");

                              if (_selectedListId != null) {
                                await _firestoreService.upsertAlbum(
                                  widget.userId,
                                  _selectedListId!,
                                  selectedAlbum,
                                );
                                _loadAlbums();
                              }

                              Navigator.pop(context);
                            },
                            child: Card(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      album['cover_image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showManualAddAlbumModal();
                  },
                  child: Text("Add Manually"),
                ),
              ],
            ),
          ),
    );
  }

  void _showManualAddAlbumModal() {
    final ImagePicker _picker = ImagePicker();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController artistController = TextEditingController();
    final TextEditingController yearController = TextEditingController();
    final TextEditingController genreController = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text("Add Album Manually"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(labelText: "Album Title"),
                      ),
                      TextField(
                        controller: artistController,
                        decoration: InputDecoration(labelText: "Artist"),
                      ),
                      TextField(
                        controller: yearController,
                        decoration: InputDecoration(labelText: "Year"),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: genreController,
                        decoration: InputDecoration(labelText: "Genre"),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          // Dismiss the keyboard before opening the image picker
                          FocusScope.of(context).unfocus();

                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            if (kIsWeb) {
                              // For web, upload the image to Firebase Storage and use the URL
                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child(
                                    'album_covers/${DateTime.now().millisecondsSinceEpoch}',
                                  );
                              final imageBytes = await image.readAsBytes();
                              await storageRef.putData(
                                imageBytes,
                                SettableMetadata(contentType: 'image/jpeg'),
                              );
                              final coverUrl =
                                  await storageRef.getDownloadURL();
                              setState(() {
                                imagePath =
                                    coverUrl; // Use the proxied URL for web
                              });
                            } else {
                              setState(() {
                                imagePath =
                                    image.path; // Use the local path for mobile
                              });
                            }
                          }
                        },
                        child: Text(
                          imagePath == null ? "Select Image" : "Reselect Image",
                        ),
                      ),
                      if (imagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                kIsWeb
                                    ? Image.network(
                                      imagePath!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                    : Image.file(
                                      io.File(imagePath!),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  Center(
                    child: Column (
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: Size(180, 40)),
                        onPressed: () async {
                          if (titleController.text.isNotEmpty &&
                              artistController.text.isNotEmpty &&
                              yearController.text.isNotEmpty &&
                              genreController.text.isNotEmpty &&
                              imagePath != null) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              // Upload the image to Firebase Storage
                              final storageRef = FirebaseStorage.instance.ref().child(
                                'album_covers/${DateTime.now().millisecondsSinceEpoch}',
                              );
                              final coverUrl =
                                  kIsWeb
                                      ? imagePath!
                                      : await storageRef
                                          .putFile(io.File(imagePath!))
                                          .then(
                                            (task) => task.ref.getDownloadURL(),
                                          );

                              // Create the album object
                              final album = {
                                'id':
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                'title': titleController.text,
                                'artist': artistController.text,
                                'year': yearController.text,
                                'genre': genreController.text,
                                'coverUrl': coverUrl, // Use the uploaded image URL
                              };

                              if (_selectedListId != null) {
                                await _firestoreService.upsertAlbum(
                                  widget.userId,
                                  _selectedListId!,
                                  album,
                                );
                                Navigator.pop(context); // Close the modal first
                                setState(() {
                                  _isProcessing =
                                      true; // Show spinner while reloading
                                });
                                await _loadAlbums(); // Refresh the albums grid
                                setState(() {
                                  _isProcessing =
                                      false; // Hide spinner after reload
                                });
                              }
                            }
                          } else {
                            // Show an error message if any field is missing
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Please fill all fields and select an image.",
                                ),
                              ),
                            );
                          }
                        },
                        child: Text("Add Album"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: Size(180, 40)),
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                    ]
                  )
                  )
                ],
              );
            },
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 8), // Adjust duration for spinning speed
    )..repeat(); // Repeat the animation indefinitely

    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() {
      _loading = true;
    });
    try {
      final lists = await _firestoreService.getUserListsWithNames(
        widget.userId,
      );
      debugPrint("Lists loaded: $lists");

      if (lists.isEmpty ||
          !lists.any((list) => list['name'] == "My Collection")) {
        // Create a default list if none exists or if "My Collection" is missing
        final defaultListId = DateTime.now().millisecondsSinceEpoch.toString();
        await _firestoreService.setList(
          widget.userId,
          defaultListId,
          name: "My Collection",
        );
        return _loadLists(); // Reload lists after creating the default list
      }

      setState(() {
        _listNames = lists;
        _listNames.sort((a, b) => a['name']!.compareTo(b['name']!));
        _selectedListId ??= lists.isNotEmpty ? lists.first['id'] : null;
        _loading = false;
      });

      if (_selectedListId != null) {
        await _loadAlbums();
      }
    } catch (e) {
      debugPrint("Error loading lists: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadAlbums() async {
    if (_selectedListId == null) return;

    try {
      final albums = await _firestoreService.getAlbumsFromList(
        widget.userId,
        _selectedListId!,
      );
      debugPrint("Albums loaded: $albums");

      setState(() {
        _albums = albums;
      });
    } catch (e) {
      debugPrint("Error loading albums: $e");
    }
  }

  Future<void> _addNewList() async {
    final listName = await _showAddListDialog();
    if (listName != null && listName.isNotEmpty) {
      // Generate a new list ID
      final newListId = DateTime.now().millisecondsSinceEpoch.toString();

      // Add the new list to Firestore
      await _firestoreService.setList(widget.userId, newListId, name: listName);

      // Set the newly created list as the selected list
      setState(() {
        _selectedListId = newListId;
      });

      // Reload the lists
      await _loadLists();
    }
  }

  Future<String?> _showAddListDialog() async {
    String? listName;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Add New List"),
            content: TextField(
              onChanged: (value) => listName = value,
              decoration: InputDecoration(hintText: "List Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, listName),
                child: Text("Add"),
              ),
            ],
          ),
    );
    return listName;
  }

  Future<String?> fetchAppleMusicLink(String albumName) async {
    final url = Uri.parse(
      'https://itunes.apple.com/search?term=$albumName&entity=album',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'].isNotEmpty) {
        return data['results'][0]['collectionViewUrl']; // Link to the album
      }
    }
    return null; // No link found
  }

  Future<void> _showAlbumDetails(Map<String, dynamic> album) async {
    final url = album['url']; // Replace with the actual URL
    final releaseId = int.tryParse(
      album['id'].toString(),
    ); // Safely convert to int

    if (releaseId == null) {
      debugPrint("Error: releaseId is null or invalid");
      return; // Exit the method if releaseId is invalid
    }

    final discogsService = DiscogsService();

    // Fetch the tracklist
    final tracklist = await discogsService.getTrackList(releaseId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the modal to take up more space
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16.0),
            height:
                MediaQuery.of(context).size.height * 0.9, // 90% of the height
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large thumbnail at the top
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      album['coverUrl'],
                      height:
                          MediaQuery.of(context).size.height *
                          0.35, // 35% height
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Album metadata
                Text(
                  album['title'],
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Artist: ${album['artist']}",
                  style: TextStyle(fontSize: 16),
                ),
                Text("Year: ${album['year']}", style: TextStyle(fontSize: 16)),
                Text(
                  "Genre: ${album['genre']}",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                // Tracklist (if available)
                if (tracklist.isNotEmpty)
                  Expanded(
                    child: ListView.separated(
                      itemCount: tracklist.length,
                      itemBuilder: (context, index) {
                        final track = tracklist[index];
                        return ListTile(
                          dense: true, // Make the list items more compact
                          leading: Text(
                            track['position'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                            ), // Slightly smaller font
                          ),
                          title: Text(
                            track['title'] ?? 'Unknown Track',
                            style: TextStyle(
                              fontSize: 16,
                            ), // Smaller font for title
                          ),
                        );
                      },
                      separatorBuilder:
                          (context, index) => Divider(
                            thickness: 1, // Add a horizontal line between items
                            color: Colors.grey,
                          ),
                    ),
                  ),
                if (tracklist.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        "No tracklist available.",
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                // Buttons arranged in a grid (2 x 2)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(150, 40),
                          ),
                          icon: Icon(Icons.favorite),
                          label: Text("Set Favorite"),
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.userId)
                                  .update({
                                    'favoriteAlbum': album['title'],
                                    'favoriteAlbumCoverUrl': album['coverUrl'],
                                  });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Favorite album set to ${album['title']}!',
                                  ),
                                ),
                              );
                              _loadLists(); // Reload lists to reflect the updated state
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to set favorite album: $e',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(150, 40),
                          ),
                          icon: Icon(Icons.music_note),
                          label: Text("Discogs"),
                          onPressed: () {
                            if (kIsWeb) {
                              // Use html.window.open for web to open the URL in a new tab
                              html.window.open(url, '_blank');
                            } else {
                              // Use url_launcher for mobile/desktop
                              openUrl(url);
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8), // Add spacing between rows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(150, 40),
                          ),
                          icon: Icon(Icons.edit),
                          label: Text("Edit"),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditAlbumDialog(album);
                          },
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.delete),
                          label: Text("Delete"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: Size(150, 40),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDeleteAlbum(album);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void openUrl(String url) async {
    debugPrint("Opening URL: $url");
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showAlbumOptions(Map<String, dynamic> album) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Album'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditAlbumDialog(album);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete Album'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteAlbum(album);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // TODO - some kind of error on this right now...
  void _showEditAlbumDialog(Map<String, dynamic> album) {
    // Safely extract fields and handle cases where they might be lists
    final title = album['title']?.toString() ?? '';
    final artist =
        album['artist'] is List
            ? (album['artist'] as List).join(
              ', ',
            ) // Join list into a single string
            : album['artist']?.toString() ??
                ''; // Convert to string if not a list
    final year = album['year']?.toString() ?? '';
    final genre =
        album['genre'] is List
            ? (album['genre'] as List).join(
              ', ',
            ) // Join list into a single string
            : album['genre']?.toString() ??
                ''; // Convert to string if not a list

    final titleController = TextEditingController(text: title);
    final artistController = TextEditingController(text: artist);
    final yearController = TextEditingController(text: year);
    final genreController = TextEditingController(text: genre);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Album'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Album Title'),
                ),
                TextField(
                  controller: artistController,
                  decoration: InputDecoration(labelText: 'Artist'),
                ),
                TextField(
                  controller: yearController,
                  decoration: InputDecoration(labelText: 'Year'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: genreController,
                  decoration: InputDecoration(labelText: 'Genre'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final updatedAlbum = {
                    ...album,
                    'title': titleController.text,
                    'artist': artistController.text,
                    'year': yearController.text,
                    'genre': genreController.text,
                  };

                  if (_selectedListId != null) {
                    await _firestoreService.upsertAlbum(
                      widget.userId,
                      _selectedListId!,
                      updatedAlbum,
                    );
                    _loadAlbums();
                  }

                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  // Add debug prints to confirm delete modal and button press
  void _confirmDeleteAlbum(Map<String, dynamic> album) {
    print('Opening delete confirmation for album: ${album['title']}');
    showDialog(
      context: context,
      builder: (context) {
        print('Building delete confirmation dialog');
        return AlertDialog(
          title: Text('Delete Album'),
          content: Text('Are you sure you want to delete "${album['title']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                print('Cancel button pressed');
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                print('Delete button pressed for album: ${album['title']}');
                if (_selectedListId != null) {
                  // Ensure album ID is treated as a string
                  final albumId = album['id'].toString();
                  print(
                    'Deleting album with ID: $albumId from list: $_selectedListId',
                  );
                  await _firestoreService.deleteAlbum(
                    widget.userId,
                    _selectedListId!,
                    albumId,
                  );
                  print('Album deleted successfully');
                  _loadAlbums();
                }
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteListConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Delete List"),
            content: Text("Are you sure you want to delete this list?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close the dialog
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close the confirmation dialog
                  Navigator.pop(context); // Close the list settings dialog
                  if (_selectedListId != null) {
                    _deleteList(_selectedListId!);
                  }
                },
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteList(String listId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete the list from Firestore
    await _firestoreService.deleteList(user.uid, listId);

    // Reload the lists and reset the selected list
    await _loadLists();

    // If the user deleted their last list, create the default one again.
    if (_listNames.isEmpty) {
      final defaultListId = DateTime.now().millisecondsSinceEpoch.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "All lists have been deleted! A default list has been recreated.",
          ),
        ),
      );
      await _firestoreService.setList(
        user.uid,
        defaultListId,
        name: "My Collection",
      );
      await _loadLists();
    }

    setState(() {
      _selectedListId = _listNames.isNotEmpty ? _listNames.first['id'] : null;
    });

    // Load albums for the new selected list
    if (_selectedListId != null) {
      await _loadAlbums();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadLists,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text("Gallery"),
              ),
              actions: [
                DropdownButton<String>(
                  value:
                      _listNames.any((list) => list['id'] == _selectedListId)
                          ? _selectedListId
                          : null, // Ensure the value is valid
                  items: [
                    ..._listNames.map((list) {
                      return DropdownMenuItem(
                        value: list['id'],
                        child: SizedBox(
                          width:
                              200, // Set a fixed width for the dropdown items
                          child: Text(
                            list['name']!,
                            overflow:
                                TextOverflow
                                    .ellipsis, // Truncate text with ellipsis
                            maxLines: 1, // Ensure it stays on one line
                          ),
                        ),
                      );
                    }),
                    DropdownMenuItem(
                      value: 'add_list',
                      child: Text(" + New List"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == 'add_list') {
                      // Call the _addNewList function when "Add list" is selected
                      _addNewList();
                    } else {
                      // Handle regular list selection
                      setState(() {
                        _selectedListId = value;
                        _loadAlbums();
                      });
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    final TextEditingController listNameController =
                        TextEditingController(
                          text:
                              _listNames.firstWhere(
                                (list) => list['id'] == _selectedListId,
                              )['name'],
                        );
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text("Edit List"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: listNameController,
                                  decoration: InputDecoration(
                                    labelText: "Edit List Name",
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.delete),
                                    label: Text("Delete List"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    onPressed: _showDeleteListConfirmation,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).primaryColor, // Solid color background
                                    ),
                                    onPressed: () async {
                                      final newName =
                                          listNameController.text.trim();
                                      if (newName.isNotEmpty &&
                                          _selectedListId != null) {
                                        await _firestoreService.setList(
                                          widget.userId,
                                          _selectedListId!,
                                          name: newName,
                                        );
                                        await _loadLists(); // Reload lists to reflect the updated name
                                      }
                                      Navigator.pop(
                                        context,
                                      ); // Close the settings dialog
                                    },
                                    child: Text("Done"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
            body:
                _loading
                    ? Center(child: CircularProgressIndicator())
                    : _listNames.isEmpty
                    ? Center(
                      child: Text(
                        "No lists available. Please create a new list.",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : Column(
                      children: [
                        Expanded(
                          child: PageStorage(
                            bucket: _bucket,
                            child: GridView.builder(
                              key: PageStorageKey<String>('galleryGrid'),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: _albums.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _albums.length) {
                                  return GestureDetector(
                                    onTap: _showAddAlbumModal,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final cellSize =
                                            constraints
                                                .maxWidth; // Use the cell's width as the base size
                                        final spinnerSize =
                                            cellSize *
                                            0.8; // Spinner size is 80% of the cell size
                                        final plusFontSize =
                                            cellSize *
                                            0.3; // "+" font size is 30% of the cell size

                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AnimatedBuilder(
                                              animation: _controller,
                                              builder: (context, child) {
                                                final angle =
                                                    _controller.value *
                                                    2 *
                                                    pi; // Rotate 360 degrees
                                                return Transform.rotate(
                                                  angle: angle,
                                                  child: Transform.scale(
                                                    scale:
                                                        1, // Keep the spinner scale at 1
                                                    child: Center(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              spinnerSize / 2,
                                                            ), // Fully rounded corners
                                                        child: Stack(
                                                          alignment:
                                                              Alignment
                                                                  .center, // Center the gradient and image
                                                          children: [
                                                            Image.asset(
                                                              'assets/album.png', // Path to your vinyl record image
                                                              width:
                                                                  spinnerSize,
                                                              height:
                                                                  spinnerSize,
                                                              fit: BoxFit.cover,
                                                            ),
                                                            Container(
                                                              width:
                                                                  spinnerSize,
                                                              height:
                                                                  spinnerSize,
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    const Color.fromARGB(
                                                                      150,
                                                                      2,
                                                                      208,
                                                                      184,
                                                                    ), // Semi-transparent teal
                                                                    const Color.fromARGB(
                                                                      150,
                                                                      250,
                                                                      125,
                                                                      0,
                                                                    ), // Semi-transparent orange
                                                                  ],
                                                                  begin:
                                                                      Alignment
                                                                          .topLeft,
                                                                  end:
                                                                      Alignment
                                                                          .bottomRight,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            // The "+" sign remains stationary
                                            Text(
                                              "+",
                                              style: TextStyle(
                                                fontSize:
                                                    plusFontSize, // Dynamically adjust font size
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                }
                                final album = _albums[index];
                                return GestureDetector(
                                  onTap: () => _showAlbumDetails(album),
                                  onLongPress: () => _showAlbumOptions(album),
                                  child: Card(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child:
                                              album['coverUrl'] != null &&
                                                      album['coverUrl']
                                                          .startsWith('http')
                                                  ? Image.network(
                                                    album['coverUrl'], // Use NetworkImage for URLs
                                                    fit: BoxFit.cover,
                                                  )
                                                  : Image.file(
                                                    io.File(
                                                      album['coverUrl'],
                                                    ), // Use FileImage for local paths
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(
                  0.5,
                ), // Semi-transparent overlay
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * pi, // Rotate 360 degrees
                        child: child,
                      );
                    },
                    child: Transform.scale(
                      scale: 1.1, // Scale the image by 10% to "zoom in"
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          180,
                        ), // Fully rounded corners
                        child: Image.asset(
                          'assets/album.png', // Path to your vinyl record image
                          width: 200, // Adjust size as needed
                          height: 200,
                          fit:
                              BoxFit
                                  .cover, // Ensure the image fits within the container
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
