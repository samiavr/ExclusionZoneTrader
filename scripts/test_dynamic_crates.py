import re

path = r"D:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/server/Items/ProceduralDistributions.lua"
with open(path, "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

# match all Crate keys
all_crates = sorted(list(set(re.findall(r'\b(Crate[A-Za-z0-9_]+)\b', text))))

def test_category(cat):
    matched = []
    if cat == "Sports":
        for k in all_crates:
            lk = k.lower()
            if any(w in lk for w in ["sport", "baseball", "basketball", "golf", "soccer", "football", "fitness", "tennis", "gym"]):
                matched.append(k)
    elif cat == "Welding":
        for k in all_crates:
            lk = k.lower()
            if any(w in lk for w in ["metal", "weld", "pipe", "sheetmetal", "blacksmith", "chains"]):
                if "locker" not in lk:
                    matched.append(k)
    elif cat == "Carpentry":
        for k in all_crates:
            lk = k.lower()
            if any(w in lk for w in ["tool", "carpentry", "lumber", "concrete", "plaster", "paint", "clay", "masonry", "sandbag", "gravel"]):
                if "chair" not in lk and "stool" not in lk:
                    matched.append(k)
    elif cat == "Food":
        food_words = ["food", "canned", "cereal", "chips", "candy", "chocolate", "beer", "soda", "wine",
                      "coffee", "tea", "buns", "butter", "flour", "rice", "pasta", "sugar", "oil",
                      "sauce", "crackers", "macaroni", "popcorn", "marinara", "marshmallows", "yeast",
                      "condiments", "peanuts", "graham", "cocoa", "baking"]
        exclude_words = ["spoiled", "animal", "feed", "toilet", "table", "chair", "sink", "oven", "stove"]
        for k in all_crates:
            lk = k.lower()
            if any(fw in lk for fw in food_words):
                if not any(ew in lk for ew in exclude_words):
                    matched.append(k)
    return matched

for cat in ["Sports", "Welding", "Carpentry", "Food"]:
    res = test_category(cat)
    print(f"=== {cat} ({len(res)}) ===")
    print(", ".join(res))
