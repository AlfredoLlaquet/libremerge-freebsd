# LibreMerge for FreeBSD — Project Purpose and Working Rules

> [!IMPORTANT]
> **Never send any request upstream.** Treat LibreMerge, WinMerge, and every other upstream project as read-only. Never push changes upstream, open a pull request or issue there, ask for a feature, review, or support, or contact upstream maintainers by comment, discussion, email, or private message. This rule covers everyone acting on behalf of this project, including automated workflows. Reading documentation and fetching upstream source and tags are part of normal maintenance.
>
> Keep fixes and proposals in `AlfredoLlaquet/libremerge-freebsd`. Before opening an issue or pull request, check the destination on GitHub. For a pull request, the **base repository** must be this fork.

## Purpose and name

Use the following repository description verbatim.

> An independently maintained FreeBSD port of LibreMerge

Keep the application name **LibreMerge**. The goal is to make the existing Qt 6 file and folder comparison and merge application build and run natively on FreeBSD. Its immediate upstream is `iagodpassos/libremerge`, which uses WinMerge’s comparison engine. Keep FreeBSD changes focused so the interface and comparison behavior stay familiar and future releases are easy to merge. [Upstream LibreMerge](https://github.com/iagodpassos/libremerge)

Programmed by **ChatGPT** for Alfredo Llaquet-Alsina.

## Marking FreeBSD code changes

Use one pair of `LM4FBS` markers around each logical block changed for this port. Keep the marker words the same in every language and use the file’s own comment syntax. Add a short reason to the opening marker when it helps explain the change.

For a replacement, start with `LM4FBS BEGIN` and preserve the complete upstream block immediately below it as comments, retaining its line breaks and indentation. Put `LM4FBS REPLACEMENT` on its own comment line, followed by the active replacement block and then `LM4FBS END`. This C++ example shows the five parts together.

```cpp
// LM4FBS BEGIN — Honor the configured temporary directory.
// const QString directory = QStringLiteral("/tmp");
// return QDir(directory).filePath(fileName);
// LM4FBS REPLACEMENT
const QString directory = QDir::tempPath();
return QDir(directory).filePath(fileName);
// LM4FBS END
```

For entirely new code, put the active block directly between `LM4FBS BEGIN ADDITION` and `LM4FBS END`. A CMake addition uses the same markers with `#` comments.

```cmake
# LM4FBS BEGIN ADDITION
if(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
    message(STATUS "Building LibreMerge for FreeBSD")
endif()
# LM4FBS END
```

The commented original must match the upstream revision currently used by this fork. When a later upstream version changes that block, refresh the commented copy and review the active FreeBSD replacement against it as part of the same update.

## Following LibreMerge releases

1. Use `origin` for this fork and `upstream` for `iagodpassos/libremerge`. For each new stable LibreMerge release, fetch its tag and merge it into the fork. Resolve conflicts here and review which FreeBSD patches are still needed.
2. Before publishing, build and test the merged version in a **FreeBSD virtual machine**. Run the existing CTest suite and application self-tests. Verify that the Qt application launches, compares files and folders, and saves a merge result. Fix FreeBSD regressions in this fork.
3. Identify the upstream tag in each downstream release. Record the FreeBSD version and what was actually tested, including any gaps. Publish a tagged source archive that corresponds to the release.

### Native FreeBSD validation

Keep the `FreeBSD` workflow (`.github/workflows/freebsd.yml`) enabled for this fork’s automated tests. Keep the inherited `CI` workflow (`.github/workflows/ci.yml`), which tests macOS and Linux, disabled in the fork’s GitHub Actions settings. Keep `ci.yml` synchronized with upstream and recheck the setting if an upstream update renames or replaces that workflow.

The initial FreeBSD changes date from November 23, 2026. The fork starts at upstream commit `7ae6fb9e3e306729675745f4fc7add809c57fda7`, 15 commits after `v1.5.0`. Its validation target is FreeBSD 15.1-RELEASE on amd64. The fork’s FreeBSD workflow builds with base Clang and `/usr/bin/make` as a regular user, installs into `/usr/local` as root, and exercises the installed program as the regular user.

Keep coverage for two FreeBSD behaviors when integrating upstream changes. The engine locates its executable through `KERN_PROC_PATHNAME`, including when procfs is unmounted. Folder operations can use the desktop Trash on a fresh account, and an overwritten file must remain recoverable with its original contents. The workflow also opens file and folder comparisons on a virtual X11 display and checks a saved merge and its backup against the expected bytes.

### Keeping the README in sync

Maintain the FreeBSD notice at the top of `README.md`, including the programming credit from “Purpose and name” and the full, clickable upstream project URL. Keep FreeBSD-specific README edits in that notice. Preserve the visible space before the first horizontal rule (`---`) and the blank line after it.

Keep the notice’s FreeBSD installation instructions in step with the commands verified in the VM, including dependency packages, cloning this fork, building, running CTest, and installing with `make install`.

When integrating an upstream tag or commit, copy the complete `README.md` from that exact revision below the divider. Verify that the text after the divider and its blank line matches the upstream file byte for byte.

## Licensing and FreeBSD packages

LibreMerge as a whole is licensed under **GNU GPL version 3 or later**. Preserve copyright and license notices, retain the notices for bundled components, and identify and date downstream modifications. When distributing a binary, make its complete corresponding source available, including the FreeBSD patches and build scripts used for that release. [License](LICENSE) · [Bundled components and their licenses](docs/VENDORED.md)

The proposed FreeBSD package name is `libremerge`. A ports maintainer can keep the build recipe and checksum in the separate FreeBSD Ports Collection and fetch a tagged source archive from this fork. That work can be done independently of Alfredo, with read-only access to this repository. The FreeBSD Project decides on inclusion and can mirror the source archive and distribute binary packages.

For a future ports recipe, `engine/TreeSitterGrammars.cmake` lists the pinned grammar archives and their SHA-256 checksums. A port can fetch them as distfiles and pass their directory to CMake as `LM_TREE_SITTER_DOWNLOAD_DIR` to configure offline.

## Working with Alfredo

ChatGPT handles the engineering work Alfredo requests, including implementation, builds, testing, upstream release integration, documentation, packaging, and publication of authorized releases. Alfredo provides authorization when a step requires it, performs any additional testing he chooses, and uses the application.

When Alfredo introduces a message with **`Question:`**, answer the question only. Wait for a separate instruction before acting on it.

## Keeping this guide current

Update this file whenever a new project decision is made, an existing decision changes, or something relevant needs to be taken into account in future work. Make the update as part of the work it governs. Replace superseded guidance and distinguish settled decisions from open questions.
