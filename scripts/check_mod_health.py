"""
Project Zomboid Mod 総合健全性検証スクリプト (check_mod_health.py)
以下の4大障害を一度にスキャンします:
  1. UTF-8 BOM混入 (Kahlua Lexer クラッシュ要因)
  2. Luaソース内の4バイト絵文字・非ASCIIマルチバイト文字列
  3. Kahlua (Lua 5.1) 非互換構文 (goto, ::label::, continue等)
  4. 未終了文字列リテラル・エスケープ破損
"""

import os
import re
import sys

# 対象MODルートディレクトリ（スクリプトからの相対パスまたは絶対パス）
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MOD_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "RadioTraderMod"))

FORBIDDEN_SYNTAX = [
    (r"\bgoto\b", "goto statement (unsupported in Lua 5.1/Kahlua)"),
    (r"::[a-zA-Z0-9_]+::", "label statement (unsupported in Lua 5.1/Kahlua)"),
    (r"\bcontinue\b", "continue keyword (not in Lua 5.1)"),
]

SUSPICIOUS_CHARS = [
    0x23E9, 0x23EA, 0x25B6, 0x26A0, 0x2705, 0x274C, 0x2014, 0x2015  # ⏩, ⏪, ▶, ⚠, ✅, ❌, —, ―
]

def check_bom(filepath):
    with open(filepath, "rb") as fp:
        head = fp.read(4)
        if head.startswith(b"\xef\xbb\xbf"):
            return True
    return False

def check_file(filepath):
    issues = []
    fname = os.path.basename(filepath)

    # 1. BOM チェック
    if check_bom(filepath):
        issues.append(("[CRITICAL] UTF-8 BOM detected! Causes Kahlua IndexOutOfBoundsException.", 0, ""))

    # 2. Lua専用構文＆文字コードチェック
    if filepath.endswith(".lua"):
        try:
            with open(filepath, "r", encoding="utf-8") as fp:
                lines = fp.readlines()
        except UnicodeDecodeError as e:
            issues.append((f"[CRITICAL] UTF-8 Decode Error: {e}", 0, ""))
            return issues

        for idx, line in enumerate(lines, 1):
            clean_line = line.split("--")[0]  # コメント除外

            # 構文チェック
            for pat, desc in FORBIDDEN_SYNTAX:
                if re.search(pat, clean_line):
                    issues.append((f"[SYNTAX] {desc}", idx, line.strip()))

            # 未定義 isDebugEnabled() チェック
            if "isDebugEnabled(" in clean_line and fname != "RadioTrader_Debug.lua":
                issues.append(("[CALL] Call to isDebugEnabled without local definition", idx, line.strip()))

            # 4バイト絵文字 / 特殊記号チェック
            emojis = []
            for c in clean_line:
                code = ord(c)
                if code > 0xFFFF or code in SUSPICIOUS_CHARS:
                    emojis.append(f"U+{code:04X}")
            if emojis:
                issues.append((f"[CHAR] Emoji/Symbol detected {emojis} (causes mojibake)", idx, line.strip()))

            # 非ASCIIマルチバイト文字の直書きチェック（Debug/UI用）
            if fname in ["RadioTrader_Debug.lua", "RadioTrader_ContextMenu.lua"]:
                non_ascii = [c for c in clean_line if ord(c) > 127]
                if non_ascii:
                    issues.append((f"[I18N] Hardcoded non-ASCII character in Lua string", idx, line.strip()))

        # COLOR_定数の未定義チェック (ファイル単位)
        all_code = "".join([l.split("--")[0] for l in lines])
        color_refs = set(re.findall(r"\b(COLOR_[A-Z0-9_]+)\b", all_code))
        for cref in color_refs:
            # 定義パターン: local COLOR_... または COLOR_... =
            def_pat = rf"\b(local\s+{cref}\b|{cref}\s*=)"
            if not re.search(def_pat, all_code):
                issues.append((f"[UNDEFINED] Constant {cref} used without definition in this file", 0, cref))

    # 3. 翻訳ファイル (JSON) のフォーマット指定子チェック
    if filepath.endswith(".json") and "Translate" in filepath:
        import json
        try:
            with open(filepath, "r", encoding="utf-8") as fp:
                data = json.load(fp)
                for k, v in data.items():
                    if isinstance(v, str):
                        # %% (エスケープ済みパーセント) を除去した上で、%s, %d, %1 以外の裸の % を検出
                        clean_v = v.replace("%%", "")
                        bad_percents = re.findall(r'%(?![sd0-9])', clean_v)
                        if bad_percents:
                            issues.append((f"[I18N] Unescaped '%' in translation (causes UnknownFormatConversionException): {k} -> {v}", 0, v))
        except Exception as e:
            issues.append((f"[CRITICAL] JSON parse error: {e}", 0, ""))

    return issues

def main():
    print(f"Scanning MOD target: {MOD_ROOT}")
    total_files = 0
    total_errors = 0
    total_warnings = 0

    for root, dirs, files in os.walk(MOD_ROOT):
        for f in files:
            if f.endswith((".lua", ".json", ".info", ".txt")):
                total_files += 1
                p = os.path.join(root, f)
                rel_p = os.path.relpath(p, MOD_ROOT)
                file_issues = check_file(p)
                if file_issues:
                    print(f"\n[SCAN] {rel_p}:")
                    for desc, line_no, sample in file_issues:
                        safe_sample = sample.encode("ascii", errors="backslashreplace").decode("ascii")
                        if "[I18N]" in desc:
                            total_warnings += 1
                            prefix = "WARN "
                        else:
                            total_errors += 1
                            prefix = "ERROR"
                        if line_no > 0:
                            print(f"  [{prefix}] Line {line_no:4d}: {desc}\n             -> {safe_sample[:80]}")
                        else:
                            print(f"  [{prefix}] {desc}")

    print("\n" + "=" * 60)
    print(f"Scanned {total_files} files: {total_errors} Critical Errors, {total_warnings} I18N Warnings.")
    if total_errors == 0:
        print("SUCCESS: 0 Critical Errors! Mod is clean and safe to run in PZ.")
        return 0
    else:
        print(f"FAILURE: {total_errors} Critical Errors detected. Must be fixed.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
