import 'package:flutter/material.dart';

/// Shared [ScaffoldMessenger] for in-app toasts (e.g. Reverb [notification.created]).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
