# BinaryBuddy Development Log

Generated: 2026-05-25
Workspace: `/Users/hero1356/Developer/binary-buddy-ios`
Repository: `git@github.com:hero1356-kor/binary-buddy-ios.git`
Branch: `main`

This file is intended as project memory for future ChatGPT/Codex sessions.
It records the actual working style, decisions, verification commands, commits,
and current assumptions from the development session.

Private credentials are intentionally not stored here. The SSH private key is not
part of this file and must never be committed.

## User Communication Preferences

- Use 존대.
- Do not use 반말.
- Be direct and practical.
- Explain what is being changed and why, but keep the final answer concise.
- For UI work, keep checking iPhone 11 layout.
- When the user asks for implementation, implement directly instead of only proposing.
- Commit when the user asks.
- Push when the user asks.

## Local Environment

- macOS: 26.5
- Xcode: 26.5
- iPhone simulator target used repeatedly: iPhone 11
- Simulator UDID used in commands: `F8CA8814-F3FB-43CD-85DD-3148EA703085`
- Bundle identifier observed: `com.hero1356.BinaryBuddy`
- Derived data path used: `/tmp/BinaryBuddyDerivedData`

## Git State After Push

After SSH setup, `main` was pushed successfully to GitHub.

Latest commits:

```text
493c84a Refine calculator keypad layout
72d6999 Add keypad arithmetic and app icon assets
58ac000 Update tests for multi-base programmer behavior
c1ca3fc Redesign UI for calculator-style multi-base input
93cb0a6 Update programmer calculator engine for multi-base input
df45fbf Refine calculator view compatibility
4c2ccf1 Add initial programmer calculator tests
6e82611 Add SwiftUI programmer calculator view
```

Remote was changed from HTTPS to SSH:

```text
origin git@github.com:hero1356-kor/binary-buddy-ios.git
```

Push result:

```text
To github.com:hero1356-kor/binary-buddy-ios.git
   58ac000..493c84a  main -> main
```

## SSH Setup Record

Reason: HTTPS push failed because GitHub credentials were not configured in this environment.

Failure:

```text
fatal: could not read Username for 'https://github.com': Device not configured
```

SSH check after key registration:

```text
Hi hero1356-kor! You've successfully authenticated, but GitHub does not provide shell access.
```

Meaning explained to user:

- SSH = Secure Shell.
- In this project, SSH is used as a secure key-based authentication method for GitHub push.
- The Mac has the private key.
- GitHub stores the public key.
- GitHub allows push when the request proves it came from the matching private key.

## Product Direction

BinaryBuddy is an iOS programmer calculator. The user wants it to solve the lack of a built-in iPhone programmer calculator similar to Windows Calculator programmer mode.

Main target:

- DEC / HEX / BIN conversion
- 8 / 16 / 32 / 64 bit width
- Bit view with tappable bits
- Calculator-style keypad
- Real arithmetic operations
- iPhone 11 one-screen usability
- Orange and black visual direction

## Major UI Decisions

The app moved toward a compact calculator-style UI.

Current layout direction:

- Black background.
- Card-like sections with dark surfaces.
- Header still shows `Programmer Calculator`.
- Bit width label changed from `BIT WIDTH` to `Bit width`.
- `BIT VIEW (...)` label removed.
- `DEC KEYPAD` / base keypad label removed.
- Removing labels allowed bit cells and keypad buttons to be enlarged.
- iPhone 11 screenshot verification was used after major layout changes.

## Input Rows

Rows shown:

- DEC
- HEX
- BIN

OCT was removed.

Decision:

- Keep DEC / HEX / BIN only.
- Remove OCT from UI and later from core model/results/tests.
- User reason: keypad and arithmetic needed space; OCT was less important.

Input row interaction:

- Whole row should be tappable/selectable.
- Active base is indicated with an orange circular marker on the left.
- DEC and HEX marker was moved to the left earlier.

Initial values:

```text
DEC 0
HEX 0x0000
BIN 0b0000_0000_0000_0000
```

Reason:

- User did not want to press AC immediately after app launch.

## Bit Width And Bit View

Bit width modes:

```text
8, 16, 32, 64
```

Current default:

```text
16
```

Bit view behavior:

- Shows at least 32 cells.
- When bit width is 8 or 16, disabled prefix bits are visually dim.
- Enabled bits are tappable.
- Tapping enabled bits toggles 0/1 and syncs DEC/HEX/BIN.
- Disabled prefix bits cannot be toggled.

Decision:

- Keep the bit view.
- User said BIT VIEW is very good.
- Make disabled MSB area clear when the selected width is smaller than visible cells.

## Keypad Decisions

The app no longer uses the iPhone system keyboard for numeric input. It uses an in-app keypad.

Reason:

- User wanted calculator-like AC and keypad controls.
- iPhone keyboard was not ideal for this calculator.

Keypad shape decision:

- DEC, HEX, BIN should keep the same keypad shape.
- Keys that are invalid for the current base should be visually disabled and functionally disabled.
- This avoids the confusing experience of keys moving around between bases.

Current keypad grid:

```text
+   -   x   /
7   8   9   =
4   5   6   AC
1   2   3   0
A   B   C   D
E   F   backspace   empty
```

Actual symbols in UI:

```text
+ - × ÷ =
```

The `=` key was moved from the top operation row to the key above `AC`.

Reason:

- Top row had 5 keys while rows below had 4 keys.
- Alignment looked wrong.

Backspace was moved to the lower row and uses a backspace icon-like symbol.

AC color:

- AC should not be red.
- AC should visually match backspace.

Disabled keypad behavior:

