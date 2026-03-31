# Premium Features Gating Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement tiered feature access (Paid, Trial, Regular) with a 14-day data grace period and specific search/ad-hiding logic.

**Architecture:** Centralized permission logic in `ResidentService`, default initialization on tier changes, and updated validation in endpoints.

**Tech Stack:** Dart, Serverpod, Flutter, Riverpod.

---

### Task 1: Update Resident Protocol

**Files:**
- Modify: `talktive_server/lib/src/protocol/resident.spy.yaml`

- [ ] **Step 1: Rename `showNeighborsDiscovery` to `showAdvancedDiscovery`**

Update the field name in `resident.spy.yaml`.

- [ ] **Step 2: Generate Serverpod code**

Run: `serverpod generate` from `talktive_server` directory.
Expected: SUCCESS

- [ ] **Step 3: Commit**

```bash
git add talktive_server/lib/src/protocol/resident.spy.yaml talktive_server/lib/src/generated/ talktive_client/lib/src/protocol/
git commit -m "feat: rename Neighbors Discovery to Advanced Discovery in protocol"
```

---

### Task 2: Enhance ResidentService with Tier Logic

**Files:**
- Modify: `talktive_server/lib/src/services/resident_service.dart`

- [ ] **Step 1: Implement `isPaidMember`, `isWithinGracePeriod`, and `applyTierDefaults`**

Add these methods to `ResidentService`. Ensure `isWithinGracePeriod` checks `premiumTrialExpires` + 14 days.

- [ ] **Step 2: Update `isPlusMember` and `canUseCustomAvatar` / `canUseVoiceMessages`**

Update existing permission checks to use `isPlusMember(resident) && resident.toggle`.

- [ ] **Step 3: Commit**

```bash
git add talktive_server/lib/src/services/resident_service.dart
git commit -m "feat: implement tier-aware permission logic in ResidentService"
```

---

### Task 3: Update MessagingService Voice Check

**Files:**
- Modify: `talktive_server/lib/src/services/messaging_service.dart`

- [ ] **Step 1: Fix voice message check to use `ResidentService.isPlusMember`**

Replace `!sender.isPremium` with `!ResidentService.isPlusMember(sender)`.

- [ ] **Step 2: Commit**

```bash
git add talktive_server/lib/src/services/messaging_service.dart
git commit -m "fix: allow trial users to send voice messages"
```

---

### Task 4: Update ResidentEndpoint Privacy Logic

**Files:**
- Modify: `talktive_server/lib/src/endpoints/resident_endpoint.dart`

- [ ] **Step 1: Update `updatePrivacy` to enforce tier restrictions**

Enforce that Trial users cannot enable `hideAds` and Regular users cannot enable any premium toggles.

- [ ] **Step 2: Commit**

```bash
git add talktive_server/lib/src/endpoints/resident_endpoint.dart
git commit -m "feat: enforce tier restrictions in updatePrivacy endpoint"
```

---

### Task 5: Implement 14-Day Grace Period in Content Cleanup

**Files:**
- Modify: `talktive_server/lib/src/services/content_ephemerality_service.dart`

- [ ] **Step 1: Update `_cleanupPrivateMessages` to respect grace period**

Modify the resident search in `_cleanupPrivateMessages` to include users who are within the 14-day grace period of their `premiumTrialExpires`.

- [ ] **Step 2: Commit**

```bash
git add talktive_server/lib/src/services/content_ephemerality_service.dart
git commit -m "feat: implement 14-day grace period for private chat retention"
```

---

### Task 6: Update SearchService for Advanced Discovery

**Files:**
- Modify: `talktive_server/lib/src/services/search_service.dart`

- [ ] **Step 1: Restrict filtered/termed search to Plus members**

In `searchUsers` and `searchLounges`, check if `term` or `filters` are provided. If so, verify `ResidentService.canUseAdvancedDiscovery(currentUser)`.

- [ ] **Step 2: Commit**

```bash
git add talktive_server/lib/src/services/search_service.dart
git commit -m "feat: restrict advanced search to Plus members"
```

---

### Task 7: Update Flutter Settings UI

**Files:**
- Modify: `talktive_flutter/lib/screens/activity/settings_screen.dart`

- [ ] **Step 1: Disable toggles based on tier and update naming**

Rename "Neighbors Discovery" to "Advanced Discovery" and disable "Hide Ads" for trial users. Disable all for regular users.

- [ ] **Step 2: Commit**

```bash
git add talktive_flutter/lib/screens/activity/settings_screen.dart
git commit -m "ui: update settings screen with tier restrictions and renaming"
```

---

### Task 8: Final Verification

- [ ] **Step 1: Run server tests**

Run: `cd talktive_server && dart test`

- [ ] **Step 2: Run flutter analyze**

Run: `cd talktive_flutter && flutter analyze`
