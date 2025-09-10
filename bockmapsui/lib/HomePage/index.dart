import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './contribute/contribute.dart' as contribute;
import './directions/directions.dart' as directions;
import './explore/explore.dart' as explore;
import './you/you.dart' as you;
import '../Profile/profileindex.dart' as account;
import '../SignupOrLogin/signup_or_login.dart' as auth;
import './map_background/map_background.dart';

class HomeIndex extends StatefulWidget {
  // pass forceGuest: true to force "no token" mode (shows only Directions & Explore)
  final bool forceGuest;
  const HomeIndex({super.key, this.forceGuest = false});

  @override
  State<HomeIndex> createState() => _HomeIndexState();
}

class _HomeIndexState extends State<HomeIndex>
    with SingleTickerProviderStateMixin {
  bool isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

  int _selectedIndex = 0;
  bool? _hasToken; // null => still loading

  @override
  void initState() {
    super.initState();

    // If widget.forceGuest is true, treat as no token immediately.
    if (widget.forceGuest) {
      _hasToken = false;
    } else {
      _checkToken();
    }

    _searchFocusNode.addListener(() {
      setState(() {
        isSearching = _searchFocusNode.hasFocus;
      });
    });
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    setState(() {
      _hasToken = token != null && token.isNotEmpty;
      // clamp index if needed
      if (_hasToken == false && _selectedIndex > 1) _selectedIndex = 0;
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // While loading (only when not forceGuest), show loading to avoid flicker
    if (_hasToken == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final double initialTop = 18.0;
    final double searchBarHeight = 48.0;
    final double slightlyLowerTop = 40.0;
    final double sidePaddingWhenTop = 12.0;
    final double sidePaddingWhenCentered = 48.0;

    final List<Widget> pages = _hasToken!
        ? [
      directions.DirectionsPage(),
      explore.ExplorePage(),
      you.YouPage(),
      contribute.ContributePage(),
    ]
        : [
      directions.DirectionsPage(),
      explore.ExplorePage(),
    ];

    // keep selectedIndex valid
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    final bool showSearchBar = _selectedIndex == 0 || _selectedIndex == 1;
    final bool showMapBackground = _selectedIndex == 0 || _selectedIndex == 1;

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (showMapBackground) const Positioned.fill(child: MapBackground()),
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
                left: isSearching ? sidePaddingWhenCentered : sidePaddingWhenTop,
                right: isSearching ? sidePaddingWhenCentered : sidePaddingWhenTop,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        // If has token -> account page; otherwise go to signup/login
                        if (_hasToken == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const account.AccountPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const auth.SignupOrLogin(),
                            ),
                          );
                        }
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
                    if (_hasToken! && (_selectedIndex == 2 || _selectedIndex == 3)) ...[
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
            // Prevent selecting unavailable tabs in guest mode
            if (!_hasToken! && index > 1) return;
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.purple.shade200,
          items: _hasToken!
              ? const [
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
          ]
              : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.directions),
              label: "Directions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: "Explore",
            ),
          ],
        ),
      ),
    );
  }
}
