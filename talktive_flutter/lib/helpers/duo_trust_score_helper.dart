import 'package:flutter/material.dart';
import '../config/theme.dart';

class DuoTrustScoreHelper {
  /// Returns the appropriate color for a given trust score.
  static Color getTrustColor(int trustScore) {
    if (trustScore >= 50) {
      return AppTheme.duoGreen; // Friendly / Highly Trusted
    } else if (trustScore >= 10) {
      return AppTheme.primaryColor; // Normal / Trusted
    } else if (trustScore >= 0) {
      return AppTheme.duoYellow; // New or Neutral
    } else if (trustScore >= -10) {
      return AppTheme.duoOrange; // Suspicious / Low Trust
    } else {
      return AppTheme.duoRed; // Dangerous / Very Low Trust
    }
  }

  /// Returns a descriptive string for the trust level.
  static String getTrustLabel(int trustScore) {
    if (trustScore >= 50) return 'Highly Trusted';
    if (trustScore >= 10) return 'Trusted';
    if (trustScore >= 0) return 'Neutral';
    if (trustScore >= -10) return 'Suspicious';
    return 'Dangerous';
  }
}
