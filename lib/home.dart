import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  late Offset _searchPosition;
  late Offset _playStorePosition;
  late Offset _folderPosition;
  late Offset _chromePosition;
  late Offset _settingsPosition;
  bool showSearchResults = false;
  bool _isDraggable = false;
  bool _isPlayStoreDraggable = false;
  final double itemHeight = 56.0;
  final double spacing = 20.0;
  bool isSearchOnTop = true;
  String? draggingItem;
  bool isTransitioning = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializePositions();
      _isInitialized = true;
    }
  }

  void _initializePositions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Search position - centered horizontally, fixed distance from top
    _searchPosition = Offset(
        (screenWidth - screenWidth * 0.9) / 2, // Center horizontally
        100 // Fixed distance from top
        );

    // Bottom icons positioning
    final bottomY = screenHeight - 150; // Moved up slightly
    final iconWidth = 60.0; // Width of each icon
    final totalIcons = 4; // Number of icons
    final totalWidth = iconWidth * totalIcons;
    final horizontalPadding = 20.0; // Padding from screen edges

    // Calculate spacing between icons
    final availableWidth = screenWidth - (2 * horizontalPadding);
    final spacing = (availableWidth - totalWidth) / (totalIcons - 1);

    // Position each icon with equal spacing
    final startX = horizontalPadding;
    _playStorePosition = Offset(startX, bottomY);
    _folderPosition = Offset(startX + (iconWidth + spacing), bottomY);
    _chromePosition = Offset(startX + (iconWidth + spacing) * 2, bottomY);
    _settingsPosition = Offset(startX + (iconWidth + spacing) * 3, bottomY);
  }

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

  void _startDragging(String itemType) {
    setState(() {
      draggingItem = itemType;
    });

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            DragOverlayScreen(
          initialPosition: itemType == 'search'
              ? _searchPosition
              : itemType == 'playstore'
                  ? _playStorePosition
                  : itemType == 'folder'
                      ? _folderPosition
                      : itemType == 'chrome'
                          ? _chromePosition
                          : _settingsPosition,
          itemType: itemType,
          onDragEnd: (finalPosition) {
            setState(() {
              if (itemType == 'search') {
                _searchPosition = finalPosition;
              } else if (itemType == 'playstore') {
                _playStorePosition = finalPosition;
              } else if (itemType == 'folder') {
                _folderPosition = finalPosition;
              } else if (itemType == 'chrome') {
                _chromePosition = finalPosition;
              } else if (itemType == 'settings') {
                _settingsPosition = finalPosition;
              }
            });
            Navigator.of(context).pop();
            Future.delayed(Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  draggingItem = null;
                });
              }
            });
          },
          otherItemPosition:
              itemType == 'search' ? _playStorePosition : _searchPosition,
          searchButton: _buildSearchButton(),
          playStoreButton: _buildPlayStoreButton(),
          folderButton: _buildFolderButton(),
          chromeButton: _buildChromeButton(),
          settingsButton: _buildSettingsButton(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Search Widget
          Positioned(
            left: _searchPosition.dx,
            top: _searchPosition.dy,
            child: Visibility(
              visible: draggingItem != 'search',
              child: GestureDetector(
                onLongPress: () => _startDragging('search'),
                child: _buildSearchButton(),
              ),
            ),
          ),

          // Play Store Icon
          Positioned(
            left: _playStorePosition.dx,
            top: _playStorePosition.dy,
            child: Visibility(
              visible: draggingItem != 'playstore',
              child: GestureDetector(
                onLongPress: () => _startDragging('playstore'),
                child: _buildPlayStoreButton(),
              ),
            ),
          ),

          // Folder Button
          Positioned(
            left: _folderPosition.dx,
            top: _folderPosition.dy,
            child: Visibility(
              visible: draggingItem != 'folder',
              child: GestureDetector(
                onLongPress: () => _startDragging('folder'),
                child: _buildFolderButton(),
              ),
            ),
          ),

          // Chrome Icon
          Positioned(
            left: _chromePosition.dx,
            top: _chromePosition.dy,
            child: Visibility(
              visible: draggingItem != 'chrome',
              child: GestureDetector(
                onLongPress: () => _startDragging('chrome'),
                child: _buildChromeButton(),
              ),
            ),
          ),

          // Settings Icon
          Positioned(
            left: _settingsPosition.dx,
            top: _settingsPosition.dy,
            child: Visibility(
              visible: draggingItem != 'settings',
              child: GestureDetector(
                onLongPress: () => _startDragging('settings'),
                child: _buildSettingsButton(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 56,
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.phone,
                color: Colors.white,
              ),
              onPressed: () async {
                Navigator.pushNamed(context, 'phone');
              },
            ),
            IconButton(
              icon: Icon(
                Icons.apps,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, 'apps');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Colors.white,
      ),
      width: MediaQuery.of(context).size.width * 0.9,
      child: MaterialButton(
        onPressed: _openSearchScreen,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search Yahoo...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            Icon(
              Icons.search,
              color: Colors.grey[600],
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildPlayStoreButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Colors.white,
      ),
      child: GestureDetector(
        onTap: () async {
          final AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            category: 'android.intent.category.LAUNCHER',
            package: 'com.android.vending',
          );
          await intent.launch();
        },
        child: Container(
          width: 60,
          height: 60,
          padding: EdgeInsets.all(8),
          child: SvgPicture.asset(
            'assets/icons/google-play-icon.svg',
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildFolderButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Colors.white.withOpacity(0.8),
      ),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => FolderContentScreen(),
          );
        },
        child: Container(
          width: 60,
          height: 60,
          padding: EdgeInsets.all(4),
          child: GridView.count(
            crossAxisCount: 2,
            padding: EdgeInsets.all(4),
            children: [
              SvgPicture.asset(
                'assets/icons/google-play-icon.svg',
                width: 20,
                height: 20,
              ),
              Icon(Icons.web, size: 20),
              Icon(Icons.shopping_bag, size: 20),
              Icon(Icons.games, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChromeButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Colors.white,
      ),
      child: GestureDetector(
        onTap: () async {
          final AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            category: 'android.intent.category.LAUNCHER',
            package: 'com.android.chrome',
          );
          await intent.launch();
        },
        child: Container(
          width: 60,
          height: 60,
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.public,
            size: 32,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Colors.white,
      ),
      child: GestureDetector(
        onTap: () async {
          final AndroidIntent intent = AndroidIntent(
            action: 'android.settings.SETTINGS',
          );
          await intent.launch();
        },
        child: Container(
          width: 60,
          height: 60,
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.settings,
            size: 32,
            color: Colors.grey[700],
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

class DragOverlayScreen extends StatefulWidget {
  final Offset initialPosition;
  final String itemType;
  final Function(Offset) onDragEnd;
  final Offset otherItemPosition;
  final Widget searchButton;
  final Widget playStoreButton;
  final Widget folderButton;
  final Widget chromeButton;
  final Widget settingsButton;

  const DragOverlayScreen({
    required this.initialPosition,
    required this.itemType,
    required this.onDragEnd,
    required this.otherItemPosition,
    required this.searchButton,
    required this.playStoreButton,
    required this.folderButton,
    required this.chromeButton,
    required this.settingsButton,
  });

  @override
  _DragOverlayScreenState createState() => _DragOverlayScreenState();
}

class _DragOverlayScreenState extends State<DragOverlayScreen> {
  late Offset _currentPosition;
  final double itemHeight = 56.0;
  final double spacing = 20.0;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
  }

  Offset _getAdjustedPosition(BuildContext context) {
    final itemRect = Rect.fromLTWH(
      _currentPosition.dx,
      _currentPosition.dy,
      300,
      itemHeight,
    );
    final otherRect = Rect.fromLTWH(
      widget.otherItemPosition.dx,
      widget.otherItemPosition.dy,
      300,
      itemHeight,
    );

    if (itemRect.overlaps(otherRect)) {
      final screenHeight = MediaQuery.of(context).size.height - 70;

      // Determine if we should move up or down based on the center points
      final itemCenter = _currentPosition.dy + (itemHeight / 2);
      final otherCenter = widget.otherItemPosition.dy + (itemHeight / 2);

      if (itemCenter < otherCenter) {
        // Move above if there's space
        final newY = widget.otherItemPosition.dy - itemHeight - spacing;
        if (newY >= 0) {
          return Offset(_currentPosition.dx, newY);
        } else {
          // If no space above, move below
          return Offset(_currentPosition.dx,
              widget.otherItemPosition.dy + itemHeight + spacing);
        }
      } else {
        // Move below if there's space
        final newY = widget.otherItemPosition.dy + itemHeight + spacing;
        if (newY + itemHeight <= screenHeight) {
          return Offset(_currentPosition.dx, newY);
        } else {
          // If no space below, move above
          return Offset(_currentPosition.dx,
              widget.otherItemPosition.dy - itemHeight - spacing);
        }
      }
    }

    return _currentPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            left: _currentPosition.dx,
            top: _currentPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _currentPosition = Offset(
                    _currentPosition.dx + details.delta.dx,
                    _currentPosition.dy + details.delta.dy,
                  );
                });
              },
              onPanEnd: (_) {
                final adjustedPosition = _getAdjustedPosition(context);
                widget.onDragEnd(adjustedPosition);
              },
              child: widget.itemType == 'search'
                  ? widget.searchButton
                  : widget.itemType == 'playstore'
                      ? widget.playStoreButton
                      : widget.itemType == 'folder'
                          ? widget.folderButton
                          : widget.itemType == 'chrome'
                              ? widget.chromeButton
                              : widget.settingsButton,
            ),
          ),
        ],
      ),
    );
  }
}

class FolderContentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Quick Links',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              padding: EdgeInsets.all(12),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _buildIconTile(
                  context,
                  icon: SvgPicture.asset(
                    'assets/icons/google-play-icon.svg',
                    width: 40,
                    height: 40,
                  ),
                  label: 'Play Store',
                  onTap: () async {
                    final AndroidIntent intent = AndroidIntent(
                      action: 'android.intent.action.MAIN',
                      category: 'android.intent.category.LAUNCHER',
                      package: 'com.android.vending',
                    );
                    await intent.launch();
                  },
                ),
                _buildIconTile(
                  context,
                  icon: Icon(Icons.search, size: 32, color: Colors.purple),
                  label: 'Yahoo',
                  onTap: () async {
                    final url = Uri.parse('https://www.yahoo.com');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                _buildIconTile(
                  context,
                  icon:
                      Icon(Icons.shopping_cart, size: 32, color: Colors.orange),
                  label: 'Amazon',
                  onTap: () async {
                    final url = Uri.parse('https://www.amazon.com');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                _buildIconTile(
                  context,
                  icon: Icon(Icons.facebook, size: 32, color: Colors.blue),
                  label: 'Facebook',
                  onTap: () async {
                    final url = Uri.parse('https://www.facebook.com');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTile(
    BuildContext context, {
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon,
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