- DEC: digits 0-9 enabled, A-F disabled.
- HEX: digits 0-9 and A-F enabled.
- BIN: only 0 and 1 enabled.
- `=` disabled until an operation is pending.
- AC and backspace enabled.

## Arithmetic Decisions

Operations added:

```text
add
subtract
multiply
divide
equals
```

Core enum:

```swift
public enum ProgrammerArithmeticOperator {
    case add
    case subtract
    case multiply
    case divide
}
```

Arithmetic behavior:

- Uses selected bit width.
- Addition uses wrapping behavior then masks to selected width.
- Subtraction uses wrapping behavior then masks to selected width.
- Multiplication uses wrapping behavior then masks to selected width.
- Division by zero throws an error.

Division by zero error:

```text
Cannot divide by zero.
```

Pending-operation behavior:

- Tap operator after entering first operand.
- Next numeric input starts a new operand.
- `=` evaluates pending operation.
- AC clears pending operation.
- Toggling a bit resets pending operation.

## App Icon Work

The user wanted an app icon because the default icon looked like a white background with a slash.

Visual direction:

- Orange and black.
- Avoid green.
- Avoid gradient background.
- More calculator-like, less pure chip-like.
- Try simple calculator icon.
- Remove numbers from the icon.
- Add one or two orange buttons.
- Eventually test all orange buttons.

Committed assets:

- `BinaryBuddy/Assets.xcassets/AppIcon.appiconset/`
- `IconCandidates/`

Note:

- `IconCandidates/` is about 34MB.
- It was committed because the user asked to commit "everything worked on so far".

## Verification Commands Used

Build/test command used repeatedly:

```sh
xcodebuild test -project BinaryBuddy.xcodeproj -scheme BinaryBuddy -destination 'id=F8CA8814-F3FB-43CD-85DD-3148EA703085' -derivedDataPath /tmp/BinaryBuddyDerivedData
```

Build-only command used earlier:

```sh
xcodebuild build -project BinaryBuddy.xcodeproj -scheme BinaryBuddy -destination 'id=F8CA8814-F3FB-43CD-85DD-3148EA703085' -derivedDataPath /tmp/BinaryBuddyDerivedData
```

Simulator install/launch/screenshot command pattern:

```sh
xcrun simctl boot F8CA8814-F3FB-43CD-85DD-3148EA703085 || true
xcrun simctl bootstatus F8CA8814-F3FB-43CD-85DD-3148EA703085 -b
xcrun simctl install F8CA8814-F3FB-43CD-85DD-3148EA703085 /tmp/BinaryBuddyDerivedData/Build/Products/Debug-iphonesimulator/BinaryBuddy.app
xcrun simctl launch F8CA8814-F3FB-43CD-85DD-3148EA703085 com.hero1356.BinaryBuddy
xcrun simctl io F8CA8814-F3FB-43CD-85DD-3148EA703085 screenshot /tmp/binarybuddy-screenshot.png
```

Repeated successful result:

```text
** TEST SUCCEEDED **
```

Test cases observed after arithmetic work:

```text
ProgrammerCalculatorTests.testAdditionWrapsToSelectedWidth()
ProgrammerCalculatorTests.testBinaryPrefixInput()
ProgrammerCalculatorTests.testDecimalToHexAndBinary()
ProgrammerCalculatorTests.testDivisionByZeroThrows()
ProgrammerCalculatorTests.testHexPrefixInput()
ProgrammerCalculatorTests.testNegativeDecimalInputUsesBitPattern()
ProgrammerCalculatorTests.testSubtractionWrapsToSelectedWidth()
ProgrammerCalculatorTests.testValueIsMaskedToSelectedWidth()
```

## Important Files

Core:

```text
BinaryBuddy/Core/NumberBase.swift
BinaryBuddy/Core/BitWidth.swift
BinaryBuddy/Core/ProgrammerCalculator.swift
BinaryBuddy/Core/ProgrammerCalculatorResult.swift
```

UI:

```text
BinaryBuddy/Features/ProgrammerCalculator/ProgrammerCalculatorView.swift
```

Tests:

```text
BinaryBuddyTests/ProgrammerCalculatorTests.swift
```

Project:

```text
BinaryBuddy.xcodeproj/project.pbxproj
```

Assets:

```text
BinaryBuddy/Assets.xcassets/
IconCandidates/
```

## Current Practical Workflow

For UI changes:

1. Inspect `ProgrammerCalculatorView.swift`.
2. Make scoped SwiftUI layout changes.
3. Run `xcodebuild test`.
4. Install and launch on iPhone 11 simulator.
5. Capture screenshot.
6. Review for one-screen fit and overlaps.
7. Commit when user approves.
8. Push when user asks.

For core calculation changes:

1. Update `ProgrammerCalculator.swift`.
2. Update `ProgrammerCalculatorTests.swift`.
3. Run `xcodebuild test`.
4. Only then report success.

## User Guidance Already Given

Simulator/device performance:

- Simulator can be slow, especially on low-RAM MacBooks.
- Debug mode through Xcode can be slower than normal app launch.
- For real performance on iPhone, install on device, stop Xcode debugging, disconnect if needed, then launch the app normally.

Developer certificate trust:

- On iPhone, trust developer app certificate through Settings.
- Korean path explained earlier:
  General / VPN & Device Management / Developer App certificate / Trust.

Git concepts:

- Commit = save the current work into local Git history on the Mac.
- Push = upload local commits to GitHub.
- Before push, phone GitHub view does not show latest local commits.
- After push, GitHub website and phone can see the latest code.

## Known Current State

As of this file creation:

- `main` was clean and synced to `origin/main` before adding this file.
- The app had latest UI/layout changes committed and pushed.
- This file itself must be committed and pushed after creation.

