void Function()? _onForceLogout;

/// Registered by [AuthNotifier] so [AuthInterceptor] can end the session without import cycles.
void setAuthForceLogoutHandler(void Function() fn) => _onForceLogout = fn;

void clearAuthForceLogoutHandler() => _onForceLogout = null;

void notifyAuthForceLogout() => _onForceLogout?.call();
