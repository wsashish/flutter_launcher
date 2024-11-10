import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const HomePageState();
  }
}

class HomePageState extends StatefulWidget {
  const HomePageState({Key? key}) : super(key: key);

  @override
  _HomePageStateState createState() => _HomePageStateState();
}

class _HomePageStateState extends State<HomePageState> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  Offset _searchPosition = Offset(0, 100); // Initial position
  bool showSearchResults = false;

  Future<void> _performSearch(String query) async {
    setState(() {
      isLoading = true;
      searchResults.clear();
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://search.yahoo.com/search?p=${Uri.encodeComponent(query)}'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final results = document.querySelectorAll('.algo');

        final newResults = results.take(4).map((result) {
          final titleElement = result.querySelector('h3');
          final linkElement = result.querySelector('a');
          final descElement = result.querySelector('.compText');

          return {
            'title': titleElement?.text ?? 'No title',
            'link': linkElement?.attributes['href'] ?? '',
            'description': descElement?.text ?? 'No description',
          };
        }).toList();

        setState(() {
          searchResults = newResults;
          isLoading = false;
        });

        print(searchResults.length.toString());
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            left: _searchPosition.dx,
            top: _searchPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _searchPosition = Offset(
                    _searchPosition.dx + details.delta.dx,
                    _searchPosition.dy + details.delta.dy,
                  );
                });
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  minWidth: MediaQuery.of(context).size.width * 0.5,
                ),
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Yahoo...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _openSearchScreen(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onTap: () => _openSearchScreen(),
                  readOnly: true, // Make it open search screen on tap
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Container(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, "phone"),
                icon: Icon(Icons.phone),
              ),
              IconButton(
                icon: Icon(Icons.apps),
                onPressed: () => Navigator.pushNamed(context, "apps"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearchScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          initialQuery: _searchController.text,
          onSearch: _performSearch,
          searchResults: searchResults,
        ),
      ),
    );
  }
}

// Create a new SearchScreen widget
class SearchScreen extends StatefulWidget {
  final String initialQuery;
  final Function(String) onSearch;
  final List<Map<String, dynamic>> searchResults;

  const SearchScreen({
    Key? key,
    required this.initialQuery,
    required this.onSearch,
    required this.searchResults,
  }) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    searchResults = widget.searchResults;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://search.yahoo.com/search?p=${Uri.encodeComponent(query)}'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final results = document.querySelectorAll('.algo');

        final newResults = results.take(4).map((result) {
          final titleElement = result.querySelector('h3');
          final linkElement = result.querySelector('a');
          final descElement = result.querySelector('.compText');

          return {
            'title': titleElement?.text ?? 'No title',
            'link': linkElement?.attributes['href'] ?? '',
            'description': descElement?.text ?? 'No description',
          };
        }).toList();

        setState(() {
          searchResults = newResults;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search Yahoo...',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) => _performSearch(value),
              onChanged: (value) => _performSearch(value),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final result = searchResults[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      result['title']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF720e9e),
                      ),
                    ),
                    subtitle: Text(
                      result['description']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      final url = result['link']?.toString();
                      if (url != null && url.isNotEmpty) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
