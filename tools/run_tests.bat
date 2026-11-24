@echo off
chcp 65001 >nul
rem Chạy kiểm thử của Anh Hùng Đất Việt (Windows).
rem   tools\run_tests.bat          -> K1 (biên dịch) + K2 (máy tự chơi, 15-25 phút)
rem   tools\run_tests.bat nhanh    -> chỉ K1
rem   tools\run_tests.bat run_save -> K1 + tests\run_save_test.tscn
rem Sửa dòng GODOT bên dưới cho đúng nơi bạn để Godot (bản _console.exe).
set GODOT=C:\Godot\Godot_v4.7.2-stable_win64_console.exe
cd /d "%~dp0.."
if not exist logs mkdir logs

echo == K1: kiem tra bien dich
"%GODOT%" --headless --path . res://tests/check_scripts.tscn > logs\k1.txt 2>&1
findstr /C:"XONG: 0 " logs\k1.txt >nul || (echo K1 THAT BAI - xem logs\k1.txt & exit /b 1)
echo K1 OK
if "%1"=="nhanh" exit /b 0
if not "%1"=="" (
  echo == Test rieng: tests\%1_test.tscn
  "%GODOT%" --headless --path . res://tests/%1_test.tscn > logs\%1.txt 2>&1
  findstr /C:" OK" logs\%1.txt >nul || (echo TEST %1 THAT BAI - xem logs\%1.txt & exit /b 1)
  echo TEST %1 OK
  exit /b 0
)
echo == K2: may tu choi (15-25 phut)...
"%GODOT%" --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn > logs\smoke.txt 2>&1
findstr /C:"SMOKE TEST OK" logs\smoke.txt >nul || (echo K2 THAT BAI - xem logs\smoke.txt & exit /b 1)
echo TAT CA DAT
