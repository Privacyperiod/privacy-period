# Security Policy

Privacy Period handles sensitive personal health data. We take security and
privacy seriously and welcome responsible disclosure.

## Reporting a vulnerability

**Please do not open a public issue for security vulnerabilities.**

Report privately through either:

- **GitHub private vulnerability reporting** — on this repository, go to the
  **Security** tab → **Report a vulnerability** (preferred), or
- **Email** — joe@privacy-period.org

Please include enough detail to reproduce: affected version/commit, steps,
impact, and any proof-of-concept. If the report concerns encryption or key
handling, please flag it as high severity.

## Our commitment

- We will **acknowledge your report within 72 hours**.
- We will investigate, keep you updated, and communicate a remediation timeline.
- We will credit you for the discovery if you wish (and only if you wish).
- We ask that you give us a reasonable opportunity to patch before any public
  disclosure (coordinated disclosure).

## Scope

Security-relevant areas include, but are not limited to:

- Encryption and key storage (AES-256-GCM; Keychain / Keystore handling)
- Any path where user data could leave the device unencrypted
- Local data export / backup / restore
- App lock (biometric / PIN) bypasses

## Out of scope

- Theoretical issues without a practical attack path
- Vulnerabilities requiring a physical, already-unlocked device with the app open
  (we still want to hear about these, but they are lower severity)

Thank you for helping keep Privacy Period and its users safe.
