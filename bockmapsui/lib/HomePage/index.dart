import 'package:flutter/material.dart';
import './contribute/contribute.dart' as contribute;
import './directions/directions.dart' as directions;
import './explore/explore.dart' as explore;
import './you/you.dart' as you;
import '../Profile/profileindex.dart' as account;
import './map_background/map_background.dart';


class HomeIndex extends StatefulWidget {
  const HomeIndex({super.key});

  @override
  State<HomeIndex> createState() => _HomeIndexState();
}

class _HomeIndexState extends State<HomeIndex>
    with SingleTickerProviderStateMixin {
  bool isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        isSearching = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double initialTop = 18.0;
    final double searchBarHeight = 48.0;
    final double slightlyLowerTop = 40.0;
    final double sidePaddingWhenTop = 12.0;
    final double sidePaddingWhenCentered = 48.0;

    final bool showSearchBar = _selectedIndex == 0 || _selectedIndex == 1;

    final List<Widget> pages = [
      directions.DirectionsPage(),
      explore.ExplorePage(),
      you.YouPage(),
      contribute.ContributePage(),
    ];

    final bool showMapBackground = _selectedIndex == 0 || _selectedIndex == 1;

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (showMapBackground)
              const Positioned.fill(child: MapBackground()),
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Expanded(child: pages[_selectedIndex]),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOutCubic,
                top: isSearching ? slightlyLowerTop : initialTop,
                left: isSearching
                    ? sidePaddingWhenCentered
                    : sidePaddingWhenTop,
                right: isSearching
                    ? sidePaddingWhenCentered
                    : sidePaddingWhenTop,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const account.AccountPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person),
                      ),
                    ),
                    if (_selectedIndex == 2 || _selectedIndex == 3) ...[
                      const SizedBox(width: 18),
                      Text(
                        _selectedIndex == 2 ? "You" : "Contribute",
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                    if (showSearchBar) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeInOutCubic,
                          height: searchBarHeight,
                          decoration: BoxDecoration(
                            boxShadow: isSearching
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: TextField(
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search destinations...',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: isSearching
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _searchFocusNode.unfocus();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.purple.shade200,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.directions),
              label: "Directions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: "Explore",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "You"),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box),
              label: "Contribute",
            ),
          ],
        ),
      ),
    );
  }
}
