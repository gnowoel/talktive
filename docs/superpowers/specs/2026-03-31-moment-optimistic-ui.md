# Design Spec: "Live" Moment Interactions (Optimistic UI)

## 1. Overview
Currently, liking or commenting on a Moment in Talktive feels "heavy" because the UI waits for a full network refresh to reflect the updated counts. This spec outlines the transition to a "Live First" optimistic architecture where the UI updates instantly, and state is reconciled in the background.

## 2. Goals
- **Instant Feedback**: Liking a moment or posting a comment should update the UI in < 100ms.
- **Single Source of Truth**: The Moment Detail screen should react to changes made in the Feed, and vice versa.
- **Resilience**: If a network request fails, the UI should gracefully revert to the server's state.

## 3. Architecture

### 3.1. Provider Reconciliation (Riverpod)
We will modify the `Moments` and `MomentLikes` providers in `lib/providers/moments_provider.dart`:

- **`Moments` Provider**: 
    - Add a `updateMomentLocally(int momentId, Moment Function(Moment) update)` method.
    - `toggleLike`: Instead of calling `refresh()`, it will find the moment in the current list and increment/decrement `likesCount` immediately.
- **`MomentLikes` Provider**:
    - `toggleLike`: Update the local `Set<int>` instantly.

### 3.2. Reactive Detail Screen
We will refactor `MomentDetailScreen` in `lib/screens/moments/moment_detail_screen.dart`:
- **Parameter Change**: Change from `Moment moment` to `int momentId`.
- **Observation**: Use `ref.watch(momentsProvider.select((list) => list.firstWhere((m) => m.id == momentId)))`.
- **Benefit**: Any change to the moment in the feed (like a background refresh or a like toggle) will automatically rebuild the detail screen.

### 3.3. Commenting Flow
- **`MomentComments` Provider**:
    - `addComment`: Optimistically add a "temp" comment object to the list.
    - **Reconciliation**: When the server returns the actual `MomentComment` (with its permanent ID), replace the temp object and increment the `commentsCount` on the parent `Moment` in the `Moments` provider.

## 4. User Experience
- **Haptics**: Maintain existing `HapticFeedback` for tactile confirmation.
- **Animations**: The heart icon and counts will use `flutter_animate` to feel bouncy and energetic.
- **Error Handling**: Use `DuoSnackBarHelper` to alert the user if a background sync fails, while reverting the local state.

## 5. Verification Plan
- **Manual Test**: Like a post in the feed → Open detail screen → Verify count is updated.
- **Manual Test**: Comment in detail screen → Return to feed → Verify comment count is updated on the card.
- **Network Test**: Toggle airplane mode → Try to like → Verify UI snaps back and shows error.
