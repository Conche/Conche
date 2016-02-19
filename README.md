# Conche

[![Build Status](https://img.shields.io/travis/Conche/Conche/master.svg?style=flat)](https://travis-ci.org/Conche/Conche)

Conche is a Swift build system.

## Project Status

After the release of Conche, Apple surprised us and release the Swift Package Manager (SPM) and therefore this project isn't applicable. I'd suggest you instead take a look at SPM and use that over Conche.

## Installation

The easiest way to install Conche is with Homebrew:

```shell
$ brew install --HEAD kylef/formulae/conche
```

If you don't have Homebrew, Conche can be installed using the Makefile:

```shell
$ git clone --recursive https://github.com/Conche/Conche
$ cd Conche
$ make install
```

## Usage

To get started with Conche, you can use `conche init` to create your first project.

```bash
$ conche init HelloWorld --with-tests
Initialised HelloWorld.
```

Conche uses the standard JSON podspec format to build your library. In your
podspec you can declare the source files, and dependencies used for your project.

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

You can use Conche in conjunction with the [Spectre](https://github.com/kylef/Spectre) BDD testing library.

```shell
$ conche test
```

### Entry Points

If you are building a command line tool, you can add each command line tool
you want to provide in the cli entry point section in your podspec.

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

You can execute your tool via `conche` after it's built.

```shell
$ conche exec <NAME>
```

You can install the CLI entry points to your system using Conche.

```shell
$ conche install
```

### FAQ

#### I want to use Xcode.

Conche is probably not for you, I'd suggest you take a look at [CocoaPods](https://cocoapods.org/)
instead which offers Xcode integration. The purpose of Conche is that it is a
build system separate from Xcode which can work on various platforms such as
Linux.

#### Does Conche support Linux?

Currently it does not, however it's built with other operating systems
in-mind and it would be trivial to add support for other platforms once Swift
is finally opened sourced. See [#7](https://github.com/Conche/Conche/issues/7).

#### Can I build an OS X, iOS, watchOS, tvOS application with Conche?

Not yet, but in the future you may be able to. Only CLI tools and libraries are
supported.

#### Why don't you support X?

Either we don't want to or we haven't got round to implementing it yet. Pull
requests are welcome.

#### Can Conche build Conche?

Of course.
