import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'chats_screen.dart';
import 'users_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatsScreen(),
    const UsersScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Optimized status switching
    final isResumed = state == AppLifecycleState.resumed;
    _updateOnlineStatus(isResumed);
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId != null) {
      if (isOnline) {
        await databaseService.setUserOnline(userId);
      } else {
        await databaseService.setUserOffline(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final currentUserId = authService.currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      // Optional: Add a custom AppBar for consistent branding across tabs
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {}, // Add global search functionality
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: theme.primaryColor.withOpacity(0.1),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColor);
              }
              return const TextStyle(fontSize: 12, color: Colors.grey);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick(); // Tactile feedback
              setState(() => _currentIndex = index);
            },
            backgroundColor: Colors.white,
            elevation: 0,
            height: 65,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chats',
              ),
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: StreamBuilder<int>(
                  stream: currentUserId != null
                      ? databaseService.getNotificationsStream(currentUserId).map(
                        (notifications) =>
                    notifications.where((n) => n['isRead'] == false).length,
                  )
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return Badge(
                      label: Text('$unreadCount'),
                      isLabelVisible: unreadCount > 0,
                      backgroundColor: Colors.redAccent,
                      child: const Icon(Icons.notifications_none_rounded),
                    );
                  },
                ),
                selectedIcon: const Icon(Icons.notifications_rounded),
                label: 'Updates',
              ),
              const NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'Messages';
      case 1: return 'Explore';
      case 2: return 'Notifications';
      case 3: return 'Account';
      default: return 'App';
    }
  }
}