# Changelog

## 2.2.0

* Added ability to filter out levels of errors
* Upgraded CFLint to latest 1.4.1 release

## 2.0.1

* Fixed issue where output does not write to the current working directory

## 2.0.0

* Running CFLint via the Java API instead of via the command line
* Fixes issue [#4](https://github.com/jsteinshouer/commandbox-cflint/issues/4) where Windows users get error that the command line is too long
* Bumping the major version because this load CFLint via an OSGi bundle which requires CommandBox 4 or above

## 1.2.1

* Fixed default pattern parameter since the | no longer works in a glob pattern

## 1.2.0

* Upgraded CFLint to latest 1.4.0 release

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