# Admin Safety System: Staff Roles & Community Moderation

We have implemented a tiered moderation system for the Talktive platform. This ensures that community management tasks can be shared between Administrators and Moderators, while keeping sensitive system settings restricted to top-level Admins.

## 🛠 Features Implemented

### 1. Centralized Role System (Enum-based)
- **Residents**: All users now have a single `role` field (Enumerated: `user`, `moderator`, `admin`).
- **Admins**: Full system access. They can manage roles (promote/demote staff), view platform-wide statistics, and perform system maintenance.
- **Moderators**: Community management access. They can handle reports, suspend/mute users, and moderate lounges/messages.
- **System Service**: Automated monitoring and reputation cleaning.

### 2. Tiered Access Control
- **Staff-Level Actions** (Shared by Admins & Moderators):
  - Resolving community reports.
  - Suspending/Unsuspending users.
  - Muting/Unmuting users.
  - Disbanding lounges or forcing them to private.
  - Deleting individual messages or moments.
  - Searching users and viewing moderation history.
- **Admin-Only Actions**:
  - Promoting/Demoting users to Admin or Moderator.
  - Viewing sensitive platform-wide statistics.
  - Running data archival and system maintenance tasks.

### 3. Staff-Enforced Locking
- **`isStaffLocked` Field**: Added to the `Group` model to track if a lounge's privacy has been set by staff (Admins or Moderators).
- **Backend Enforcement**: The `updateGroup` endpoint now checks this flag. If a lounge is locked, non-staff users are strictly prevented from making it public again.
- **Staff Overrides**: Staff can use the `AdminEndpoint` to force a lounge private, which automatically sets the lock flag.

### 4. Immersive Moderation UI
- **Gavel Menu**: Staff now see a distinctive 'Gavel' icon in Lounge Chats, Lounge Profiles, and User Profiles (Three-dot menu).
- **Staff Actions**:
    - **Force Private**: Instantly hides the lounge and locks its visibility.
    - **Disband Lounge**: Permanently deletes the lounge.
    - **Mute User**: Temporarily restricts a user's ability to chat.
    - **Suspend User**: Permanently disables an account (PERMANENT action).
    - **Delete Message**: Directly removes inappropriate content from the chat UI.
- **Visual Feedback**: In the "Edit Lounge" dialog, the visibility toggle is disabled for locked lounges.

### 5. Admin CLI Utility (`admin_bootstrap.dart`)
Updated with staff management commands:
- `promote <username>`: Make a user an Admin.
- `demote <username>`: Remove Admin status.
- `promote-mod <username>`: Make a user a Moderator.
- `demote-mod <username>`: Remove Moderator status.
- `privatize <groupId>`: Force a lounge to private/locked via CLI.
- `list-users`: Show all users with their roles (e.g., `[ADMIN]`, `[MODERATOR]`, or `[USER]`).

---

## 🚀 How to Test

### In the Flutter App
1.  **Staff View**: Sign in as an Admin or Moderator.
2.  **Lounge Moderation**: Go to any Lounge. Use the Gavel icon to "Force Private" or "Disband".
3.  **User Moderation**: Go to a User Profile. Use the menu to "Mute" (choose duration) or "Suspend" (requires typing 'SUSPEND').
4.  **Content Moderation**: Long-press any message in Plaza or a Group to see the "Delete Message (Staff)" option.

### Via terminal (Admin Utility)
```bash
# List users and their roles
dart bin/admin_bootstrap.dart list-users

# Promote a new moderator
dart bin/admin_bootstrap.dart promote-mod <username>

# Check lounge status
dart bin/admin_bootstrap.dart list-groups
```

---

## 📄 Documentation Updates
Updated relevant logic in:
- `AdminEndpoint` (Staff logic & Role management)
- `ResidentService` (Protocol mapping)
- `EndpointAuthMixin` (Staff auth checks)
- `UserProfileViewScreen` (Mute/Suspend UI)
- `MessageBubble` (Delete UI)
- `GroupChatScreen` & `GroupProfileScreen` (Lounge moderation UI)
