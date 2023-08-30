import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:modern_form_esys_flutter_share/modern_form_esys_flutter_share.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quote_app/Screens/FavouirteQuoteScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> quotes = [];
  List<Map<String, dynamic>> favoriteQuotes = [];
  String formattedDate = '';
  String formattedDay = '';
  bool isFavorite = false;
  double favouriteButtonSize = 30;
  String _favoriteMessage = '';
  final CollectionReference favoriteQuotesCollection =
      FirebaseFirestore.instance.collection('favorite_quotes');

  void initState() {
    DateTime currentDate = DateTime.now();
    formattedDate = DateFormat('MMMM dd, yyyy').format(currentDate);
    formattedDay = DateFormat('EEEE').format(currentDate);
    fetchData();
    fetchFavoriteQuotes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
        centerTitle: true,
        title: Text("Quote Of The Day"),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  height: 90,
                ),
                Text(
                  "${formattedDay}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 90,
          ),
          quotes.isEmpty
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: quotes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final quote = entry.value;

                    return Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(children: [
                        Text(
                          '"${quote['text']}"\n\n',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "-${quote['author']}",
                          style: TextStyle(
                              fontSize: 18, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.share),
                              onPressed: () {
                                shareQuote(
                                    quotes[0]['text'], quotes[0]['author']);
                              },
                            ),
                            SizedBox(
                              width: 40,
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              width: favouriteButtonSize,
                              height: favouriteButtonSize,
                              child: IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                ),
                                onPressed: () {
                                  toggleFavorite(index);
                                  setState(() {
                                    favoriteQuotes.contains(quote);
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      ]),
                    );
                  }).toList(),
                ),
          SizedBox(
            height: 40,
          ),
          FloatingActionButton.extended(
            onPressed: () async {
              final deleted = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (contex) => FavouriteQuoteScreen(
                            onDelete: UpdateFavourite,
                          )));
              if (deleted != null) {
                UpdateFavourite(deleted);
              }
            },
            label: Text("Click here to see favourite Quotes"),
          ),
        ],
      ),
    );
  }

  Future<void> fetchData() async {
    final Map<String, String> queryParams = {
      'category': 'all',
      'count': '1',
    };
    final uri = Uri.https(
      'famous-quotes4.p.rapidapi.com',
      '/random',
      queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'X-RapidAPI-Key': '7e44389b8amsh582e5bad6a77d01p1cb6a5jsn47a8786585f3',
        'X-RapidAPI-Host': 'famous-quotes4.p.rapidapi.com',
      },
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        quotes = List<Map<String, dynamic>>.from(responseData);
        isFavorite = false;
        favouriteButtonSize = 30;
      });
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  }

  Future<void> fetchFavoriteQuotes() async {
    final querySnapshot = await favoriteQuotesCollection.get();

    setState(() {
      favoriteQuotes = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> addAllFavoriteQuotesToFirestore() async {
    for (var quote in favoriteQuotes) {
      await favoriteQuotesCollection.add(quote);
    }
  }

  void toggleFavorite(int currentQuoteIndex) {
    setState(() {
      isFavorite = !isFavorite;
      if (isFavorite) {
        favouriteButtonSize = 50;
        _favoriteMessage = 'Added to favorites';
        addQuoteToFavorites(quotes[currentQuoteIndex]);
      } else {
        favouriteButtonSize = 30;
        _favoriteMessage = 'Removed from favorites';
        removeQuoteFromFavorites(quotes[currentQuoteIndex]);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_favoriteMessage)),
      );
    });
  }

  Future<void> addQuoteToFavorites(Map<String, dynamic> quote) {
    return favoriteQuotesCollection.add(quote);
  }

  void UpdateFavourite(Map<String, dynamic> quote) {
    setState(() {
      for (var q in quotes) {
        if (q['text'] == quote['text'] && q['author'] == quote['author']) {
          isFavorite = false;
          if (isFavorite == false) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Removed from favorites")),
            );
          } 
          break;
        }
      }
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
      fetchFavoriteQuotes();
    }
  }

  void shareQuote(String text, String author) async {
    try {
      Share.text('Quote', '"$text" -$author', 'text/plain');
    } catch (e) {
      print('Error sharing: $e');
    }
  }
}
