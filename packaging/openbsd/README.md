# Building the OpenBSD port

LibreMerge’s local port builds an ordinary OpenBSD package with `bsd.port.mk`. The first target is **OpenBSD 8.0, amd64**. The recipe lives in this fork. For installation from a package or from a Git checkout, see the [user instructions](../../README.md#install-from-an-openbsd-package).

## Build from the complete source archive

The package downloads include `libremerge-1.5.0-source.tar.gz` and `SHA256`. The archive contains the source used to build the package, the port recipe, and the pinned copies of Poco Foundation, SQLite Lemon, and the syntax grammars. Save both files in the same directory. With the source-build dependencies listed in the main README installed, run the following as a regular user.

```sh
sha256 -C SHA256 libremerge-1.5.0-source.tar.gz
tar -xzf libremerge-1.5.0-source.tar.gz
cd libremerge-1.5.0
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DLM_OPENBSD_DISTFILES="$PWD/distfiles" -DFETCHCONTENT_FULLY_DISCONNECTED=ON
cmake --build build --parallel 2
ctest --test-dir build --output-on-failure
```

The build can run offline after its system dependencies are installed. To install the result, run `su root -c 'cmake --install build'` from this directory.

## Produce the binary package

Use the ports tree that matches the OpenBSD release. If `/usr/ports` is already populated with the 8.0 release tree, proceed to the packaging commands below. To install the release tree on a fresh 8.0 machine, fetch and verify it as a regular user, then extract it as root.

```sh
mkdir -p ~/ports-download && cd ~/ports-download
ftp -o ports.tar.gz https://cdn.openbsd.org/pub/OpenBSD/8.0/ports.tar.gz
ftp -o SHA256.sig https://cdn.openbsd.org/pub/OpenBSD/8.0/SHA256.sig
signify -C -p /etc/signify/openbsd-80-base.pub -x SHA256.sig ports.tar.gz
su root -c 'tar -C /usr -xzf ports.tar.gz'
```

In a root shell, start in the directory containing the verified LibreMerge source archive and its unpacked `libremerge-1.5.0` directory. Put the work directory on a filesystem with room for the extracted source and compilation. The helper prints the path of a new private overlay. The release ports tree remains available to resolve dependencies.

```sh
archive="$PWD/libremerge-1.5.0-source.tar.gz"
port=$(sh libremerge-1.5.0/packaging/openbsd/prepare-port.sh "$archive" /usr/local/pobj)
cd "$port"
make FETCH_PACKAGES= package
make show=PKGFILE
```

The last command prints the full path to `libremerge-1.5.0.tgz`. The framework stages the installation, checks the packing list and shared libraries, and creates the package. `FETCH_PACKAGES=` allows it to install dependencies from the OpenBSD package mirrors. The candidate itself is built locally.

## Build and verify a development candidate

After building the Git checkout using the main README, run the following at the top of that checkout as your regular user. The helper combines the tracked commit with the verified sources from its CMake download directory and writes the complete source archive to the output directory.

```sh
sh packaging/openbsd/make-source.sh "$PWD/build/_deps/openbsd-distfiles" "$PWD/out"
```

The port recipe is extracted from this archive when the overlay is prepared. Each candidate gets private distfiles, build objects and package output, so a previous candidate with the same package name cannot satisfy the build. The helper creates the OpenBSD `distinfo` for those exact archive bytes. The independently distributed `SHA256` verifies the archive before this step.

The OpenBSD workflow builds and installs the documented checkout, runs CTest and the application self-tests, then builds the port from the complete archive. A separate job boots the official installer on an empty virtual disk. Only the package, checksum and test scripts are copied to that installation. It runs `pkg_add` and opens file and folder comparisons in X11, saves a merge, and compares the saved file and its backup with the original fixtures. Successful runs offer the standalone `.tgz` and a bundle containing its corresponding source and checksums. The FreeBSD workflow continues to exercise its own source, binary installations and upgrades.

For another OpenBSD release or architecture, use that release’s matching base system, ports tree and package set, and verify the resulting binary in a fresh installation. When publishing a changed package for an existing OpenBSD release, update the port’s version or `REVISION` so `pkg_add -u` can recognize the upgrade.
