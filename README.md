# CampusFix — Campus Incident Reporting App

A Flutter app for ALU students to report campus issues (water, electricity,
facilities, furniture, sanitation, safety) and follow them until they are
resolved. Authorised staff review reports and update their status.

**Stack:** Flutter · Provider · Firebase Authentication · Cloud Firestore · Cloudflare Workers KV (photos, via a Worker)

## Features

- **Auth:** register / sign in / sign out with ALU email only
  (`@alustudent.com`), mandatory email verification, password reset.
- **Report an issue:** category tiles, title, description, campus location picker,
  optional photo (camera or gallery, compressed on device) with live upload progress.
- **Browse:** live campus feed, search (title / place / reference), status tabs,
  filter sheet (status, category, only mine, sort).
- **Details:** photo, description, status timeline with staff messages.
- **Edit / delete** own reports while still *Submitted*.
- **Staff:** dashboard with campus-wide counts and the new-report queue, update status
  (Submitted → In progress → Resolved / Rejected) with a message to the student.
- **Notifications:** in-app notification feed with unread badge, created on submit and
  on every status change.

## Architecture

```
lib/
  core/         theme tokens, constants (categories, statuses, locations), validators, formatters
  models/       AppUser, Incident (+ StatusChange history), AppNotification
  services/     AuthService, IncidentRepository, StorageService, NotificationRepository  ← only layer that touches Firebase
  providers/    AuthProvider, IncidentProvider, IncidentFilter, NotificationProvider, ShellProvider  ← state + business rules
  screens/      auth/, student/, reports/, staff/, notifications/, profile/, auth_gate, app_shell
  widgets/      reusable UI components (AppButton, AppTextField, CategoryTile, ReportCard, StatusPill, TimelineStep, …)
```

UI → Provider (ChangeNotifier) → Repository/Service → Firebase. Screens never call
Firebase directly. `IncidentProvider` holds one live Firestore stream, so a status change
made by staff updates the home stats, list, details and dashboard at the same time.

### Firestore data model

| Collection | Fields |
|---|---|
| `users/{uid}` | `name`, `email`, `role` (`student` \| `staff`), `department?`, `createdAt` |
| `incidents/{id}` | `reference`, `title`, `description`, `category`, `location`, `status`, `reporterId`, `reporterName`, `photoUrl?`, `photoPath?`, `history[] {status, at, byName, note?}`, `createdAt`, `updatedAt` |
| `staffInvites/{email}` | `department?` (admin-only, doc ID is the lower-case email) |
| `notifications/{id}` | `userId`, `incidentId`, `title`, `body`, `status`, `read`, `createdAt` |

Photos are stored in Cloudflare Workers KV at `incidents/{uid}/{incidentId}_{timestamp}.jpg`,
behind the Worker in [`cloudflare/photo-worker.js`](cloudflare/photo-worker.js). Firebase Storage
now requires the paid Blaze plan, so photos use Cloudflare's free tier instead.

### Access control

Enforced server-side in [`firestore.rules`](firestore.rules) and the photo Worker:

- Every read/write requires a signed-in, **email-verified** account with an **ALU email**
  (`@alustudent.com`, `@alueducation.com`), or an admin-created **staff** account (see below).
- Self-registration creates `role: "student"`, or `"staff"` only for an email an admin listed in
  `staffInvites`; nobody can change their own role.
- Students can edit/delete only **their own** reports and only while `status == "submitted"`.
- Only `staff` can change `status`/`history`, and must append exactly one timeline entry.
- Students only read their own notifications; only staff can notify other users.
- Photos: the Worker verifies the Firebase ID token (signature, project, expiry, verified
  email); users upload or delete only inside their own `incidents/{uid}/` folder; images only, max 5 MB.

## Setup

1. Create a Firebase project at https://console.firebase.google.com, then enable
   **Authentication → Email/Password** and **Firestore Database**.
2. Add an Android app with package name `com.alu.campus_fix`, download
   `google-services.json` and place it at `android/app/google-services.json`.
3. Paste [`firestore.rules`](firestore.rules) into **Firestore → Rules**, then Publish.
4. Photos (Cloudflare dashboard): create a KV namespace, create a Worker from
   [`cloudflare/photo-worker.js`](cloudflare/photo-worker.js), bind the namespace as `PHOTOS`, add the
   variable `FIREBASE_PROJECT_ID`, and put the Worker URL in `photoApiUrl` in
   [`lib/core/constants.dart`](lib/core/constants.dart).
5. Run on an Android device or emulator: `flutter run`

### Creating a staff account

Students self-register with their ALU email. Staff (who may use any email, e.g. Gmail) sign up
in the app too, but only after an admin invites them:

1. **Firebase Console → Firestore → Start collection `staffInvites`** (first time only), then
   **Add document** with the staff member's email **in lower case as the document ID**
   (e.g. `jane.doe@gmail.com`). Optionally add a `department` (string) field.
2. The staff member opens the app, taps **Create account**, and signs up with that exact email.
   The app finds the invite and creates their profile with `role: "staff"`.
3. They open the verification link in their inbox and tap **I've verified** → staff dashboard.

Alternatively, an existing student account can be promoted by changing `role` to `staff` in
**Firestore → users → {uid}**.

The Firestore rules only accept `role: "staff"` on sign-up when `staffInvites/{email}` exists,
and the app has no way to write invites. Deleting an invite stops new sign-ups with that email
but doesn't demote an existing account; to do that, change its `role` back in `users/{uid}`.
A non-ALU email that isn't invited can't sign up and is signed straight back out.

## Tests

```
flutter test                           # 22 unit and widget tests
node cloudflare/photo-worker.test.mjs  # 13 security checks for the photo Worker
```

Unit tests cover validation rules, the search/filter/sort logic, and date formatting;
widget tests cover form validation on the category picker and the report card.
