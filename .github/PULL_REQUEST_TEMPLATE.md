<!--
Thanks for contributing to Privacy Period. Please complete this checklist.
Keep PRs small and focused — one logical change per PR.
-->

## Summary

<!-- What does this change do, and why? -->

## Related issue

<!-- e.g. Closes #42  (non-trivial changes should reference an issue) -->

## Checklist

- [ ] Commit messages follow Conventional Commits (`type(scope): description`)
- [ ] Public functions/classes/modules have KDoc (Kotlin) / DocC (Swift) docs
- [ ] No hardcoded user-facing strings — all strings use i18n keys
- [ ] Tests added/updated and passing locally (CI must be green)
- [ ] No new dependency, OR the dependency's license + network behavior is stated
- [ ] No analytics / ads / tracking / silent network calls introduced
- [ ] No encryption keys stored outside Keychain / Keystore; no key material logged
- [ ] No medical or diagnostic claims in any user-facing string
- [ ] New source files include the AGPL-3.0 header
- [ ] `CHANGELOG.md` updated under `[Unreleased]` if user-facing

## Privacy / security notes

<!-- Call out any privacy or security implications of this change. -->
