import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';

class ListsPage extends StatefulWidget {
  @override
  _ListsPageState createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  final FirestoreService _firebaseService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _addNewList() async {
    final user = _auth.currentUser;
    if (user == null) return;

    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New List'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter list name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newListId = DateTime.now().millisecondsSinceEpoch.toString();
                await _firebaseService.setList(user.uid, newListId, name: controller.text);
                Navigator.pop(context);
                setState(() {}); // Refresh the UI
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteList(String listId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firebaseService.deleteList(user.uid, listId);
    setState(() {}); // Refresh the UI
  }

  void _openList(String listId) {
    Navigator.pop(context, listId); // Pass the selected list ID back to the gallery page
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Center(child: Text('Please log in to view your lists.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Lists'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewList,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _firebaseService.getUserListsWithNames(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No lists available. Add a new list!'));
          }

          final lists = snapshot.data!;

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              final listId = list['id']!;
              final listName = list['name']!;

              return ListTile(
                leading: IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    TextEditingController controller = TextEditingController();
                    controller.text = listName;

                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Edit List Name'),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(hintText: 'Enter new list name'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (controller.text.isNotEmpty) {
                                await _firebaseService.setList(user.uid, listId, name: controller.text);
                                Navigator.pop(context);
                                setState(() {}); // Refresh the UI
                              }
                            },
                            child: Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                title: Text(listName),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteList(listId),
                ),
                onTap: () => _openList(listId),
              );
            },
          );
        },
      ),
    );
  }
}
