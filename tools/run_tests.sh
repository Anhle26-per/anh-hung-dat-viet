#!/usr/bin/env bash
# Chạy kiểm thử của Anh Hùng Đất Việt (Linux / macOS).
#   bash tools/run_tests.sh          -> K1 (biên dịch) + K2 (máy tự chơi, 15-25 phút)
#   bash tools/run_tests.sh nhanh    -> chỉ K1
#   bash tools/run_tests.sh <ten>    -> K1 + tests/<ten>_test.tscn (ví dụ: run_save, lan)
# Đổi đường dẫn Godot: GODOT=/duong/dan/godot bash tools/run_tests.sh
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mkdir -p logs

echo "== K1: kiểm tra biên dịch"
"$GODOT" --headless --path . res://tests/check_scripts.tscn > logs/k1.txt 2>&1
tail -n 3 logs/k1.txt
if ! grep -q "KIỂM TRA XONG: 0 lỗi" logs/k1.txt; then
  echo "K1 THẤT BẠI (xem logs/k1.txt)"; exit 1
fi

case "${1:-}" in
  nhanh) echo "K1 OK"; exit 0 ;;
  "") ;;
  *)
    echo "== Test riêng: tests/${1}_test.tscn"
    "$GODOT" --headless --path . "res://tests/${1}_test.tscn" > "logs/${1}.txt" 2>&1
    tail -n 5 "logs/${1}.txt"
    grep -q " OK" "logs/${1}.txt" || { echo "TEST ${1} THẤT BẠI (xem logs/${1}.txt)"; exit 1; }
    exit 0 ;;
esac

echo "== K2: máy tự chơi (15-25 phút)..."
"$GODOT" --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn > logs/smoke.txt 2>&1
grep -E "==|gánh|trùm|Tam Yêu|THẤT BẠI|SCRIPT ERROR|SMOKE" logs/smoke.txt | tail -n 25
grep -q "SMOKE TEST OK" logs/smoke.txt || { echo "K2 THẤT BẠI (xem logs/smoke.txt)"; exit 1; }
echo "TẤT CẢ ĐẠT"
