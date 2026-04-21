import 'package:equatable/equatable.dart';

final class AdvertiserBalance extends Equatable {
  const AdvertiserBalance({
    required this.available,
    required this.locked,
    required this.spent,
    required this.currency,
  });

  final double available;
  final double locked;
  final double spent;
  final String currency;

  @override
  List<Object?> get props => [available, locked, spent, currency];
}
