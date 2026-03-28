# Test Coverage & TDD Strategy: Talktive Serverpod Migration

To ensure the stability of the **Talktive** platform as we approach deployment, we are implementing a comprehensive testing strategy. This includes increasing coverage for critical backend services and frontend components, and adopting a **Test-Driven Development (TDD)** approach for all future features.

## 1. Testing Tiers

### A. Backend (talktive_server)
Focus on business logic, security, and data integrity.

1.  **Unit Tests (`test/unit/services/`)**:
    *   **Scope**: Pure logic in Service classes (e.g., `InputValidationService`, `GamificationService` math).
    *   **Goal**: Ensure individual components behave correctly in isolation.
    *   **Mocking**: Use `mockito` or simplified mocks to isolate logic from external systems (FCM, Redis, Database).
2.  **Integration Tests (`test/integration/`)**:
    *   **Scope**: Endpoint logic and full service flows.
    *   **Goal**: Verify that endpoints correctly interact with the database, caching, and background tasks.
    *   **Mechanism**: Use `withServerpod` for access to a real session and a transaction-isolated database.

### B. Frontend (talktive_flutter)
Focus on user experience, state management, and UI consistency.

1.  **Unit & Provider Tests (`test/providers/`)**:
    *   **Scope**: `AuthProvider`, `ResidentProvider`, `GamificationProvider`.
    *   **Goal**: Verify that state changes correctly in response to API results or user actions.
2.  **Widget Tests (`test/widgets/duo/`)**:
    *   **Scope**: Reusable components (`DuoButton`, `DuoCard`, `DuoAvatar`).
    *   **Goal**: Ensure UI remains consistent across code changes (Goldens + Interaction tests).
3.  **Integration Tests (`integration_test/`)**:
    *   **Scope**: Critical user journeys (Login -> Setup -> High Floor -> Post to Plaza).
    *   **Goal**: End-to-end verification of the user experience.

---

## 2. Priority Coverage: Critical Features

| Feature | Tested Layer | Key Scenarios to Cover |
| :--- | :--- | :--- |
| **Messaging** | Backend Service | Floor restrictions, media validation, blockage checks, denormalized updates. |
| **Gamification** | Backend Service | XP accumulation, level-up logic, daily streak calculation, badge awarding. |
| **Authentication** | Backend/Flutter | Token exchange, session persistence, version selection workflow. |
| **Privacy Rules** | Backend Service | Blocked user interaction, private chat visibility, content ephemerality. |
| **Reputation** | Backend Service | Mute/Unmute logic, reputation tier transitions, effective floor formula. |

---

## 3. TDD Workflow: Step-by-Step

Going forward, we will adopt the following **Red-Green-Refactor** workflow for every new task:

1.  **RED**: Write a failing test case that defines the expected behavior of the new feature or fix.
    *   *Example*: A test verifying that a message cannot be pinned by a regular user in the Plaza.
2.  **GREEN**: Write the *minimal amount of code* required to pass the test.
    *   *Example*: Implement the permission check in `MessagingService.pinMessage`.
3.  **REFACTOR**: Clean up the code, optimize performance, and ensure it follows the project's design system and architectural patterns.
    *   *Example*: Extract common permission logic into a helper method.

---

## 4. Implementation Timeline (Phase 8.24)

### Step 1: Backend Baseline (Current Session)
- [ ] Create `test/unit/services/messaging_service_test.dart`.
- [ ] Create `test/unit/services/gamification_service_test.dart`.
- [ ] Add integration tests for `MessageEndpoint` and `LoungeEndpoint`.

### Step 2: Frontend Baseline
- [ ] Create `test/widgets/duo/duo_components_test.dart`.
- [ ] Implement `AuthProvider` unit tests.

### Step 3: CI/CD Integration
- [ ] Configure `dart test` and `flutter test` to run on every commit (pre-deploy check).

---

> [!IMPORTANT]
> **TDD is a Mindset**: By writing tests first, we document the requirements and ensure that our code is "testable" by design, leading to lower coupling and higher maintainability.

> [!TIP]
> Use `dart test --coverage` and tools like `lcov` to visualize which parts of the codebase still lack protection.
