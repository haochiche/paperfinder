import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'repositories/local_store.dart';
import 'repositories/openalex_repository.dart';
import 'repositories/zotero_repository.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

class PaperfinderApp extends StatefulWidget {
  const PaperfinderApp({super.key});

  @override
  State<PaperfinderApp> createState() => _PaperfinderAppState();
}

class _PaperfinderAppState extends State<PaperfinderApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(
      openAlexRepository: OpenAlexRepository(),
      zoteroRepository: ZoteroRepository(),
      localStore: LocalStore(),
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Paperfinder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          home: HomeShell(controller: _controller),
        );
      },
    );
  }
}

