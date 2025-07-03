import { User } from './types';

/**
 * Shared reputation calculation utilities for consistent scoring across client and server
 */

/**
 * Reputation level thresholds - keep in sync with client-side Dart code
 */
export const REPUTATION_THRESHOLDS = {
  EXCELLENT: 0.90,
  GOOD: 0.80,
  FAIR: 0.60,
  POOR: 0.40,
} as const;

/**
 * Calculate reputation score based on total reports vs total messages.
 * Uses a dampened formula to balance the impact of reports against activity.
 *
 * Formula: 1.0 - (totalReports / sqrt(totalMessages + dampening))
 * Where dampening = (totalMessages * 0.1).clamp(5.0, 50.0) to provide stability
 *
 * @param user - User object containing messageCount and reportCount
 * @returns reputation score between 0.0 and 1.0, where 1.0 is perfect reputation
 */
export const calculateReputationScore = (user: User): number => {
  if (!user.messageCount || user.messageCount <= 0) return 1.0;
  if (!user.reportCount || user.reportCount <= 0) return 1.0;

  // Apply dampening to prevent extreme drops from limited data
  const dampening = Math.max(5.0, Math.min(50.0, user.messageCount * 0.1));
  const adjustedTotal = user.messageCount + dampening;
  const ratio = user.reportCount / Math.sqrt(adjustedTotal);
  const score = 1.0 - ratio;

  // Ensure score is between 0.0 and 1.0
  return Math.max(0.0, Math.min(1.0, score));
};

/**
 * Get reputation level as a string based on score thresholds
 * @param score - Reputation score between 0.0 and 1.0
 * @returns reputation level string
 */
export const getReputationLevel = (score: number): string => {
  if (score >= REPUTATION_THRESHOLDS.EXCELLENT) return 'excellent';
  if (score >= REPUTATION_THRESHOLDS.GOOD) return 'good';
  if (score >= REPUTATION_THRESHOLDS.FAIR) return 'fair';
  if (score >= REPUTATION_THRESHOLDS.POOR) return 'poor';
  return 'very_poor';
};

/**
 * Check if user has good reputation (score >= 0.80)
 * @param user - User object
 * @returns true if user has good reputation
 */
export const hasGoodReputation = (user: User): boolean => {
  return calculateReputationScore(user) >= REPUTATION_THRESHOLDS.GOOD;
};

/**
 * Check if user has poor reputation (score < 0.60)
 * @param user - User object
 * @returns true if user has poor reputation
 */
export const hasPoorReputation = (user: User): boolean => {
  return calculateReputationScore(user) < REPUTATION_THRESHOLDS.FAIR;
};

/**
 * Calculate restriction duration multiplier based on reputation score
 * Users with better reputation get shorter restrictions
 *
 * @param user - User object
 * @returns multiplier between 0.1 and 1.0 (lower score = longer restriction)
 */
export const getRestrictionMultiplier = (user: User): number => {
  const reputationScore = calculateReputationScore(user);
  // Invert the score so poor reputation leads to longer restrictions
  // Apply minimum multiplier of 0.1 to prevent extremely long restrictions
  return Math.max(0.1, 1.0 - reputationScore);
};

/**
 * Get user reputation summary for logging/debugging
 * @param user - User object
 * @returns object with reputation details
 */
export const getReputationSummary = (user: User) => {
  const score = calculateReputationScore(user);
  const level = getReputationLevel(score);

  return {
    score: Math.round(score * 1000) / 1000, // Round to 3 decimal places
    level,
    messageCount: user.messageCount || 0,
    reportCount: user.reportCount || 0,
    hasGoodReputation: hasGoodReputation(user),
    hasPoorReputation: hasPoorReputation(user),
  };
};
