# Changelog

## 1.1.0

* Fix for case sensitive OSs
* Added the ability for the `pattern` argument to accept a list of globbing patterns: ex `models/**.cfc,modules_app/**.cfc`

## 1.0.0

* Upgraded CFLint to latest 1.3.0 release
* Added the ability to suppress the display output if needed via the `suppress` argument
* Added the ability to generate multiple output types at once
* Added the ability to have the choice to fail with an exit code or note using the `exitOnError` argument, great for not failing CI builds if needed
* New text report output by using the `text` argument
* New json report output by using the `json` argument
* Added types for CLI introspection and tab completion.

## 0.5.0

* Original Release