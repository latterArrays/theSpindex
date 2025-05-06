import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<DocumentSnapshot> _userDataFuture;
  late Future<List<Map<String, dynamic>>> _albumListsFuture;
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots(); // Listen for real-time updates
    _userDataFuture = _fetchUserData();
    _albumListsFuture = _fetchAlbumLists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger the pull-to-refresh functionality when the tab renders the first time
    _refreshUserData();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger the pull-to-refresh functionality when the widget is updated
    _refreshUserData();
  }

  Future<DocumentSnapshot> _fetchUserData() {
    return FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  Future<List<Map<String, dynamic>>> _fetchAlbumLists() async {
    final listsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('lists')
        .get();

    return listsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? 'Unnamed List',
        'count': (data['albums'] as List<dynamic>?)?.length ?? 0,
      };
    }).toList();
  }

  Future<void> _refreshUserData() async {
    setState(() {
      _userDataFuture = _fetchUserData();
      _albumListsFuture = _fetchAlbumLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading user data: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User data not found. Please ensure your profile is set up.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final profilePictureUrl = userData['profilePicture'] ?? '';
          final favoriteAlbum = userData['favoriteAlbum'] ?? 'Not set';
          final memberSince = userData['createdAt'] != null
              ? (userData['createdAt'] as Timestamp).toDate()
              : DateTime.now();

          final GlobalKey shareKey = GlobalKey();

          return RefreshIndicator(
            onRefresh: _refreshUserData,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RepaintBoundary(
                      key: shareKey,
                      child: Column(
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: profilePictureUrl.isNotEmpty
                                  ? NetworkImage(profilePictureUrl)
                                  : AssetImage('assets/defaultProfile.png') as ImageProvider,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('${userData['email'] ?? 'Not available'}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 16),
                          Text('Favorite Album:\n$favoriteAlbum',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (favoriteAlbum != 'Not set') ...[
                            SizedBox(height: 8),
                            Image.network(
                              userData['favoriteAlbumCoverUrl'] ?? '',
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 100),
                            ),
                            SizedBox(height: 16),
                          ],
                          Text('Member Since: ${memberSince.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 16),
                          Text('Album Lists:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _albumListsFuture,
                            builder: (context, albumListsSnapshot) {
                              if (albumListsSnapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }

                              if (albumListsSnapshot.hasError) {
                                return Center(child: Text('Error loading album lists: ${albumListsSnapshot.error}'));
                              }

                              final albumLists = albumListsSnapshot.data ?? [];

                              return DataTable(
                                columns: [
                                  DataColumn(label: Text('List Name')),
                                  DataColumn(label: Text('Albums')),
                                ],
                                rows: albumLists
                                    .map<DataRow>(
                                      (list) => DataRow(
                                        cells: [
                                          DataCell(Text(list['name'])),
                                          DataCell(Text(list['count'].toString())),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Center(
                      child: kIsWeb
                          ? SizedBox.shrink() // Hide the button on web
                          : ElevatedButton(
                              onPressed: () async {
                                try {
                                  RenderRepaintBoundary boundary =
                                      shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                                  ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                                  final imageWidth = image.width;
                                  final imageHeight = image.height;

                                  // Embed the GitHub URL in the shared image
                                  final painter = ui.PictureRecorder();
                                  final canvas = Canvas(painter);
                                  final paint = Paint();

                                  // Draw the profile card content
                                  canvas.drawImage(image, Offset.zero, paint);

                                  // Add the GitHub URL at the bottom of the image
                                  final textPainter = TextPainter(
                                    text: TextSpan(
                                      text: 'Learn more at https://github.com/latterArrays/theSpindex',
                                      style: TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold),
                                    ),
                                    textDirection: TextDirection.ltr,
                                  );
                                  textPainter.layout();
                                  textPainter.paint(canvas, Offset(100, imageHeight - 40)); // Adjust position and size for better visibility

                                  final finalImage = await painter.endRecording().toImage(imageWidth, imageHeight);
                                  final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
                                  final pngBytes = byteData!.buffer.asUint8List();

                                  final directory = await getTemporaryDirectory();
                                  final file = File('${directory.path}/profile_card.png');
                                  await file.writeAsBytes(pngBytes);

                                  final params = ShareParams(
                                    text: 'Check out my Spindex profile! Learn more at https://github.com/latterArrays/theSpindex',
                                    files: [XFile(file.path)],
                                  );

                                  final result = await SharePlus.instance.share(params);

                                  if (result.status == ShareResultStatus.success) {
                                    print('Profile shared successfully!');
                                  }
                                } catch (e) {
                                  print('Error sharing profile: $e');
                                }
                              },
                              child: Text('Share Profile'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}