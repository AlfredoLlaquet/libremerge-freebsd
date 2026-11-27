# LibreMerge for FreeBSD and OpenBSD — Project Purpose and Working Rules

> [!IMPORTANT]
> **Never send any request upstream.** Treat LibreMerge, WinMerge, and every other upstream project as read-only. Never push changes upstream, open a pull request or issue there, ask for a feature, review, or support, or contact upstream maintainers by comment, discussion, email, or private message. This rule covers everyone acting on behalf of this project, including automated workflows. Reading documentation and fetching upstream source and tags are part of normal maintenance.
>
> Keep fixes and proposals in `AlfredoLlaquet/libremerge-bsd`. Before opening an issue or pull request, check the destination on GitHub. For a pull request, the **base repository** must be this fork.

## Purpose and name

Use the following repository description verbatim.

> Independently maintained ports for FreeBSD and OpenBSD of LibreMerge

Keep the application name **LibreMerge**. The goal is to make the existing Qt 6 file and folder comparison and merge application build and run natively on FreeBSD and OpenBSD. Its immediate upstream is `iagodpassos/libremerge`, which uses WinMerge’s comparison engine. Keep BSD changes focused so the interface and comparison behavior stay familiar and future releases are easy to merge. [Upstream LibreMerge](https://github.com/iagodpassos/libremerge)

Since November 26, 2026, the same fork also targets OpenBSD. Develop both platforms on `development`. Preserve existing FreeBSD source, binary, and upgrade coverage when extending OpenBSD support. The initial OpenBSD target is 8.0 amd64, with both installation from source and a binary produced by OpenBSD’s ports framework.

Created and directed by **Alfredo Llaquet-Alsina**. Implemented by **ChatGPT**.

## Marking FreeBSD/OpenBSD code changes

Use one pair of `LM4BSD` markers around each logical block changed for FreeBSD, OpenBSD, or both. Keep the marker words the same in every language and use the file’s own comment syntax. Add a short reason to the opening marker when it helps explain the change. Preserve the native formats of machine-readable manifests, checksums, and packing lists. Keep unmodified third-party sources as distributed.

For a replacement, start with `LM4BSD BEGIN` and preserve the complete upstream block immediately below it as comments, retaining its line breaks and indentation. Put `LM4BSD REPLACEMENT` on its own comment line, followed by the active replacement block and then `LM4BSD END`. This C++ example shows the five parts together.

```cpp
// LM4BSD BEGIN — Honor the configured temporary directory.
// const QString directory = QStringLiteral("/tmp");
// return QDir(directory).filePath(fileName);
// LM4BSD REPLACEMENT
const QString directory = QDir::tempPath();
return QDir(directory).filePath(fileName);
// LM4BSD END
```

For entirely new code, put the active block directly between `LM4BSD BEGIN ADDITION` and `LM4BSD END`. A CMake addition uses the same markers with `#` comments.

```cmake
# LM4BSD BEGIN ADDITION
if(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    message(STATUS "Building LibreMerge for ${CMAKE_SYSTEM_NAME}")
endif()
# LM4BSD END
```

The commented original must match the upstream revision currently used by this fork. When a later upstream version changes that block, refresh the commented copy and review the active replacement for each affected BSD system as part of the same update.

## Following LibreMerge releases

All changes start on the long-lived `development` branch. Bring it up to date with `main` when needed, test the changes there, and keep the branch after merging. Tailor checks to the change. When Alfredo authorizes implementation through release in one run, ChatGPT carries out the BSD VM tests, fast-forwards `main` to the tested commit, confirms both BSD workflows pass there, and publishes the verified files. Follow the stage boundaries Alfredo sets for other requests.

1. Use `origin` for this fork and `upstream` for `iagodpassos/libremerge`. For each new stable LibreMerge release, fetch its tag and merge it into the fork. Resolve conflicts here and review which BSD patches are still needed.
2. Before publishing, build and test the merged version in native FreeBSD and OpenBSD virtual machines. Run the CTest suite and application self-tests. Verify that the Qt application launches, compares files and folders, and saves a merge result and its backup. Fix regressions in this fork.
3. Identify the upstream revision and tested commit in each downstream release. Record the FreeBSD and OpenBSD versions, architectures, installation and upgrade results, and any gaps. Publish the complete corresponding source archives alongside the packages.

### Native FreeBSD validation

Keep the `FreeBSD` workflow (`.github/workflows/freebsd.yml`) enabled for this fork’s automated tests. Keep the inherited `CI` workflow (`.github/workflows/ci.yml`), which tests macOS and Linux, disabled in the fork’s GitHub Actions settings. Keep `ci.yml` synchronized with upstream and recheck the setting if an upstream update renames or replaces that workflow.

The initial FreeBSD changes date from November 23, 2026. The fork starts at upstream commit `7ae6fb9e3e306729675745f4fc7add809c57fda7`, 15 commits after `v1.5.0`. Its initial validation target was FreeBSD 15.1-RELEASE on amd64. The fork’s FreeBSD workflow builds with base Clang and `/usr/bin/make` as a regular user, installs into `/usr/local` as root, and exercises the installed program as the regular user.

Keep coverage for the following FreeBSD behaviors when integrating upstream changes.

- The engine locates its executable through `KERN_PROC_PATHNAME`, including when procfs is unmounted.
- Folder operations can use the desktop Trash on a fresh account. An overwritten file must remain recoverable with its original contents.
- Filters interpret local dates using the time zone and daylight-saving offset for the date being compared. Preserve coverage for dates on both sides of a daylight-saving change.

Build the release candidate natively on FreeBSD 14.4 and 15.1 amd64. Use the oldest supported minor release selected for each major series as its binary build baseline. Run the complete CTest suite, the installed application’s self-tests, and the virtual X11 checks in both `UTC` and `Europe/Madrid`, with fresh XDG settings and data for each zone. The X11 checks open file and folder comparisons and verify a saved merge and its backup against the expected bytes.

In separate fresh VMs, install the actual candidate with `pkg install ./filename.pkg`, verify its version and contents, and test a real upgrade from the previous revision. Exercise the 14 package on both 14.4 and 14.5, and the 15 package on 15.1. Record the actual kernel and userland patch levels. When coverage changes, update both the workflow and the README’s tested and expected compatibility. Keep a successful source build distinct from a verified binary installation.

### Native OpenBSD validation

Build and install the documented source checkout with base Clang as a regular user, elevating privileges for installation. Use the OpenBSD release’s ports tree to build the binary package from the matching complete source archive. Keep all pinned sources and license notices needed for an offline rebuild in that archive. The overlay and build instructions are in [packaging/openbsd](packaging/openbsd/README.md).

Install the resulting `.tgz` in a separate VM created from official OpenBSD media on an empty disk with the base and X sets. Use the normal OpenBSD mirrors for runtime dependencies. Test a fresh installation and an upgrade from the previous available package, verifying its installed version before and after the upgrade. Verify the source-update commands from an existing checkout. Cover file and folder comparison, a saved merge and its backup, application self-tests, and the source build’s CTest suite. Record the release, architecture, tested commit, and workflow results.

### Keeping the README in sync

Maintain the BSD notice at the top of `README.md`. Its opening paragraph introduces LibreMerge and names the independently maintained FreeBSD and OpenBSD ports. Keep the programming credit from “Purpose and name” below that paragraph and the upstream project link in the explanation of the divider. Keep downstream README edits in the notice. Preserve the visible space before the first horizontal rule (`---`) and the blank line after it.

Write the notice for people installing, updating, and using LibreMerge. Link directly to the published packages and checksums under `AlfredoLlaquet/libremerge-bsd`. Use the default branch for a new clone and the current tracking branch for source updates (`git pull --ff-only`). Give development downloads and workflow links in project reports. Keep historical test results in their release notes.

In **Install from a FreeBSD package**, give the download link and matching install command for each supported FreeBSD major version and architecture. Follow it with **Verify the FreeBSD package**. Keep its direct `SHA256SUMS` link on the same release tag as the package links. In **Update from the FreeBSD package**, direct readers to both the download table above and the fork’s releases page.

Keep source installation and source update instructions in step with the commands verified in the VM, including dependencies, cloning this fork, building as a regular user, and installing with root privileges. On FreeBSD, run `make install` from the build directory. Specify the starting directory for rebuilding an existing clone. Give automated testing its own optional section after the installation and update instructions. Explain what CTest checks, where to run it, how to see failure output, and where to find the full test log.

On OpenBSD, use `cmake --install build` as root from the top of the checkout. Put **Update from an OpenBSD package** immediately after **Install from an OpenBSD package**, and **Update on OpenBSD from source** immediately after **Install on OpenBSD from source**. Document the ports-built filename, native `SHA256` check, local trusted download directory, and targeted `pkg_add -u libremerge` upgrade.

Place **Compatibility** last, after the optional tests and before Alfredo’s author paragraph. Follow the table of tested versions immediately with the expected compatibility for untested versions.

Keep Alfredo’s author paragraph verbatim immediately before the paragraph explaining the divider. Use a third-level heading, a working link to https://www.thecrumbs.org/, and extra vertical space above and below it.

When integrating an upstream tag or commit, copy the complete `README.md` from that exact revision below the divider. Verify that the text after the divider and its blank line matches the upstream file byte for byte.

## Licensing and BSD packages

LibreMerge as a whole is licensed under **GNU GPL version 3 or later**. Preserve copyright and license notices, retain the notices for bundled components, and identify and date downstream modifications. When distributing a binary, make its complete corresponding source available, including the BSD patches and build scripts used for that release. [License](LICENSE) · [Bundled components and their licenses](docs/VENDORED.md)

Use the package name `libremerge`, a monotonically increasing FreeBSD package version (for example `1.5.0_4` for tag `v1.5.0-bsd.4`), and a distinct filename for each major ABI. Update `packaging/freebsd/release.conf` and the README examples together. Test upgrades with the previously published binary for each ABI. On OpenBSD, use the release’s ports framework and bump the port’s `REVISION` when repackaging the same upstream version. Omit `REVISION` for the first package of a new upstream version. Point the OpenBSD upgrade test at the previous published tag, source commit, package name, and SHA-256 in `packaging/openbsd/ci/previous.conf`.

Take the two tested FreeBSD packages, the complete FreeBSD source archive and `SHA256SUMS` from the verified run’s `libremerge-FreeBSD-amd64` artifact. Take the tested OpenBSD package, its corresponding source archive and native `SHA256` from the matching `libremerge-OpenBSD-8.0-amd64` artifact for the same commit. The FreeBSD source includes the build scripts, BSD changes, license notices and grammar distfiles. For an offline FreeBSD grammar build from the unpacked source, pass `-DLM_TREE_SITTER_DOWNLOAD_DIR="$PWD/distfiles"` at configure time. The OpenBSD archive also supplies the sources used for its private Poco Foundation and SQLite Lemon builds.

For an authorized immutable release, check that release immutability is enabled, tag the tested commit, and create a draft release. Attach the three tested packages, both complete source archives, and both checksum files. Verify the draft assets against the tested downloads before publishing. Then check that the public README links download the same bytes, the tag resolves to the tested commit, and GitHub shows **Immutable**.

A ports maintainer can independently keep a recipe and checksum in the FreeBSD Ports Collection and fetch a tagged source archive from this fork. The FreeBSD Project decides on inclusion and can mirror the source archive and distribute binary packages.

For a future ports recipe, `engine/TreeSitterGrammars.cmake` lists the pinned grammar archives and their SHA-256 checksums. A port can fetch them as distfiles and pass their directory to CMake as `LM_TREE_SITTER_DOWNLOAD_DIR` to configure offline.

## Working with Alfredo

ChatGPT handles the engineering work Alfredo requests, including implementation, builds, testing, upstream release integration, documentation, packaging, and publication of authorized releases. Alfredo provides authorization when a step requires it, performs any additional testing he chooses, and uses the application.

When Alfredo asks a question, including a suggested change phrased as a question or a message beginning with **`Question:`**, answer it and wait for a separate instruction before making changes.

## Keeping this guide current

Update this file whenever a new project decision is made, an existing decision changes, or something relevant needs to be taken into account in future work. Make the update as part of the work it governs. Replace superseded guidance and distinguish settled decisions from open questions.
