import re

path = r"D:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/server/Items/ProceduralDistributions.lua"
with open(path, "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

target_tables = [
    # 大工・建築
    "CrateCarpentry", "CrateLumber", "CrateConcrete", "CrateSandBags", "CrateGravelBags",
    # 陶芸・石工
    "CratePottery", "CrateClayBags", "CrateClayBricks", "CrateMasonry",
    # 鍛冶・金属
    "CrateBlacksmithing", "CrateMetalwork", "CrateSheetMetal",
    # 電気・電子
    "CrateElectronics", "CrateBatteries",
    # 動物・農業
    "CrateAnimalFeed", "CrateFarming", "CrateFertilizer",
    # 支援・サバイバル・軍用
    "CrateHumanitarian", "ArmySurplusAmmoBoxes", "CrateCamping",
    # 食品・缶詰・穀物
    "CrateCannedFood", "CrateFlour", "CrateRice", "CratePasta"
]

for t in target_tables:
    m = re.search(r'\n\t' + t + r'\s*=\s*\{([^}]+items\s*=\s*\{[^}]+\}[^}]+)\}', text)
    if not m:
        m = re.search(r'\n\t' + t + r'\s*=\s*\{([^}]+)\}', text)
    if m:
        block = m.group(1)
        rolls_m = re.search(r'rolls\s*=\s*([0-9.]+)', block)
        r_val = rolls_m.group(1) if rolls_m else '?'
        items_m = re.search(r'items\s*=\s*\{([^}]+)\}', block)
        if items_m:
            raw = items_m.group(1).replace('\n', ' ').strip()
            # extract string literals and numbers
            tokens = re.findall(r'\"([^\"]+)\"|([0-9.]+)', raw)
            flat = [t[0] if t[0] else t[1] for t in tokens]
            pairs = []
            for i in range(0, len(flat)-1, 2):
                pairs.append(f"{flat[i]} ({flat[i+1]})")
            print(f"=== {t} (rolls={r_val}, total items={len(pairs)}) ===")
            print("   " + ", ".join(pairs[:6]))
            if len(pairs) > 6:
                print("   ..." + ", ".join(pairs[6:12]))
