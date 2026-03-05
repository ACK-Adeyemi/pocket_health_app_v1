# ADR 006: API Key Security and Exposure Mitigation

## Status
Accepted

## Context
Google identified a publicly accessible API key in the `docs/main.dart.js` file. This occurred because the Flutter web build artifacts (including the compiled JavaScript containing Firebase configuration) were being committed to the repository in the `docs/` directory for hosting purposes (e.g., GitHub Pages). 

While Firebase API keys are technically public by design (required for client-side authentication), they should never be left unrestricted. Unrestricted keys can be used by third parties, leading to quota exhaustion, service disruption, or unauthorized access if backend security rules (Firestore/Storage) are weak.

## Decision
We are implementing a multi-layered mitigation strategy:

1.  **Repository Hygiene**: Modified `.gitignore` to exclude compiled web artifacts (`.js`, `.wasm`, `.html`, `.json`) and the `assets/` directory from the `docs/` folder. This prevents sensitive configuration from being committed to version control in a compiled format that is easily scanned.
2.  **In-Code Documentation**: Added a security warning and instructions to `lib/firebase_options.dart` to ensure any developer working on the project is aware that GCP restrictions (referrers/package names) are mandatory.
3.  **Infrastructure Security**: 
    *   **HTTP Referrer Restrictions**: Lock the Web API key to the specific domain(s) where the app is hosted (e.g., `pocket-health-001.firebaseapp.com/*`).
    *   **API Restrictions**: Limit the API key to only the specific services required (Firestore, Auth, Storage, etc.) in the Google Cloud Console.
    *   **App Check**: (Future Consideration) Implement Firebase App Check to further verify that requests are coming from the genuine app.

## Consequences
*   **Easier**: Prevents automated scanners from flagging "exposed" keys in the repository. Ensures new developers understand the security model immediately.
*   **More Difficult**: Developers must remember to update GCP restrictions when changing hosting domains. The `docs/` folder can no longer be used as a "dumb" dump for builds if those builds contain secrets; a proper CI/CD pipeline for deployment is preferred.

## Alternatives Considered
*   **Using Environment Variables/Dotenv**: While common in server-side apps, Flutter Web compiles these into the JS bundle anyway, so it doesn't solve the "exposure" in the final build. GCP restrictions are the industry-standard solution for this specific platform.
*   **Rotating Keys**: Recommended if the key was used for a non-public service, but since this key is *meant* to be in the client, rotation is only necessary if restriction is not possible (not the case here).

## Notes
*   Refer to the [Firebase Security Guidelines](https://firebase.google.com/docs/projects/api-keys) for more information on how API keys work.
