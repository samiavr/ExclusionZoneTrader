import re

path = r"D:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/server/Items/ProceduralDistributions.lua"
with open(path, "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

keys = re.findall(r'\n\t([A-Za-z0-9_]+)\s*=\s*\{', text)
tailor_tables = [k for k in keys if any(x in k.lower() for x in ['tailor', 'fabric', 'sewing', 'textile', 'leather'])]
print('Tailoring/Fabric tables:', tailor_tables)

for t in tailor_tables:
    m = re.search(r'\n\t' + t + r'\s*=\s*\{([^}]+items\s*=\s*\{[^}]+\}[^}]+)\}', text)
    if m:
        block = m.group(1)
        items_m = re.search(r'items\s*=\s*\{([^}]+)\}', block)
        if items_m:
            raw = items_m.group(1).replace('\n', ' ').strip()
            tokens = re.findall(r'\"([^\"]+)\"|([0-9.]+)', raw)
            flat = [x[0] if x[0] else x[1] for x in tokens]
            pairs = []
            for i in range(0, len(flat)-1, 2):
                pairs.append(f"{flat[i]} ({flat[i+1]})")
            print(f"=== {t} ===")
            print("  " + ", ".join(pairs[:8]))
