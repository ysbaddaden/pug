# Pug

A lightweight tool for managing software executables at specific versions,
ensuring reproducibility across operating systems.

The idea stems from the fact that most developers today publish binaries
alongside their source code – for example as GitHub release assets. Modern
languages (Go, Rust, Zig, …) make it straightforward to distribute software for
the major operating systems.

## Key benefits

- No need to wait for your distribution to ship a new package, and you're not
  forced to upgrade your whole system when you want a newer tool.
- Keeps your system free of unnecessary global dependencies; each executable is
  treated like a runtime.
- Eliminates the need for Docker or Nix tool.
- Works on all major operating systems (only tested on Linux).
- Reproducible installations across platforms.

## Usage

Write a simple `pug.json` file (see the examples below), then run `pug run
<command>` or `pug shell` to start an interactive shell. That's it.

## Catalog

Downloads are defined in a catalog of URL templates for Linux, macOS
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

Define the tools you want to install in a `pug.json` file, specifying the
package name and the desired version. Each package is looked up in the catalog.
For example:

```json
[
  {"name": "prek",  "version": "0.4.6"},
  {"name": "rumdl", "version": "0.2.28"}
]
```

Pug downloads each version into a cache, and tries to find a `<name>` (or
`<name>.exe`) executable in the extracted archive, or the downloaded file to be
the executable itself.

Pug downloads each specified version into a cache, extracts the archive (if
necessary), and looks for an executable named `<name>` (or `<name>.exe`).
Dependencies are fetched automatically when required. When you run `pug run
<command> [args...]` or `pug shell`, Pug temporarily adjusts `PATH` so that all
the installed executables are available.

## Upgrades

The `pug outdated` command lists packages that have a newer release available.
It currently works only with GitHub release assets, so you need to edit
`pug.json` manually to upgrade.

## Status

Pug is usable, though still somewhat rough around the edges.

- The catalog must be manually created in the user's data directory:
  - UNIX: `~/.local/share/pug/catalog.json`
  - macOS: `~/Library/Application Support/pug/catalog.json`
  - Windows: `~\AppData\Roaming\pug\catalog.json`

- The bundled catalog is sparse; a comprehensive catalog would be valuable but
  would require significant maintenance.

- Pug could also install executables globally, for example by linking them into
  `~/.local/bin` (UNIX only). A simple `pug.json` could therefore be used to set
  up a system with up‑to‑date or legacy tools we rely on regularly.

## License

Distributed under the MIT license.
