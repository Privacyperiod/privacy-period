# Alpha testing

This is how to get Privacy Period onto test devices for an alpha. The alpha ships
the **Demo** build configuration, which reveals the gated clinical modules (and the
"Load sample data" tool) for testing and clinician review — the App Store `Release`
build keeps them gated until each is signed off.

## Recommended: TestFlight (internal testers)

Over-the-air, no cable, push new builds anytime, and the clinician can install from an
email invite. Internal testers skip App Review, so builds are available minutes after
processing. Needs a paid Apple Developer Program membership.

### One-time setup

1. **Signing team.** Your Apple Developer **Team ID** is injected from the
   `PRIVACYPERIOD_TEAM` environment variable at generate time, so it never lands in the
   repo. Set it once in your shell profile (e.g. `~/.zshrc`):
   ```sh
   export PRIVACYPERIOD_TEAM=XXXXXXXXXX   # 10-char Team ID (developer.apple.com → Membership)
   ```
   then, from `iosApp/`, run `xcodegen generate && pod install`. Without it (CI, fresh
   clones) the project still builds for the simulator; device builds and TestFlight
   need it. Find your Team ID at developer.apple.com → Membership details.
   - You must register at least one device first (connect an iPhone, or
     developer.apple.com → Devices), or automatic signing reports "no devices".
2. **App Store Connect record.** Create a new app: bundle id `org.privacyperiod.app`,
   name "Privacy Period", primary language English.
3. Export-compliance and the version are already handled in `project.yml`
   (`ITSAppUsesNonExemptEncryption = false`; version single-sourced from
   `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`).

### Each build

```sh
cd iosApp
xcodegen generate && pod install        # only after changing project.yml / deps
```

1. In Xcode, select the **"PrivacyPeriod (Demo)"** scheme and **Any iOS Device** as
   the destination.
2. **Product → Archive**.
3. In the Organizer, **Distribute App → TestFlight (Internal Testing Only)** → upload.
4. In App Store Connect → TestFlight, once the build finishes processing, add the two
   testers to an **Internal Testing** group (they must be Users on your team).

For every subsequent upload, bump the build number: increment
`CURRENT_PROJECT_VERSION` in `iosApp/project.yml`, then `xcodegen generate`.

### Tester quick-start

1. Install **TestFlight** from the App Store and accept the email invite (or open the
   invite link on the device).
2. Install Privacy Period from TestFlight.
3. It opens onto the mood & energy check-in (skippable with "Not today").
4. **Settings (gear, top-right) → Load sample data** seeds two cycles so the home
   tracker and the Premenstrual pattern are populated to explore.
5. **Choose conditions to track** turns modules on/off; the home surfaces what's on.

## Fast path: install directly from Xcode

Both phones with you and you just want it on them now: plug each phone in, select it as
the destination with the **"PrivacyPeriod (Demo)"** scheme, and **Run**. With a paid
account the device registers automatically and the app lasts ~1 year. No App Store
Connect record needed — but updates require re-cabling, so TestFlight is the better
home for an ongoing alpha.

## Notes

- The alpha is the **Demo** build: all clinical modules are visible for testing. None
  is clinically signed off; the App Store `Release` build keeps them gated.
- "Load sample data" only exists in Demo builds, never in `Release`.
