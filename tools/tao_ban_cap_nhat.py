"""Công cụ tạo gói vá tự động cập nhật (.pck + version.json) trong 1 lệnh.

Ví dụ:
    python tools/tao_ban_cap_nhat.py --version 1.2.1 --build 121 --notes "Sửa lỗi & cân bằng tướng"
    python tools/tao_ban_cap_nhat.py   (dùng nguyên phiên bản đang ghi trong scripts/data/version.gd)
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_GD = os.path.join(ROOT, "scripts", "data", "version.gd")
GODOT_EXE = r"D:\Games\Godot\Godot_v4.7.2-stable_win64_console.exe"
PCK_OUT = os.path.join(ROOT, "build", "AnhHungDatViet.pck")
PATCH_DIR = os.path.join(ROOT, "build", "release_patch")


def read_version_gd():
    with open(VERSION_GD, "r", encoding="utf-8") as f:
        txt = f.read()
    ver = re.search(r'const VERSION := "([^"]+)"', txt).group(1)
    bld = int(re.search(r"const BUILD := (\d+)", txt).group(1))
    min_eng = re.search(r'const MIN_ENGINE := "([^"]+)"', txt).group(1)
    repo = re.search(r'const REPO := "([^"]+)"', txt).group(1)
    return txt, ver, bld, min_eng, repo


def update_version_gd(txt, new_ver, new_build):
    txt = re.sub(r'const VERSION := "[^"]+"', f'const VERSION := "{new_ver}"', txt)
    txt = re.sub(r"const BUILD := \d+", f"const BUILD := {new_build}", txt)
    with open(VERSION_GD, "w", encoding="utf-8", newline="\n") as f:
        f.write(txt)


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(65536)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest().lower()


def main():
    ap = argparse.ArgumentParser(description="Đóng gói bản vá .pck và version.json cho GitHub Releases.")
    ap.add_argument("--version", help="Số phiên bản mới (vd: 1.2.1)")
    ap.add_argument("--build", type=int, help="Số build tăng dần (vd: 121)")
    ap.add_argument("--notes", default="Cập nhật mới nhất cho Anh Hùng Đất Việt.", help="Ghi chú thay đổi")
    ap.add_argument("--skip-export", action="store_true", help="Dùng build/AnhHungDatViet.pck hiện có, không gọi Godot xuất lại")
    args = ap.parse_args()

    txt, cur_ver, cur_build, min_eng, repo = read_version_gd()
    ver = args.version or cur_ver
    bld = args.build if args.build is not None else cur_build
    if args.version or args.build is not None:
        update_version_gd(txt, ver, bld)
        print(f"Đã cập nhật scripts/data/version.gd -> v{ver} (build {bld})")

    if not args.skip_export:
        if not os.path.exists(GODOT_EXE):
            print(f"LỖI: Không tìm thấy Godot tại {GODOT_EXE}", file=sys.stderr)
            sys.exit(1)
        os.makedirs(os.path.dirname(PCK_OUT), exist_ok=True)
        cmd = [GODOT_EXE, "--headless", "--path", ROOT, "--export-pack", "Windows Desktop", "build/AnhHungDatViet.pck"]
        res = subprocess.run(cmd, cwd=ROOT)
        if res.returncode != 0:
            print("LỖI: Godot export-pack thất bại!", file=sys.stderr)
            sys.exit(res.returncode)

    if not os.path.exists(PCK_OUT):
        print(f"LỖI: Không thấy tệp {PCK_OUT}", file=sys.stderr)
        sys.exit(1)

    digest = sha256_file(PCK_OUT)
    size_bytes = os.path.getsize(PCK_OUT)
    os.makedirs(PATCH_DIR, exist_ok=True)
    shutil.copy2(PCK_OUT, os.path.join(PATCH_DIR, "AnhHungDatViet.pck"))

    manifest = {
        "version": ver,
        "build": bld,
        "min_engine": min_eng,
        "size_bytes": size_bytes,
        "sha256": digest,
        "pck_url": f"https://github.com/{repo}/releases/latest/download/AnhHungDatViet.pck",
        "release_url": f"https://github.com/{repo}/releases/latest",
        "notes": args.notes,
    }
    with open(os.path.join(PATCH_DIR, "version.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"XONG! Gói vá v{ver} (build {bld}) đã sẵn sàng tại: {PATCH_DIR}")
    print(f"  - AnhHungDatViet.pck ({size_bytes / 1048576.0:.2f} MB, sha256={digest[:16]}...)")
    print("  - version.json")
    print(f"Bước cuối: kéo thả cả 2 tệp trên vào Release mới tại https://github.com/{repo}/releases/new")


if __name__ == "__main__":
    main()
