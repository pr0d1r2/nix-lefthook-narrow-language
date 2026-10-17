# Changelog

All notable changes to this project are documented here.

## Unreleased

- Make `add` and `compact` skip every `.narrow-language*.dic` file and honour
  `NARROW_LANGUAGE_EXCLUDE_FILES`, so one dictionary no longer feeds another and
  excluded files no longer add words.
- Restore the `check`, `compact`, `add`, `freeze`, `suggest` and `default`
  packages lost in the move to the referenced standard, and put the repo-local
  hook tools on the dev shell and `confirm` PATH.
