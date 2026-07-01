import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../data/change_password_remote.dart';

final changePasswordRemoteProvider = Provider<ChangePasswordRemote>(
  (ref) => ChangePasswordRemote(ref.watch(wayoAdsDioProvider)),
);
