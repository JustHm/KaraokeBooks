# KaraokeBooks Agent Guide

## Product and architecture

- KaraokeBooks is a UIKit, code-only iOS app that searches TJ/KY karaoke songs, shows rankings, and stores favourites locally.
- The presentation layer uses ReactorKit + RxSwift. Keep view binding declarative: views emit `Action`, reactors mutate `State`, and side effects belong in services or reactors.
- UI uses UIKit and SnapKit. Do not introduce Storyboards or SwiftUI into an existing screen without an agreed migration scope.
- Local favourites are Core Data. Treat the current persisted model as production data: discuss migration and duplicate handling before changing entities, attributes, or constraints.

## Source conventions

- Preserve the existing file header in every source file. New Swift files must begin with the project header, use the `KaraokeBooks` target, and use the creation date in `YYYY/MM/DD` form.
- Keep Korean user-facing strings natural and consistent with the surrounding screen.
- Prefer `URLComponents` and `URLQueryItem` for all URLs derived from user input.
- Avoid editing generated Xcode user data, `xcuserdata`, and `*.xcuserstate`.

## UI and iOS 26

- Test UI changes on the currently supported iOS Simulator before considering the work complete.
- Do not directly change a presented controller's `view.frame` to implement a sheet. Configure `UISheetPresentationController` detents and sheet properties instead.
- Keep search controls in the content area when UIKit navigation search behavior differs across iOS versions.
- Verify custom segmented controls after the first layout pass as well as after a selection change.

## Verification harness

Run the repository harness before handoff:

```sh
./scripts/verify.sh lint
./scripts/verify.sh build
./scripts/verify.sh test
```

`test` requires a booted iOS Simulator. To select one explicitly, set `DESTINATION`, for example:

```sh
DESTINATION='platform=iOS Simulator,name=iPhone 17,OS=26.2' ./scripts/verify.sh test
```

Do not report a simulator-service or package-resolution outage as an application failure; report it as an environment blocker with the command output.

## Git safety

- Inspect `git status --short` before editing and preserve unrelated changes.
- Never commit, push, reset, or remove tracked files unless the user explicitly asks.
- Never add secrets, provisioning profiles, SSH keys, `xcuserdata`, or DerivedData to Git.
