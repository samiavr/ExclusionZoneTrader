import os
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
SOURCE_42 = os.path.join(REPO_ROOT, "RadioTraderMod", "42")

# Note: C:\Users\samia\Zomboid\mods\RadioTraderMod is already a junction to RadioTraderMod!
# Therefore, do NOT sync to Zomboid/mods directory directly.
TARGET_DIRS = [
    os.path.join(REPO_ROOT, "mod", "42"),
    os.path.join(REPO_ROOT, "RadioTraderMod_B42", "42"),
    os.path.join(REPO_ROOT, "RadioTraderMod_B42", "42.0"),
]

print(f"=== Syncing from {SOURCE_42} ===")
for target in TARGET_DIRS:
    if os.path.exists(os.path.dirname(target)):
        print(f"Syncing to -> {target}")
        if os.path.exists(target):
            shutil.rmtree(target)
        shutil.copytree(SOURCE_42, target)
        print("  -> OK")
    else:
        print(f"Skipping (parent does not exist) -> {target}")

print("=== All Sync Completed ===")
