# Pug

A simple manager for install a list of software executables at specific
versions.

The project comes from the realization that most software developers today
upload executables along their source code, for example as GitHub release
assets. Modern languages make it easy to distribute software for the major
operating systems (Go, Rust, Zig, ...).

It comes with many benefits:

- No need to wait for your distribution to package a version, and no force
  upgrade when you upgrade your system;
- No need to pollute your system, Keep executable dependencies just like
  runtime;
- No need for Docker, Nix or devenv (they have their use, and their issues);
- No need for a different package manager for every operating system (only
  tested on Linux so far).
- Reproducible installations, across operating systems!

## Usage

Write a simple `pug.json` file (see below), then run `pug run <command>` or `pug
shell`. That's it.

## Catalog

Downloads are defined in a catalog of URL patterns for Linux, macOS
and Windows. For example:

```json
[
  {
    "name": "prek",
    "urls": {
      "linux": "https://github.com/j178/prek/releases/download/v$VERSION/prek-$ARCH-unknown-linux-musl.tar.gz",
      "macos": "https://github.com/j178/prek/releases/download/v$VERSION/prek-$ARCH-apple-darwin.tar.gz",
      "win32": "https://github.com/j178/prek/releases/download/v$VERSION/prek-$ARCH-pc-windows-msvc.zip"
    }
  },
  {
    "name": "shfmt",
    "urls": {
      "linux": "https://github.com/mvdan/sh/releases/download/v$VERSION/shfmt_v$VERSION_linux_$GOARCH",
      "macos": "https://github.com/mvdan/sh/releases/download/v$VERSION/shfmt_v$VERSION_darwin_$GOARCH",
      "win32": "https://github.com/mvdan/sh/releases/download/v$VERSION/shfmt_v$VERSION_windows_$GOARCH.exe"
    }
  },
]
```

## Packages

Installations are defined in a `pug.json` file listing the packages and the
version to install. Each package will be looked up in the catalog. For example:

```json
[
  {"name": "prek",  "version": "0.4.6"},
  {"name": "rumdl", "version": "0.2.28"}
]
```

Pug downloads each version into a cache, and tries to find a `<name>` (or
`<name>.exe`) executable in the extracted archive, or the downloaded file to be
the executable itself.

Dependencies are automatically downloaded when needed. Pug manipulates `PATH`
when calling commands so all the executables are available. You can execute `pug
run <command> [arg, ...]` to run a command with all the other executables
available, or `pug shell`.

## Upgrade

The `pug outdated` command lists packages that have a newer version available.
It only works with GitHub release assets for now, and you must manually edit
your `pug.json`.

## Status

Usable, though a little rough.

The catalog is expected to be at `../catalog.json` relative to the executable
for example. It should use `XDG` instead (or mac/win equivalent), and expect the
catalog to be at `~/.local/share/pug/catalog.json`.

The provided catalog is also almost empty. I'm not sure whether Pug should have
a general catalog. It would be nice, but also a lot of work to maintain...

Pug could also install dependencies as defaults for your system. For example by
linking the executables into `~/.local/bin/`. A simple `pug.json` could help
setup your system with up-to-date, or legacy, software you use on a regular
basis (not tied to a project).

## License

Distributed under the MIT license.
