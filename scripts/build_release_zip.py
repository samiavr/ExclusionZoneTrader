import os
import zipfile
import hashlib

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
SOURCE_DIR = os.path.join(REPO_ROOT, "RadioTraderMod")
DIST_DIR = os.path.join(REPO_ROOT, "dist")
VERSION = "v1.0.0"
ZIP_NAME = f"ExclusionZoneTrader_{VERSION}.zip"
ZIP_PATH = os.path.join(DIST_DIR, ZIP_NAME)

EXCLUDE_EXTS = {".tmp", ".bak", ".pyc"}
EXCLUDE_NAMES = {".DS_Store", "Thumbs.db", "desktop.ini"}

def build_zip():
    os.makedirs(DIST_DIR, exist_ok=True)
    print(f"Building release zip: {ZIP_PATH}")
    print(f"Source: {SOURCE_DIR}")

    with zipfile.ZipFile(ZIP_PATH, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(SOURCE_DIR):
            for file in files:
                ext = os.path.splitext(file)[1].lower()
                if ext in EXCLUDE_EXTS or file in EXCLUDE_NAMES:
                    continue
                
                full_path = os.path.join(root, file)
                # Archive name starts with 'RadioTraderMod/...'
                rel_path = os.path.relpath(full_path, REPO_ROOT)
                zf.write(full_path, rel_path)
                print(f"  + {rel_path}")

    size_mb = os.path.getsize(ZIP_PATH) / (1024 * 1024)
    print(f"\n[SUCCESS] Archive created: {ZIP_PATH} ({size_mb:.2f} MB)")

    # Compute SHA256
    sha256 = hashlib.sha256()
    with open(ZIP_PATH, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha256.update(chunk)
    print(f"SHA-256: {sha256.hexdigest()}")

if __name__ == "__main__":
    build_zip()
