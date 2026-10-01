import math

def test_spawn_safety():
    min_player_dist = 45
    min_dist_sq = min_player_dist * min_player_dist

    # プレイヤーが (1000, 1000) にいると仮定
    players = [{"x": 1000, "y": 1000}]

    # ケース1: プレイヤーから30タイル離れた位置 (1030, 1000) -> 拒絶されるべき
    sq1 = {"x": 1030, "y": 1000}
    dist_sq_1 = (sq1["x"] - players[0]["x"])**2 + (sq1["y"] - players[0]["y"])**2
    assert dist_sq_1 < min_dist_sq, f"sq1 should be inside safety zone: {dist_sq_1} < {min_dist_sq}"

    # ケース2: プレイヤーから45タイル離れた位置 (1045, 1000) -> 許可境界
    sq2 = {"x": 1045, "y": 1000}
    dist_sq_2 = (sq2["x"] - players[0]["x"])**2 + (sq2["y"] - players[0]["y"])**2
    assert dist_sq_2 >= min_dist_sq, f"sq2 should be outside safety zone: {dist_sq_2} >= {min_dist_sq}"

    # ケース3: プレイヤーから50タイル離れた位置 (1035, 1036) -> 許可
    sq3 = {"x": 1035, "y": 1036}
    dist_sq_3 = (sq3["x"] - players[0]["x"])**2 + (sq3["y"] - players[0]["y"])**2
    dist_3 = math.sqrt(dist_sq_3)
    assert dist_3 >= 45, f"sq3 dist {dist_3} should be >= 45"

    # マルチプレイヤーケース: Player A (1000, 1000), Player B (1050, 1050)
    players_mp = [{"x": 1000, "y": 1000}, {"x": 1050, "y": 1050}]
    # 候補地 (1046, 1000): Player Aからは46タイル離れているが、Player Bから (1046-1050)^2 + (1000-1050)^2 = 16 + 2500 = 2516 (dist 50.15) -> 許可
    # 候補地 (1040, 1040): Player Aから (40)^2+(40)^2 = 3200 (dist 56.5) だが Player Bから (10)^2+(10)^2 = 200 (dist 14.1) -> 拒絶されるべき！
    sq_mid = {"x": 1040, "y": 1040}
    rejected = False
    for p in players_mp:
        d2 = (sq_mid["x"] - p["x"])**2 + (sq_mid["y"] - p["y"])**2
        if d2 < min_dist_sq:
            rejected = True
            break
    assert rejected, "sq_mid must be rejected because it is close to Player B!"

    print("ALL SPAWN SAFETY TESTS PASSED!")

if __name__ == "__main__":
    test_spawn_safety()
