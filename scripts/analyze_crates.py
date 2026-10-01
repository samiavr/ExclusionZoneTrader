import re

path = r"D:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/server/Items/ProceduralDistributions.lua"
with open(path, "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

# Match all top-level keys inside ProceduralDistributions.list
keys = re.findall(r'\n\t([A-Za-z0-9_]+)\s*=\s*\{', text)
print(f"Total procedural tables found: {len(keys)}")

# Let's inspect keywords
def find_keys(patterns, exclude=[]):
    res = []
    for k in keys:
        lk = k.lower()
        if any(p.lower() in lk for p in patterns):
            if not any(e.lower() in lk for e in exclude):
                res.append(k)
    return sorted(res)

print("\n--- Gun / Weapon / Ammo Tables ---")
guns = find_keys(["Gun", "Ammo", "Firearm", "Pistol", "Rifle", "Shotgun", "Weapon"])
print(f"Found {len(guns)}: {guns[:20]}")

print("\n--- Medical / Pharmacy / Hospital Tables ---")
meds = find_keys(["Med", "Pharma", "Hospital", "Clinic", "Doctor", "FirstAid", "Ambulance"])
print(f"Found {len(meds)}: {meds[:20]}")

print("\n--- Vehicle / Mechanic Tables ---")
vehs = find_keys(["CarSupply", "Mechanic", "Auto", "Vehicle"])
print(f"Found {len(vehs)}: {vehs[:20]}")

print("\n--- Carpentry / Tools / Hardware Tables ---")
tools = find_keys(["Tool", "Carpenter", "Logging", "ConstructionWorker", "Hardware"])
print(f"Found {len(tools)}: {tools[:20]}")

print("\n--- Metal / Welding Tables ---")
metal = find_keys(["Weld", "Metal", "Blacksmith"])
print(f"Found {len(metal)}: {metal[:20]}")

print("\n--- Food / Grocery / Kitchen Tables ---")
food = find_keys(["Gigamart", "Kitchen", "Grocery", "Bakery", "Butcher", "Food", "Canned"])
print(f"Found {len(food)}: {food[:20]}")

print("\n--- Clothing / Outfit / Wardrobe Tables ---")
clothes = find_keys(["Outfit", "Wardrobe", "ClosetClothes", "Clothing", "Dresser"])
print(f"Found {len(clothes)}: {clothes[:20]}")
