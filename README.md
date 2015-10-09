# Conche

A native Swift build system and dependency manager.

## Usage

Conche uses information about your library described in it's podspec, including
any dependencies.

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

```json
{
  "name": "Conche",
  "version": "1.0.0",
  "source_files": "Conche/*.swift",
  "entry_points": {
    "cli": {
      "conche": "bin/conche.swift"
    }
  },
  "dependencies": {
    "Commander": [ "~> 0.5.0" ],
    "PathKit": [ "~> 0.5.0" ]
  }
}
```

**NOTE**: *`entry_points` is an extension to a podspec allowing you to create CLIs.*

You can execute your tool via `conche` after built.

```shell
$ conche exec <NAME>
```

### Testing

You can use Conche in conjunction with the [Spectre](https://github.com/kylef/Spectre) BDD testing library.

```shell
$ conche test
```

## Installation

### Homebrew

```shell
$ git clone --recursive https://github.com/kylef/Conche
$ cd Conche
$ make DESTDIR=/usr/local/Cellar/Conche/HEAD install
$ brew link conche
```

##### Why don't you have a formula?

Conche is still alpha and this will be made when we're ready.

### Other

```shell
$ git clone --recursive https://github.com/kylef/Conche
$ cd Conche
$ make install
```

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

#### Can I build an OS X, iOS, watchOS, tvOS application with Conche?

Not yet, but in the future you may be able to. Only CLI tools and libraries are
supported.

#### Why don't you support X?

Either we don't want to or we haven't got round to implementing it yet. Pull
requests are welcome.

#### Can Conche build Conche?

Of course.

