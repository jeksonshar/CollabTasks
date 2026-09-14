# Feature: BiometricLock

## 1. Business Goal & Value
- **Purpose:** Protect application privacy and data security via local biometric authentication (fingerprint/face unlock) and inactivity timeout, with an opaque privacy veil during app switcher usage.
- **User Stories Covered:**
  - Automatic app locking after `kInactivityTimeout` of foreground inactivity.
  - Automatic app locking when resuming from background if elapsed time exceeds `kInactivityTimeout`.
  - Privacy screen veil displayed in task switcher when the app is backgrounded.
  - Global overlay via `MaterialApp.builder` ensuring lock and privacy screens cover all routes, including pushed subroutes and chat screens.
  - Keyboard dismissal upon lock overlay presentation.
  - Option to re-authenticate or log out to return to password authentication.

## 2. Architectural Blueprint (Clean Architecture)

### Domain Layer
- **Models / Types:**
  - `LockStatus` (idle, locked, authenticating, privacyScreen, requiresLogout)
  - `LockErrorType`
- **Services / Contracts:**
  - `IBiometricService`: local authentication abstraction

### Data Layer
- **Persistence:**
  - `SharedPreferences` for storing `isBiometricEnabled`.
- **Services:**
  - `BiometricService`: wraps `package:local_auth` with `sensitiveTransaction: false` allowing biometrics (face + fingerprint).

### Presentation Layer (UI & Bloc)
- **Bloc:** `LockBloc`
  - **Events:**
    - `LockCheckRequested`
    - `LockAppPaused`
    - `LockAppResumed`
    - `LockUserInteractionOccurred`
    - `LockAuthenticateRequested`
    - `LockSignInWithPasswordRequested`
    - `LockBiometricToggled`
    - `LockBiometricOfferResponded`
    - `LockAuthStatusChanged`
  - **States:** `LockState` (status, isBiometricEnabled, isBiometricAvailable, authenticationFailed)
- **Components & Screens:**
  - `MaterialApp.builder`: Host for the global `Stack` overlay containing `PrivacyScreenWidget` and `LockScreenWidget` on top of the root `Navigator`.
  - `LockScreenWidget`: Full-screen overlay dismissing focus and prompting for biometric authentication or password sign-in.
  - `PrivacyScreenWidget`: Opaque brand cover shown during app backgrounding / task switching.

## 3. Testing Matrix
- [x] **Unit / Bloc:** `test/features/auth/ui/lock_bloc/lock_bloc_test.dart`
- [x] **Widget:** `test/features/auth/ui/lock_screen/lock_screen_overlay_test.dart`

## 4. Data Flow & State Machine (Mermaid)
```mermaid
graph TD
    AppLifecycle[AppLifecycle / UserInteraction / Timer] -->|Dispatch Event| LockBloc[LockBloc]
    LockBloc -->|Biometric Authenticate| BioService[BiometricService]
    BioService -->|Result| LockBloc
    LockBloc -->|Emit LockState| GlobalBuilder[MaterialApp.builder Stack]
    GlobalBuilder -->|locked / authenticating| LockScreen[LockScreenWidget (Overlays Root Navigator)]
    GlobalBuilder -->|privacyScreen| PrivacyScreen[PrivacyScreenWidget (Overlays Root Navigator)]
    GlobalBuilder -->|idle| AppContent[Root Navigator / Pushed Subroutes]
```
