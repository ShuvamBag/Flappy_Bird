# Flappy_Bird 

The objective is to keep the bird airborne for as long as possible by tapping or clicking the screen, causing the bird to flap its wings and ascend. The challenge lies in the precise timing required to maneuver the bird through the gaps between the pipes, as a single collision with either the ground or a pipe results in an instant game over.

The game's mechanics are straightforward, but its execution demands exceptional hand-eye coordination and quick reflexes. With each successful gap cleared, players earn points, and the ultimate goal is to achieve the highest score possible. Flappy Bird intentionally lacks any progress checkpoints or levels, emphasizing a relentless difficulty curve that ramps up the longer the player survives.

Made using Flutter and Dart.

Available for ANDROID , IOS , WEB .....

## Online Leaderboard Setup

The online leaderboard uses Firebase Realtime Database and anonymous Firebase Authentication. The existing Firebase web app is configured in `lib/firebase_options.dart`; web runs and builds need no extra key arguments. Anonymous sign-in is enabled, and `database.rules.json` is deployed to the configured project. The rules require sign-in and only allow a player's existing score to increase.

The checked-in `.firebaserc` selects the leaderboard project. From this project directory, deploy future rule changes with `firebase deploy --only database`. Android and iOS app registrations have not been added to the Firebase project yet; register those apps and supply their app IDs before using the online leaderboard in native builds.
## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
