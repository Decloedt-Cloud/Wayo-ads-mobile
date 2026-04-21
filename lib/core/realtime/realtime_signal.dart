import 'package:equatable/equatable.dart';

/// Normalised realtime payload for dashboard invalidation.
final class RealtimeSignal extends Equatable {
  const RealtimeSignal({required this.name, this.channelName, this.raw});

  final String name;
  final String? channelName;
  final Object? raw;

  @override
  List<Object?> get props => [name, channelName, raw];
}
