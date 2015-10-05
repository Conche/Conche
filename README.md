# Conche

A native Swift build system and dependency manager.

## Usage

Butter is used to build your Swift files wrapped in a podspec

```shell
$ conche build
Building Commander
```

Simply describe your sources and dependencies in a JSON podspec and Conche can
build your Swift library.

```json
{
  "name": "Conche",
  "version": "1.0.0",
  "source_files": "Conche/*.swift",
  "entry_points": {
    "conche": "bin/conche.swift"
  },
  "dependencies": {
    "Commander": [ "~> 0.5.0" ],
    "PathKit": [ "~> 0.5.0" ]
  }
}
```

*NOTE*: **`entry_points` is an extension to a podspec allowing you to define binary files.**

```shell
$ conche build
Downloading Dependencies
-> PathKit 0.5.0
-> Commander 0.5.0
Building Dependencies
-> PathKit
-> Commander
Building Conche
Building Entry Points
-> conche -> .conche/bin/conche
```

## Installation

Todo.

## Status

Conche is currently a MVP and is missing many features.

### Missing Features

- Dependency resolution - Currently versions will not be checked and the latest
  version of a dependency MAY be used.
- Support for various components of a podspec, such as frameworks, resources,
  etc.
- Support for CocoaPods subspecs.
- Private spec repositories.

### FAQ

#### I want to use Xcode.

Conche is probably not for you, I'd suggest you take a look at CocoaPods
instead which offers Xcode integration. The purpose of Conche is that it is a
build system separate from Xcode which can work on various platforms such as
Linux.

#### Does Conche support Linux?

Currently it does not, however it's built with other operating systems
in-mind and it would be trivial to add support for other platforms once Swift
is finally opened sourced. See [#7](https://github.com/kylef/Conche/issues/7).

