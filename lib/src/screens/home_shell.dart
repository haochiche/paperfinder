import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import 'discovery_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final screens = [
      SearchScreen(controller: controller),
      DiscoveryScreen(controller: controller),
      SavedScreen(controller: controller),
      SettingsScreen(controller: controller),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6F0E6),
              Color(0xFFECE4D5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      title: Text(controller.errorMessage!),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: controller.clearError,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: controller.selectedTabIndex,
                  children: screens,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.selectedTabIndex,
        onDestinationSelected: controller.setTabIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.style), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

