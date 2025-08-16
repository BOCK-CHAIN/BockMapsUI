import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../SignupOrLogin/signup_or_login.dart';

class HomeIndex extends StatefulWidget {
  const HomeIndex({super.key});

  @override
  State<HomeIndex> createState() => _HomeIndexState();
}

class _HomeIndexState extends State<HomeIndex> with SingleTickerProviderStateMixin {
  bool isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();

  final String backendUrl = 'http://10.0.2.2:3000'; // Android emulator

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

  Future<void> _logout() async {
    try {
      final url = Uri.parse('$backendUrl/api/auth/logout');
      await http.post(url, headers: {
        'Content-Type': 'application/json',
      });

      // Show logout message first
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            duration: Duration(seconds: 2),
          ),
        );

        // Wait for a short moment so user can see the message
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignupOrLogin()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out, please try again'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double initialTop = 18.0;
    final double searchBarHeight = 48.0;
    final double slightlyLowerTop = 40.0;
    final double sidePaddingWhenTop = 12.0;
    final double sidePaddingWhenCentered = 48.0;

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
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
              AnimatedPositioned(
                duration: Duration(milliseconds: 420),
                curve: Curves.easeInOutCubic,
                top: isSearching ? slightlyLowerTop : initialTop,
                left: isSearching ? sidePaddingWhenCentered : sidePaddingWhenTop,
                right: isSearching ? sidePaddingWhenCentered : sidePaddingWhenTop,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.horizontal,
                            child: child,
                          ),
                        );
                      },
                      child: isSearching
                          ? const SizedBox.shrink(key: ValueKey('empty'))
                          : InkWell(
                        key: const ValueKey('logout'),
                        onTap: _logout,
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
