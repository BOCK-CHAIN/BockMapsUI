import 'package:flutter/material.dart';

class HomeIndex extends StatefulWidget {
  const HomeIndex({super.key});

  @override
  State<HomeIndex> createState() => _HomeIndexState();
}

class _HomeIndexState extends State<HomeIndex> with SingleTickerProviderStateMixin {
  bool isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

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
    // animation parameters
    final double initialTop = 18.0; // normal top position
    final double searchBarHeight = 48.0;
    // small drop when searching
    final double slightlyLowerTop = 40.0;
    // horizontal padding changes to center bar when searching
    final double sidePaddingWhenTop = 12.0;
    final double sidePaddingWhenCentered = 48.0;

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Background / content
              Positioned.fill(
                child: Column(
                  children: [
                    SizedBox(height: 80),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Map / content goes here',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search + logout row
              AnimatedPositioned(
                duration: Duration(milliseconds: 420),
                curve: Curves.easeInOutCubic,
                top: isSearching ? slightlyLowerTop : initialTop,
                left: isSearching ? sidePaddingWhenCentered : sidePaddingWhenTop,
                right: isSearching ? sidePaddingWhenCentered : sidePaddingWhenTop,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logout button
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(sizeFactor: animation, axis: Axis.horizontal, child: child),
                        );
                      },
                      child: isSearching
                          ? const SizedBox.shrink(key: ValueKey('empty'))
                          : InkWell(
                        key: const ValueKey('logout'),
                        onTap: () {
                          Navigator.pop(context);
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
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(Icons.exit_to_app),
                        ),
                      ),
                    ),

                    if (!isSearching) const SizedBox(width: 12),

                    // Search bar
                    Expanded(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 420),
                        curve: Curves.easeInOutCubic,
                        height: searchBarHeight,
                        decoration: BoxDecoration(
                          boxShadow: isSearching
                              ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            )
                          ]
                              : null,
                        ),
                        child: TextField(
                          focusNode: _searchFocusNode,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search destinations...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
