# Paperfinder

`Paperfinder` is an Android-first Flutter app for academic paper discovery. Users search OpenAlex by keyword and filters, triage results with swipe cards, and save selected papers into Zotero.

## Current Scope

- OpenAlex paper search with keyword, year range, and journal/source filtering
- Swipeable paper cards with expandable abstracts
- Local saved/skipped state and search history
- Zotero API key setup and configurable collection save target
- Future-ready ranking interface for semantic reranking

## Local Setup

This repository was implemented in an environment without the Flutter SDK installed, so platform folders were not generated with `flutter create`.

To make the project runnable locally:

1. Install Flutter.
2. From this repository root, run `flutter create . --platforms=android,ios`.
3. Run `flutter pub get`.
4. Start the app with `flutter run`.

The generated platform folders should coexist with the source tree in `lib/` and `test/`.

