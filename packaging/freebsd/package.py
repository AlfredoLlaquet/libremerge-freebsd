#!/usr/bin/env python3
# LM4BSD BEGIN ADDITION — Stage a FreeBSD Release build as a native pkg archive.
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def create_package(build, version, destination):
    abi = output("pkg", "config", "ABI")
    source = Path.cwd()
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        stage = work / "stage"
        subprocess.run(["cmake", "--install", build, "--strip"], check=True,
                       env={**os.environ, "DESTDIR": str(stage)})
        prefix = stage / "usr/local"
        exe = prefix / "bin/libremerge"
        if not exe.is_file():
            raise SystemExit("The build did not install the Qt application")
        licenses = prefix / "share/licenses/libremerge"
        licenses.mkdir(parents=True)
        for original, name in (("LICENSE", "LICENSE"), ("docs/VENDORED.md", "VENDORED.md"),
                               ("engine/Externals/xdiff/COPYING", "xdiff-COPYING")):
            shutil.copyfile(source / original, licenses / name)

        # Qt also loads its image formats, SVG support and translations at runtime.
        runtime = {"qt6-base", "qt6-imageformats", "qt6-svg", "qt6-translations", "poco", "icu"}
        # libarchive can come from the base system or the ports tree.
        for line in output("ldd", exe).splitlines():
            fields = line.split()
            if len(fields) >= 3 and fields[0].startswith("libarchive.so") and fields[2].startswith("/usr/local/"):
                runtime.add(output("pkg", "which", "-qo", fields[2]))
        deps = {}
        for package in sorted(runtime):
            name, origin, installed = output("pkg", "query", "%n %o %v", package).split()
            deps[name] = {"origin": origin, "version": installed}

        files = {}
        for path in sorted(prefix.rglob("*")):
            if path.is_file() or path.is_symlink():
                files["/" + str(path.relative_to(stage))] = {
                    "uname": "root", "gname": "wheel",
                    "perm": format(stat.S_IMODE(path.lstat().st_mode), "04o"),
                }
        manifest = {
            "name": "libremerge", "version": version, "origin": "textproc/libremerge",
            "prefix": "/usr/local", "abi": abi, "categories": ["textproc"],
            "comment": "Graphical file and folder comparison and merging",
            "desc": "Native FreeBSD port of the Qt LibreMerge application with the WinMerge comparison engine.",
            "maintainer": "AlfredoLlaquet@users.noreply.github.com",
            "www": "https://github.com/AlfredoLlaquet/libremerge-freebsd",
            "licenses": ["GPLv3+"], "licenselogic": "single", "deps": deps, "files": files,
        }
        spec = work / "manifest.json"
        spec.write_text(json.dumps(manifest), encoding="utf-8")
        subprocess.run(["pkg", "create", "-M", spec, "-r", stage, "-o", work], check=True)
        filename = f"libremerge-{version}"
        shutil.move(work / f"{filename}.pkg", destination / f"{filename}-{abi.replace(':', '-')}.pkg")


if __name__ == "__main__":
    build, version, dest = sys.argv[1:]
    create_package(Path(build).resolve(), version, Path(dest).resolve())
# LM4BSD END
