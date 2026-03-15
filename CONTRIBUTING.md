# Contributing

Thanks for your interest in contributing to Clingfy.

## Before you start

- For larger changes, open an issue or start a discussion before investing in implementation work.
- Do not include secrets, local environment files, signing assets, or generated release artifacts in commits or pull requests.
- Keep changes scoped and easy to review.

## Local setup

```bash
flutter pub get
flutter analyze
flutter test
```

For macOS-specific work, use the flavor-aware build commands:

```bash
flutter build macos --flavor dev
flutter build macos --flavor prod
```

Additional development notes are available in [docs/development.md](docs/development.md).

## Pull request expectations

- Keep behavior-preserving refactors separate from feature work when possible.
- Add or update tests when behavior changes.
- Run `flutter analyze` and `flutter test` before opening a PR.
- If your change touches native macOS code or release tooling, also run the relevant macOS build or explain why you could not.

## Coding and review expectations

- Follow the existing project structure and boundary intent:
  - `lib/core` for reusable recorder/domain logic
  - `lib/app` for the product shell and workflow
  - `lib/commercial` for client-side licensing and monetization
  - `lib/ui` for shared UI primitives
- Avoid introducing secrets or environment-specific values into tracked files.
- Prefer focused, low-risk changes over broad rewrites.

## Contribution licensing

By submitting a contribution to this repository, you agree that your contribution will be licensed under the repository's GPL-3.0-or-later terms.
