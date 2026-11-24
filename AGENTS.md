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

Use the long-lived `development` branch for all changes. Start from the current `main`, integrate later changes from `main` when needed, and keep the branch after merging. Give Alfredo the development README, the successful FreeBSD run, and its tested package downloads for review. Merge the reviewed commit to `main` after Alfredo approves. A push to either branch may build artifacts. Publishing a release is a separate, authorized step.

1. Use `origin` for this fork and `upstream` for `iagodpassos/libremerge`. For each new stable LibreMerge release, fetch its tag and merge it into the fork. Resolve conflicts here and review which FreeBSD patches are still needed.
2. Before publishing, build and test the merged version in a **FreeBSD virtual machine**. Run the existing CTest suite and application self-tests. Verify that the Qt application launches, compares files and folders, and saves a merge result. Fix FreeBSD regressions in this fork.
3. Identify the upstream tag in each downstream release. Record the FreeBSD version and what was actually tested, including any gaps. Publish a tagged source archive that corresponds to the release.

### Native FreeBSD validation

Keep the `FreeBSD` workflow (`.github/workflows/freebsd.yml`) enabled for this fork’s automated tests. Keep the inherited `CI` workflow (`.github/workflows/ci.yml`), which tests macOS and Linux, disabled in the fork’s GitHub Actions settings. Keep `ci.yml` synchronized with upstream and recheck the setting if an upstream update renames or replaces that workflow.

The initial FreeBSD changes date from November 23, 2026. The fork starts at upstream commit `7ae6fb9e3e306729675745f4fc7add809c57fda7`, 15 commits after `v1.5.0`. Its validation target is FreeBSD 15.1-RELEASE on amd64. The fork’s FreeBSD workflow builds with base Clang and `/usr/bin/make` as a regular user, installs into `/usr/local` as root, and exercises the installed program as the regular user.

Keep coverage for the following FreeBSD behaviors when integrating upstream changes.

- The engine locates its executable through `KERN_PROC_PATHNAME`, including when procfs is unmounted.
- Folder operations can use the desktop Trash on a fresh account. An overwritten file must remain recoverable with its original contents.
- Filters interpret local dates using the time zone and daylight-saving offset for the date being compared. Preserve coverage for dates on both sides of a daylight-saving change.

Build the release candidate natively on FreeBSD 14.4 and 15.1 amd64. Use the oldest supported minor release selected for each major series as its binary build baseline. Run the complete CTest suite, the installed application’s self-tests, and the virtual X11 checks in both `UTC` and `Europe/Madrid`, with fresh XDG settings and data for each zone. The X11 checks open file and folder comparisons and verify a saved merge and its backup against the expected bytes.

In separate fresh VMs, install the actual candidate with `pkg install ./filename.pkg`, verify its version and contents, and test a real upgrade from the previous revision. Exercise the 14 package on both 14.4 and 14.5, and the 15 package on 15.1. Record the actual kernel and userland patch levels. When coverage changes, update both the workflow and the README’s tested and expected compatibility. Keep a successful source build distinct from a verified binary installation.

### Keeping the README in sync

Maintain the FreeBSD notice at the top of `README.md`, including the programming credit from “Purpose and name” and the full, clickable upstream project URL. Keep FreeBSD-specific README edits in that notice. Preserve the visible space before the first horizontal rule (`---`) and the blank line after it.

Maintain separate package installation and package update sections, with the right download and filename for each major ABI. Keep source installation and source update instructions in step with the commands verified in the VM, including dependencies, cloning this fork, building as a regular user, and installing with `make install` with root privileges. Specify the starting directory for rebuilding an existing clone. Give automated testing its own optional section after the installation and update instructions. Explain what CTest checks, where to run it, how to see failure output, and where to find the full test log.

Keep Alfredo’s author paragraph verbatim immediately before the paragraph explaining the divider. Use a third-level heading, a working link to https://www.thecrumbs.org/, and extra vertical space above and below it.

When integrating an upstream tag or commit, copy the complete `README.md` from that exact revision below the divider. Verify that the text after the divider and its blank line matches the upstream file byte for byte.

## Licensing and FreeBSD packages

LibreMerge as a whole is licensed under **GNU GPL version 3 or later**. Preserve copyright and license notices, retain the notices for bundled components, and identify and date downstream modifications. When distributing a binary, make its complete corresponding source available, including the FreeBSD patches and build scripts used for that release. [License](LICENSE) · [Bundled components and their licenses](docs/VENDORED.md)

Use the package name `libremerge`, a monotonically increasing FreeBSD package version (for example `1.5.0_3` for tag `v1.5.0-freebsd.3`), and a distinct filename for each major ABI. Update `packaging/freebsd/release.conf` and the README examples together. Test upgrades with the previously published binary for each ABI. The first package release builds an upgrade fixture from the actual previous source-only tag. Keep that fixture out of public downloads.

For a release, take both tested packages, the complete source archive and `SHA256SUMS` from the reviewed run’s `libremerge-FreeBSD-amd64` artifact. Verify the checksums and tag the same commit. Attach those exact files to the fork’s GitHub Release. The source archive includes the build scripts, FreeBSD changes, license notices and the grammar distfiles used by CMake. For an offline grammar build from the unpacked source, pass `-DLM_TREE_SITTER_DOWNLOAD_DIR="$PWD/distfiles"` at configure time. This project uses ordinary GitHub Releases.

A ports maintainer can independently keep a recipe and checksum in the FreeBSD Ports Collection and fetch a tagged source archive from this fork. The FreeBSD Project decides on inclusion and can mirror the source archive and distribute binary packages.

For a future ports recipe, `engine/TreeSitterGrammars.cmake` lists the pinned grammar archives and their SHA-256 checksums. A port can fetch them as distfiles and pass their directory to CMake as `LM_TREE_SITTER_DOWNLOAD_DIR` to configure offline.

## Working with Alfredo

ChatGPT handles the engineering work Alfredo requests, including implementation, builds, testing, upstream release integration, documentation, packaging, and publication of authorized releases. Alfredo provides authorization when a step requires it, performs any additional testing he chooses, and uses the application.

When Alfredo introduces a message with **`Question:`**, answer the question only. Wait for a separate instruction before acting on it.

## Keeping this guide current

Update this file whenever a new project decision is made, an existing decision changes, or something relevant needs to be taken into account in future work. Make the update as part of the work it governs. Replace superseded guidance and distinguish settled decisions from open questions.
