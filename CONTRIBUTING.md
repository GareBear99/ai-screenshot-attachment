# Contributing

Thanks for contributing.

## Scope

This repository focuses on lightweight macOS screenshot capture for browser and AI-agent workflows.

## Before opening a PR

- Keep the utility small and dependency-light.
- Prefer native macOS capabilities where possible.
- Document new flags in the README.
- Explain any behavior change that affects automation or output parsing.

## Development notes

- Preserve the last stdout line as the final screenshot path unless the contract is intentionally changed.
- Avoid introducing network dependencies for core functionality.
- Prefer explicit errors over silent fallback behavior.

## Pull request checklist

- [ ] Updated docs
- [ ] Updated usage examples if flags changed
- [ ] Kept output behavior stable or documented the change
- [ ] Tested on macOS with a real browser target
