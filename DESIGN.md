# Task 1 Kotlin Stub Emission Design

## Summary

For Task 1, I added a new `--emit kotlin-jvm` option instead of trying to force Kotlin through the existing Java runtime mode switch.

The Kotlin path reuses the normal Swift analysis step, then writes one top-level Kotlin file with stub functions for the small subset the task asks for.

## How to Run

To run just the Kotlin Task 1 tests:

```bash
swift test --disable-experimental-prebuilts --filter Kotlin
```

## Corners Cut

- Only top-level functions are emitted.
- Only these types are accepted: `Int`, `Int32`, `Bool`, `Double`, `String`, `Void`.
- If a declaration falls outside that subset, it is skipped and noted in comments instead of being half-translated.
- Kotlin output still goes through `--output-java`. I did not add a separate `--output-kotlin` flag yet.
- `--output-swift` is still part of the command line shape even though this path does not use it.
- Generated Kotlin bodies are just `TODO("Not implemented")`.
- This does not try to hook Kotlin up to FFM or JNI yet.

## Better Shape Later

If this grows past Task 1, the cleaner split is:

- `--emit` decides whether we are generating Java or Kotlin
- `--mode` stays about the backend for Java generation
- Kotlin gets its own output root instead of borrowing `--output-java`

It would also be better to share more lifted JVM-side API information between the Java and Kotlin paths instead of having the Kotlin stub generator stay so narrow.

## Next Steps

- Add `--output-kotlin`
- Add a small compile check for generated Kotlin
- Carry more function information through the stub path, especially `async`, `throws`, and better diagnostics around unsupported declarations
- For Task 2, replace stub bodies with calls into a runtime layer instead of changing the top-level Kotlin API again
