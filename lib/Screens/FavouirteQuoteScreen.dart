import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavouriteQuoteScreen extends StatefulWidget {
  const FavouriteQuoteScreen({super.key});

  @override
  State<FavouriteQuoteScreen> createState() => _FavouriteQuoteScreenState();
}

class _FavouriteQuoteScreenState extends State<FavouriteQuoteScreen> {
  List<Map<String, dynamic>> fetchedFavoriteQuotes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavoriteQuotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favourite Quotes'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(), // Show a loading indicator
            )
          : fetchedFavoriteQuotes.isEmpty
              ? Center(
                  child: Text(
                    'No favourite Quote here',
                    style: TextStyle(fontSize: 25),
                  ),
                )
              : ListView.builder(
                  itemCount: fetchedFavoriteQuotes.length,
                  itemBuilder: (context, index) {
                    final quote = fetchedFavoriteQuotes[index];
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color.fromARGB(255, 14, 172, 162),
                            child: Text("${index + 1}"),
                          ),
                          title: Text(
                            quote['text'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('- ${quote['author']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              removeQuoteFromFavorites(
                                  quote); // Unfavorite the quote
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> fetchFavoriteQuotes() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('favorite_quotes').get();

    setState(() {
      fetchedFavoriteQuotes = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      isLoading = false;
    });
  }

  Future<void> removeQuoteFromFavorites(Map<String, dynamic> quote) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('favorite_quotes')
        .where('text', isEqualTo: quote['text'])
        .where('author', isEqualTo: quote['author'])
        .get();

    if (snapshot.docs.isNotEmpty) {
      snapshot.docs.first.reference.delete();
      setState(() {
        fetchedFavoriteQuotes.remove(quote);
      });
      Navigator.pop(context, quote);
      // Refresh the list after unfavorite
    }
  }
}
