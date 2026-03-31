# "Live" Moment Interactions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the current "heavy" Moment liking and commenting into a high-energy, "Live First" optimistic experience.

**Architecture:** Use local state reconciliation in Riverpod to update counts and lists instantly, and refactor the Detail Screen to reactively observe the main Moments feed as the single source of truth.

**Tech Stack:** Flutter, Riverpod, Serverpod, `flutter_animate`.

---

### Task 1: Enhance `Moments` Notifier with Local Reconciliation

**Files:**
- Modify: `talktive_flutter/lib/providers/moments_provider.dart`

- [ ] **Step 1: Add `updateMomentLocally` helper to `Moments` class**
- [ ] **Step 2: Refactor `toggleLike` for optimistic updates**
- [ ] **Step 3: Commit changes**

---

### Task 2: Reactive Detail Screen Refactor

**Files:**
- Modify: `talktive_flutter/lib/screens/moments/moment_detail_screen.dart`

- [ ] **Step 1: Update constructor to take `momentId` instead of the full object**
- [ ] **Step 2: Update `build` method to watch the specific moment reactively**
- [ ] **Step 3: Update `_toggleLike` to use the new reactive flow**
- [ ] **Step 4: Commit changes**

---

### Task 3: Optimistic Commenting and Reconciliation

**Files:**
- Modify: `talktive_flutter/lib/providers/moments_provider.dart`
- Modify: `talktive_flutter/lib/screens/moments/moment_detail_screen.dart`

- [ ] **Step 1: Enhance `MomentComments` with local addition and count reconciliation**
- [ ] **Step 2: Update `_postComment` in `MomentDetailScreen` to remove manual refresh logic**
- [ ] **Step 3: Commit changes**

---

### Task 4: Fix Navigation (GoRouter)

**Files:**
- Modify: `talktive_flutter/lib/config/router.dart` (Check file existence first)

- [ ] **Step 1: Find the `/moments/detail` route and update it to support ID-based loading**
- [ ] **Step 2: Commit changes**

---

### Task 5: Aesthetic Polish (Animations)

**Files:**
- Modify: `talktive_flutter/lib/widgets/duo/duo_moment_card.dart`
- Modify: `talktive_flutter/lib/screens/moments/moment_detail_screen.dart`

- [ ] **Step 1: Add bounce animation to the heart icon when liked**
- [ ] **Step 2: Commit changes**

---

### Task 6: Final Verification

- [ ] **Step 1: Run Flutter Analyze**
- [ ] **Step 2: Manual Smoke Test**
