# LibreMerge for FreeBSD and OpenBSD

LibreMerge is a graphical tool for comparing and merging files and folders. This independently maintained FreeBSD port also supports OpenBSD. This repository provides the source, binary packages, and installation instructions for both systems. The upstream project is at <https://github.com/iagodpassos/libremerge>.

Programmed by **ChatGPT** for Alfredo Llaquet-Alsina.

## Install from a FreeBSD package

Download the package for your version of FreeBSD. You can [verify the download](#verify-the-freebsd-package) before installing it. Open a **root shell** in the directory where you saved it and run the matching command below.

| Release download | Install command for revision 3 |
| --- | --- |
| [FreeBSD 14 amd64 package](https://github.com/AlfredoLlaquet/libremerge-freebsd/releases/download/v1.5.0-freebsd.3/libremerge-1.5.0_3-FreeBSD-14-amd64.pkg) | `pkg install ./libremerge-1.5.0_3-FreeBSD-14-amd64.pkg` |
| [FreeBSD 15 amd64 package](https://github.com/AlfredoLlaquet/libremerge-freebsd/releases/download/v1.5.0-freebsd.3/libremerge-1.5.0_3-FreeBSD-15-amd64.pkg) | `pkg install ./libremerge-1.5.0_3-FreeBSD-15-amd64.pkg` |

The `./` selects the local file. `pkg` fetches any missing runtime dependencies from your configured FreeBSD repositories. Open **LibreMerge** from your desktop’s applications menu, or run `libremerge` in a terminal as your regular user.

## Verify the FreeBSD package

Save [SHA256SUMS for revision 3](https://github.com/AlfredoLlaquet/libremerge-freebsd/releases/download/v1.5.0-freebsd.3/SHA256SUMS) in the same directory as your `.pkg` file. Keep both original filenames. Before installing or updating, run this command in that directory as your regular user.

```sh
sha256sum --ignore-missing -c SHA256SUMS
```

Look for your package’s exact filename followed by `: OK`. This confirms that the download matches the published checksum. The command skips release files you did not download. If your package shows `FAILED`, download it again and repeat the check. If its name is missing from the output, check the directory, filenames, and release revision before proceeding.

## Update from the FreeBSD package

Close LibreMerge and download the newer `.pkg` for your FreeBSD major version from the table above or [the releases page](https://github.com/AlfredoLlaquet/libremerge-freebsd/releases). In a root shell in the download directory, run `pkg install ./` followed immediately by the **new filename**, just as in the table above. The command upgrades the installed copy. Run `pkg info libremerge` to see the installed package version, then reopen LibreMerge.

## Install on FreeBSD from source

These steps build LibreMerge with the base system’s Clang and `make` and install it under `/usr/local`.

1. In a root shell, install the dependencies.

   ```sh
   pkg install git cmake qt6-base qt6-svg qt6-imageformats qt6-translations \
       poco boost-libs icu re2c lemon googletest
   ```

2. As your regular user, clone this fork and build the application. The first CMake configuration downloads the syntax-highlighting grammars.

   ```sh
   git clone https://github.com/AlfredoLlaquet/libremerge-freebsd.git
   cd libremerge-freebsd
   cmake -S . -B build -G "Unix Makefiles" -DCMAKE_MAKE_PROGRAM=/usr/bin/make \
       -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
   cd build
   make -j2
   ```

3. From the same `build` directory, install with root privileges.

   ```sh
   su root -c 'make install'
   ```

4. In your graphical desktop session, start LibreMerge as your regular user.

   ```sh
   libremerge
   ```

## Update on FreeBSD from source

As your regular user, open a terminal in the **top level of your existing clone** (the `libremerge-freebsd` directory containing `CMakeLists.txt`). Pull the latest changes and rebuild using the same `build` directory.

```sh
git pull --ff-only
cmake -S . -B build -G "Unix Makefiles" -DCMAKE_MAKE_PROGRAM=/usr/bin/make \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
cd build
make -j2
```

From that same `build` directory, reinstall with root privileges. The next time you launch `libremerge`, it will run the updated version.

```sh
su root -c 'make install'
```

## Install from an OpenBSD package

The OpenBSD package is built for **OpenBSD 8.0 on amd64**. Run `uname -r` and `machine -a` to check your system. Save `libremerge-1.5.0.tgz` and its accompanying `SHA256` in a directory of their own. As your regular user, verify the package in that directory.

```sh
sha256 -C SHA256 libremerge-1.5.0.tgz
```

After the checksum reports `OK`, open a root shell in the same directory and install from it. The command trusts this directory for the fork’s unsigned package and uses your configured OpenBSD mirror for dependencies.

```sh
env TRUSTED_PKG_PATH="$PWD" PKG_PATH=installpath pkg_add libremerge-1.5.0
```

Run `libremerge` as your regular user in your graphical session, or open **LibreMerge** from the applications menu. To remove the package later, run `pkg_delete libremerge` as root.

## Install on OpenBSD from source

Use an OpenBSD 8.0 installation with the compiler and X sets. The following commands install under `/usr/local`.

1. In a root shell, install the dependencies.

   ```sh
   pkg_add git cmake ninja qt6-qtbase qt6-qtsvg qt6-qtimageformats qt6-qttranslations \
       boost icu4c libarchive re2c gtest pcre2 libutf8proc vulkan-headers
   ```

2. As your regular user, clone the fork and build it. The first configuration downloads the pinned syntax grammars, Poco Foundation, and SQLite Lemon. The build checks their SHA-256 digests. A matching complete source archive also supports an [offline build](packaging/openbsd/README.md).

   ```sh
   git clone -b development https://github.com/AlfredoLlaquet/libremerge-freebsd.git
   cd libremerge-freebsd
   cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
   cmake --build build --parallel 2
   ```

3. From the top of the same checkout, install with root privileges. Then start `libremerge` from your regular user’s desktop session.

   ```sh
   su root -c 'cmake --install build'
   ```

To update a source installation, run `git pull --ff-only` at the top of your existing checkout, then repeat the configure, build, and install commands. To make a binary package of your own, see [Building the OpenBSD port](packaging/openbsd/README.md).

## Run the automated tests (optional)

After building on either system, you can run CTest as your regular user from the `libremerge-freebsd/build` directory. It checks the comparison engine and image merging, including file and folder comparisons, filters, and how dates are interpreted in your local time zone.

```sh
ctest --output-on-failure
```

CTest prints the name and output of each failed test. The full log for the most recent run is `Testing/Temporary/LastTest.log`, relative to the build directory.

## Compatibility

All packages listed here are for **amd64** (64-bit Intel or AMD). Choose the package for your operating system and release.

| Package | Built on | Fresh installation and upgrade tested on |
| --- | --- | --- |
| FreeBSD 14 amd64 | 14.4-RELEASE | 14.4-RELEASE and 14.5-RELEASE |
| FreeBSD 15 amd64 | 15.1-RELEASE-p6 | 15.1-RELEASE-p6 |

**Expected compatibility.** Later patch levels of the releases above and later minor releases in the same major series on amd64 should work when compatible versions of Qt and the other runtime libraries are available. These versions have not been tested individually. A later 14.x release would use the FreeBSD 14 package.

On **OpenBSD 8.0 amd64**, the automated checks cover building and installing from source, installing the ports-built `.tgz` on a fresh system, and comparing and merging files in both installations. An OpenBSD binary package is specific to its release and architecture.

<br>

### Alfredo Llaquet-Alsina is not only a FreeBSD enthusiast, but also a writer. Please visit [www.TheCrumbs.org](https://www.thecrumbs.org/) and take a look at his work, free for everyone.

<br>

Everything below the horizontal rule is the upstream LibreMerge README, reproduced verbatim from the revision used by this fork. Its download and installation instructions describe the upstream macOS and Linux releases.

<br><br>

---

# LibreMerge

**A free, open-source differencing and merging tool for macOS (and Linux) — bringing the WinMerge experience beyond Windows.**

LibreMerge reuses the battle-tested comparison engine of [WinMerge](https://winmerge.org/) — GNU diffutils + git xdiff, folder scanning, file filters, moved-block detection, Unicode handling — and rebuilds the user interface natively with Qt 6, since the original UI is written in MFC and cannot leave Windows. If you know WinMerge, you already know LibreMerge: the layout, the colors and the workflow are intentionally the same.

📦 [Releases](https://github.com/iagodpassos/libremerge/releases) · ☕ [Buy me a coffee](https://buymeacoffee.com/iagodpassos) · 🪙 [Donate in crypto](#support)

![File comparison](docs/screenshots/file-compare-light.png)

## Features

- **Side-by-side file comparison and merging** (2-way and 3-way) with the classic WinMerge look: gold difference blocks, character- or word-level highlights inside lines, gray filler keeping the panes aligned line by line
- **Free editing with live remerge**: type directly in the panes, copy differences (or all of them) in either direction, or just what a selection takes in (whole differences, inline differences, lines or characters, as WinMerge's copy granularity says), from the Merge menu or WinMerge's pane menu, with its Select Line Difference (F4) and a difference's text to the clipboard (Ctrl+1, 2 and 3), undo/redo, recompare with F5; Tab and Shift+Tab indent and unindent the selected lines, with tabs or spaces and the tab size of WinMerge's Options > Editor; Enter keeps the line's indentation and, in languages with braces, goes in a level after an opening bracket, while a closing one typed alone goes back, as WinMerge's auto-indent (a box of Options > Editor leaves the brackets out); files are saved with their original encoding, BOM and line endings preserved (each line's own in a file whose lines end in more than one way, and in every file with WinMerge's Preserve original EOL in Options > Editor); line endings count in the comparison, and files whose lines end otherwise bring up WinMerge's question to treat them as the same; File > Convert Line Endings to (or a click on the ending in the status bar) makes a pane's lines all end alike, and View Whitespace and View EOL show what is there
- **Folder comparison** (2-way and 3-way) with a hierarchical tree or flat list, background scanning with progress and cancel, file masks / regex / expression filters, copy between sides and delete to Trash (every pairwise direction in 3-way, from the context menu); a file on one side only opens against an empty untitled pane, as in WinMerge; two selected files with different names (three in 3-way) compare with each other through Compare or Enter, and Compare Non-horizontally picks the sides of two; the 3-way view marks which pair stayed identical on each difference, like WinMerge. Without "Include subfolders" (on the selection screen) only the top folders' items are compared: a subfolder opens in the same window and ".." goes back up, as in WinMerge. WinMerge's seven compare methods (full, quick or binary contents, modified date, date and size, size, existence), switched from the status bar, and its View menu filters to show or hide identical, different, unique, skipped or binary items; Hide Items, in the context menu, keeps the items you pick out of the list across recompares, until View > Show Hidden Items
- **Archive comparison** (zip, 7z, tar and compressed tar, plus single-file gz/bz2/xz/zst): archives extract to temporary folders and open as a folder comparison, WinMerge style, against another archive or a plain folder, 2- or 3-way, with nested archives unwrapped automatically
- **Diff pane** showing the current difference per file, WinMerge's path bar over each pane in every comparison (copy the path or the file name, edit the caption or the path in place, open another file, the clipboard or a recent file in the pane), per-pane status bars (line/column, encoding, EOL), and WinMerge's **location pane**: the whole comparison at a glance, a click or a drag to move through it, and its menu with Go to Line and moved blocks; Edit > Go to (Ctrl+G) reaches a line of any file or a difference by its number
- **CSV/TSV table comparison** (2-way and 3-way) as side-by-side grids: cell editing (F2 or start typing) with undo, a cell edited as its line has it as in WinMerge's text: a delimiter typed parts the cell, a line break (Shift+Enter or Alt+Enter) the row, Backspace at a cell's start and Delete at its end join it to the one before or after, copies of whole differences, of the selected cells or of the selected rows, from the Merge menu or a cell's context menu (with Select Line Difference, F4, going cell by cell, a difference's text to the clipboard with Ctrl+1, 2 and 3, the filters and File > Convert Line Endings to), cell-level difference highlighting, quoted fields (a quoted cell may run over several lines), first-row headers, columns left out of the comparison from the header's menu (in every file or in one, as WinMerge's Ignore This Column), and WinMerge's Options > Compare > Table to pick the files that open as tables (CSV, TSV or a delimiter of your own, by file pattern) with their delimiter and quote character
- **Image comparison** (2-way and 3-way) with WinMerge's own image-diff engine: block-level pixel differences with adjustable block size and color-distance threshold, insertion/deletion detection for shifted rows/columns, XOR and alpha-blend overlays, blink mode, wipe and rectangle-select dragging, multi-page navigation (animated GIF, multi-page TIFF, saved back with their pages and an animation's delays, as WinMerge does), rotation/flips, copy between sides with undo, and a clickable difference minimap; WinMerge's Options > Compare > Image picks the image files by pattern and can compare images by their pixels in folder comparisons too; SVG files compare as pictures too, and PDF files page by page on macOS (add *.svg or *.pdf from the patterns' drop-down, as in WinMerge), drawn at Image > Vector Image Scaling and saved back as PNG
- **Binary comparison** (2-way and 3-way), after WinMerge's hex view: the files as hex dumps side by side, each byte that differs at the same offset colored, next and previous difference, the selected bytes or all of them copied across, and the editing of the hex editor WinMerge embeds (overwrite or insert, by hex digit or by character, Cut, Copy and Paste, Find and Replace in Frhed's special syntax, Go to offset) with one undo history for the panes. Binary files and WinMerge's binary file patterns open it, and Options > Compare > Binary holds the editor's settings
- **WinMerge's filters**: Tools > Filters with its three pages, file filters (one global folder filter with masks, expressions and presets, picked from the selection screen and built with the "=" helper menu), line filters (regular expressions that mark matching differences as trivial) and substitution filters; a **display filter bar** in the folder window (by comparison result, or per column) and in the file and table windows (hide the lines a text or a line expression does not match, with the "=" menu to build one); and **moved block detection**
- **Find and Replace** in the compare panes with WinMerge's own dialogs: whole word, match case, regular expressions (their groups in the replacement), Replace All in a selection, F3 to search again, every occurrence of the text marked, and the Marker dialog for texts of your own marked in three colors
- **Syntax highlighting** as WinMerge colors files: its own parsers for 47 languages and Tree-sitter grammars for 23, the built-in parsers first by default (YAML, TOML, Markdown, TypeScript and properties files then come from Tree-sitter) or in the order picked in Options > Editor; WinMerge's View > Syntax Highlight and the status bar's syntax column choose the language by hand, of every pane or of one, and its Options > Editor > Syntax sets the extensions each language opens by; "Ignore comment differences" knows the comments of all of them, by the language chosen
- **WinMerge's color schemes** (Default, Modern, Solarized Light, VS Dark, Midnight, Solarized Dark, Twilight), one for the light mode and one for the dark, with the mode light, dark or following the system (on Linux, the dark style of GNOME and KDE, picked up as you switch it), every color of them changed on WinMerge's Colors pages (Differences, Syntax, Text, Markers, Folder Compare, System), and schemes of your own saved from the current colors, under Options > Colors; **English, Spanish, Catalan, French, German and Brazilian Portuguese** interface following the system language
- Drag & drop files or folders onto the window or the Dock icon; a WinMerge-style "Select Files or Folders" screen with history, paths verified as you type, auto completion, read-only flags and swap, the compare options at hand on the Options button's arrow, and Compare's arrow to open files as text, table, binary, image or archive; a single file opens against a snapshot of itself, to review your own edits
- **WinMerge project files** (`.WinMerge`, in WinMerge's own format): File > Open Project (Ctrl+J, ⌘J on the Mac) opens every comparison a project holds, with its read-only sides, descriptions, filter, subfolders, compare options and hidden items, and the recent projects are listed in the File menu; File > Save Project saves the comparison in front, and the selection screen loads and saves projects too; Options > Project picks which items opening, loading and saving take
- Comparison options carried over from WinMerge: ignore whitespace/case/blank lines/EOL/numbers, diff algorithm selection (Myers, minimal, patience, histogram)
- An **Options dialog laid out like WinMerge's**, with its General settings (close with Esc, preserve file times on save, verify paths, auto completion, reload of files changed by other applications), its Compare page (whitespace, case, blank lines, EOL, numbers, codepage and comment differences, moved blocks, indent heuristic, diff algorithm), its Message Boxes page, where notices such as "files are identical" can be hidden and brought back, its System page (deletes to the Trash or for good, the external editor that Open > With External Editor and Ctrl+Alt+E open files in, where user data and filters go, the temp folder), and its Codepage page: the codepage files without a BOM read and save in (the system's UTF-8, the interface language's or a custom one), HTML/XML/.rc files read by the charset they declare, and an encoding detector (ICU's, where WinMerge has Windows' mlang)

| Dark theme | Folder comparison |
| --- | --- |
| ![Dark theme](docs/screenshots/file-compare-dark.png) | ![Folder comparison](docs/screenshots/folder-compare-light.png) |

| Image comparison | On Linux (Debian/GNOME) |
| --- | --- |
| ![Image comparison](docs/screenshots/image-compare.png) | ![LibreMerge on Debian](docs/screenshots/linux-debian.png) |

## Install (macOS)

**Requirements**: macOS 14.4 (Sonoma) or later, Intel or Apple Silicon (universal binary). macOS 12 and 13 stay with [LibreMerge 0.9.9](https://github.com/iagodpassos/libremerge/releases/tag/v0.9.9), the last release that runs on them.

**Homebrew**:

```sh
brew install --cask iagodpassos/tap/libremerge
```

(Recent Homebrew asks you to trust third-party taps first: `brew trust iagodpassos/tap`.)

**Manual**: download `LibreMerge-<version>.dmg` from the [releases page](https://github.com/iagodpassos/libremerge/releases), open it and drag LibreMerge to Applications.

LibreMerge is not yet notarized by Apple, so the first launch needs one extra step: right-click the app → **Open** (or allow it under **System Settings → Privacy & Security**). If macOS still refuses ("app is damaged"), clear the download quarantine once:

```sh
xattr -d com.apple.quarantine /Applications/LibreMerge.app
```

You can also launch comparisons from the terminal:

```sh
LibreMerge left.txt right.txt          # 2-way file compare
LibreMerge base.txt mine.txt theirs.txt  # 3-way
LibreMerge dirA/ dirB/                 # folder compare
```

## Build from source (macOS / Linux)

Dependencies: a C++17 compiler, CMake ≥ 3.24, Ninja, Qt 6.4 or newer, POCO, ICU, Boost (headers), libarchive, re2c and lemon. The first configure downloads the sources of the Tree-sitter grammars WinMerge uses, about 12 MB (`-DLM_TREE_SITTER_GRAMMARS=OFF` builds without them). On macOS: `brew install cmake ninja qt poco icu4c boost googletest re2c lemon libarchive`. On Debian/Ubuntu see the package list in [`.github/workflows`](.github/workflows).

```sh
cmake -S . -B build -G Ninja
cmake --build build
ctest --test-dir build        # engine test suite (417 tests)
./build/app/LibreMerge        # (on macOS: build/app/LibreMerge.app)
```

## Install (Linux)

**AppImage** (recommended — any distro, x86_64 or arm64): download the `LibreMerge-<version>-<arch>.AppImage` for your architecture from the [releases page](https://github.com/iagodpassos/libremerge/releases), make it executable and run — Qt, ICU and Poco are bundled, nothing to install. Needs glibc 2.35+ (Debian 12+, Ubuntu 22.04+, Mint 21+, Fedora 36+, Arch):

```sh
chmod +x LibreMerge-<version>-x86_64.AppImage && ./LibreMerge-<version>-x86_64.AppImage
```

To add the AppImage to your applications menu (GNOME, KDE and others), run it once with `--install-desktop-integration`; it writes a menu entry pointing at the AppImage, its icons and the Dolphin context-menu entry below under `~/.local/share`, and `--remove-desktop-integration` takes them out again.

**Homebrew on Linux**: the same cask installs the AppImage for your architecture into `~/Applications`, adds it to the applications menu and to Dolphin's context menu, and puts a `libremerge` command on your PATH (glibc 2.35+ as above):

```sh
brew install --cask iagodpassos/tap/libremerge
```

**Dolphin (KDE)**: the AppImage's desktop integration, the Homebrew cask and an install from source (`cmake --install`, and so the PKGBUILD below) add *Compare with LibreMerge* to Dolphin's context menu when one to three files or folders are selected, like WinMerge's shell extension: two or three are compared, and one opens the selection window with it filled in.

**Arch Linux**: an AUR package is on the way. Meanwhile, `packaging/aur/PKGBUILD` on the `main` branch builds and installs the latest release with `makepkg -si`; the copy inside a release tag still points to the version before it, as it is updated right after each release is tagged.

Other formats (native .deb packages, Flatpak) come back if there is demand — open an issue if you need one and it moves up the list.

## Use with git

LibreMerge works as git's merge and diff tool. Conflicts open in the familiar three-pane layout, with the merged result in the middle pane.

**macOS**:

```sh
git config --global merge.tool libremerge
git config --global mergetool.libremerge.cmd \
  '/Applications/LibreMerge.app/Contents/MacOS/LibreMerge "$LOCAL" "$MERGED" "$REMOTE"'

git config --global diff.tool libremerge
git config --global difftool.libremerge.cmd \
  '/Applications/LibreMerge.app/Contents/MacOS/LibreMerge "$LOCAL" "$REMOTE"'
```

**Linux**: the same commands, with `libremerge` (or the path to the AppImage) in place of the full bundle path.

To use it, run `git mergetool` after a conflict: resolve it in the middle pane, save, and close the window. Two notes on the extra files you may see afterwards:

- LibreMerge writes a `.bak` copy next to the file it saves, which is WinMerge's default behavior. Turn it off under Options > Backup Files if you prefer.
- `git mergetool` itself keeps a `.orig` file unless you set `git config --global mergetool.keepBackup false`.

WinMerge's switches work in these commands too: for the merge tool, `-e -u -wl -wr -fm -dl Local -dm Merged -dr Remote` in front of the paths makes Esc close the window, keeps the files out of the recent comparisons, opens the outer panes read-only with the focus on the middle one, and names the three panes.

## Command line

LibreMerge reads WinMerge's command line, with `-` in front of each switch (`/` starts a path on macOS and Linux); `libremerge --help` lists the switches. For example:

```sh
libremerge -e -u -wl -dl "Base" -dr "Mine" base.txt mine.txt
```

These work today: the descriptions (`-dl`, `-dm`, `-dr`), read-only sides (`-wl`, `-wm`, `-wr`), the focus (`-fl`, `-fm`, `-fr`), `-e`, `-x` and `-xq`, `-u`, the window type (`-t`), the compare method (`-m`), the subfolders (`-r`, `-r-`), the file filter (`-f`), the line and character to go to (`-l`, `-c`), `-fileext`, the codepage (`-cp`), the table switches, the compare options (`-ignorews` and the like, and any option of the Options by WinMerge's name with `-cfg`), the output file (`-o`), `-noprefs`, `-inifile`, `-self-compare`, `-new`, `-minimize`, `-maximize` and `-show-dialog`. For scripts, `-noninteractive` answers every message box with Cancel (its text goes to the terminal) and closes once the comparison is done, without a window where Qt's offscreen platform is there, and `-enableexitcode` makes the exit code 0 for identical files or folders, 1 for different ones and 2 on an error:

```sh
libremerge -noninteractive -enableexitcode -noprefs old/ new/ && echo same
```

Not yet: `-or`, auto-merge (`-al`, `-am`, `-ar`) and plugins; LibreMerge says so on the terminal when it meets them. Windows' own switches for a single instance (`-s`, `-sw`, `-g`) are taken and have no effect: each run is a separate LibreMerge, which a caller waits for anyway.

## Known limitations

- Image comparison: PDF files compare on macOS only (the AppImage carries no Qt PDF module)
- On GNOME, Ctrl+Alt+Left and Ctrl+Alt+Right (Copy to Left and Advance, Copy to Right and Advance) switch workspaces and never reach LibreMerge; the toolbar buttons and the Merge menu still do it, and these commands leave GNOME's workspace switch on its other keys (Super+Page Up/Down and Super+Alt+Left/Right):

  ```sh
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>Page_Up', '<Super><Alt>Left']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Page_Down', '<Super><Alt>Right']"
  ```

## Support

If LibreMerge saves you time, you can [buy me a coffee](https://buymeacoffee.com/iagodpassos). ☕

You can also donate in crypto:

**Bitcoin (BTC)**
```
bc1q6zqluhqta4lud8vmzepdfxyp87ags3yf6htfau
```

**Solana (SOL)**
```
FR2ncB2yHZQ1pB6KmwjWu7hsuM2hNY2xqCQC8GQjUAuP
```

**Ethereum (ETH)**
```
0xF82f53D4D38471b44A00D1e55e61325A1b268D48
```

**Monero (XMR)**
```
47JW4qR9z8RCSLBLqYiRN6hDg4QwZs1ad9XdzsziVWXD4fKyeUhCw6xdSQZ9Tp41dPbcfGGoCNuH2FaUyPGVsVJNQVBHDAb
```

## AI-assisted development

This port was built with the assistance of **Claude Fable 5**, an AI model by [Anthropic](https://www.anthropic.com): the engine portability layer, the Qt interface and the release tooling came out of AI-assisted pair-programming sessions. Everything that ships is validated against WinMerge's own engine test suite (357 tests) and an application selftest suite, on macOS and Linux CI.

## Relationship to WinMerge, license

LibreMerge is an independent port based on the comparison engine of [WinMerge](https://winmerge.org/), © Dean P. Grimm / Thingamahoochie Software and the WinMerge contributors, licensed GPL-2.0-or-later. Vendored engine sources keep their original headers; the port layer and the Qt application are new code. See [docs/VENDORED.md](docs/VENDORED.md) for the exact provenance and local-change policy.

LibreMerge as a whole is distributed under the **GNU GPL v3.0 or later** ([LICENSE](LICENSE)).

**LibreMerge is not affiliated with or endorsed by the WinMerge project.** The name and icon are original to this project.

## Roadmap

HTML reports and patch generation, notarized builds, Linux packages (AUR first), and — if it proves itself — offering the portable engine fixes back to WinMerge upstream ([WinMerge/winmerge#141](https://github.com/WinMerge/winmerge/issues/141) tracks the idea of a cross-platform UI).

Issues and pull requests are welcome. Everyone who helps is credited in [CONTRIBUTORS.md](CONTRIBUTORS.md), which the About box shows too.
