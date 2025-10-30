class ErrorMessages {
  static String getAuthErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (errorLower.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }

    if (errorLower.contains('user not found')) {
      return 'No account found with this email address.';
    }

    if (errorLower.contains('too many requests')) {
      return 'Too many login attempts. Please try again later.';
    }

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorLower.contains('user already registered') ||
        errorLower.contains('email already in use')) {
      return 'An account with this email already exists.';
    }

    if (errorLower.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (errorLower.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (errorLower.contains('cancelled') || errorLower.contains('canceled')) {
      return 'Sign in was cancelled.';
    }

    // Generic fallback
    return 'An error occurred. Please try again.';
  }

  static String getGenericErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorLower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorLower.contains('not found')) {
      return 'The requested item was not found.';
    }

    if (errorLower.contains('permission denied') ||
        errorLower.contains('unauthorized')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Generic fallback
    return 'An error occurred. Please try again.';
  }
}
