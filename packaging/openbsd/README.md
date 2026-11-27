# Building the OpenBSD port

LibreMerge’s local port builds an ordinary OpenBSD package with `bsd.port.mk`. The first target is **OpenBSD 8.0, amd64**. The recipe lives in this fork. For installation from a package or from a Git checkout, see the [user instructions](../../README.md#install-from-an-openbsd-package).

## Build from the complete source archive

Download the [complete OpenBSD source archive](https://github.com/AlfredoLlaquet/libremerge-bsd/releases/download/v1.6.0-bsd.1/libremerge-1.6.0-source.tar.gz) and its [SHA256 file](https://github.com/AlfredoLlaquet/libremerge-bsd/releases/download/v1.6.0-bsd.1/SHA256). The archive contains the source used to build `libremerge-1.6.0.tgz`, the port recipe, and the pinned copies of Poco Foundation, SQLite Lemon, and the syntax grammars. Save both files in the same directory. With the [OpenBSD source-build dependencies](../../README.md#install-on-openbsd-from-source) installed, run the following as a regular user.

```sh
sha256 -C SHA256 libremerge-1.6.0-source.tar.gz
tar -xzf libremerge-1.6.0-source.tar.gz
cd libremerge-1.6.0
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DLM_OPENBSD_DISTFILES="$PWD/distfiles" -DFETCHCONTENT_FULLY_DISCONNECTED=ON
cmake --build build --parallel 2
ctest --test-dir build --output-on-failure
```

The build can run offline after its system dependencies are installed. To install the result, run `su root -c 'cmake --install build'` from this directory.

## Produce the binary package

Use a clean OpenBSD 8.0 amd64 build environment for a distributable 8.0 package. The release ports tree and the libraries installed in the build environment must agree. OpenBSD's regular package mirror also offers stable updates, which can have newer library versions. The build uses the original release packages as its minimum library versions. People installing LibreMerge can use the normal mirror with current updates.

If `/usr/ports` already contains the 8.0 release tree, proceed to the packaging commands below. To install it on a fresh 8.0 machine, fetch and verify it as a regular user, then extract it as root.

```sh
mkdir -p ~/ports-download && cd ~/ports-download
ftp -o ports.tar.gz https://cdn.openbsd.org/pub/OpenBSD/8.0/ports.tar.gz
ftp -o SHA256.sig https://cdn.openbsd.org/pub/OpenBSD/8.0/SHA256.sig
signify -C -p /etc/signify/openbsd-80-base.pub -x SHA256.sig ports.tar.gz
su root -c 'tar -C /usr -xzf ports.tar.gz'
```

In a root shell, start in the directory containing the verified LibreMerge source archive and its unpacked `libremerge-1.6.0` directory. Set `PKG_PATH` before installing any build dependencies on this machine. The literal release URL selects the package set that matches `ports.tar.gz`. Put the work directory on a filesystem with room for the extracted source and compilation. On systems configured with `PORTS_PRIVSEP=Yes`, its parent must be accessible to the ports build users. The helper applies the framework’s ownership settings inside the new work directory.

```sh
export PKG_PATH=https://cdn.openbsd.org/pub/OpenBSD/8.0/packages/amd64/
archive="$PWD/libremerge-1.6.0-source.tar.gz"
port=$(sh libremerge-1.6.0/packaging/openbsd/prepare-port.sh "$archive" /usr/local/pobj)
cd "$port"
make FETCH_PACKAGES= prepare install-depends
make FETCH_PACKAGES=No package
make lib-depends-check
make show=PKGFILE
```

The first `make` installs build and runtime dependencies from the OpenBSD package mirrors. The second turns off binary fetching for LibreMerge itself and builds the candidate from the supplied archive. The framework stages the installation and checks the packing list. `lib-depends-check` verifies its shared library declarations, and the last command prints the full path to `libremerge-1.6.0.tgz`.

## Build and verify a development candidate

After building the Git checkout using the main README, run the following at the top of that checkout as your regular user. The helper combines the files at the current Git commit with the verified sources from its CMake download directory. Commit any local changes you intend to include in the package before creating this archive.

```sh
sh packaging/openbsd/make-source.sh "$PWD/build/_deps/openbsd-distfiles" "$PWD/out"
```

The port recipe is extracted from this archive when the overlay is prepared. Each candidate gets private distfiles, build objects and package output, so a previous candidate with the same package name cannot satisfy the build. The helper creates the OpenBSD `distinfo` for those exact archive bytes. The independently distributed `SHA256` verifies the archive before this step.

The OpenBSD workflow verifies the documented source update on an existing checkout, builds and installs the application, runs CTest and the application self-tests, then builds the port from the complete archive. A separate job boots the official installer on an empty virtual disk. It tests a fresh package installation and an upgrade from the previous package with `pkg_add -u`. It opens file and folder comparisons in X11, saves a merge, and compares the saved file and its backup with the original fixtures. Successful runs offer the standalone `.tgz` and a bundle containing its corresponding source and checksums. The FreeBSD workflow exercises its own source builds, package installations and upgrades.

For another OpenBSD release or architecture, use that release’s matching base system, ports tree and package set, and verify the resulting binary in a fresh installation. When publishing a changed package for an existing OpenBSD release, update the port’s version or `REVISION` so `pkg_add -u` can recognize the upgrade.
