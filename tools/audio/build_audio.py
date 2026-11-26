"""Sinh toàn bộ hiệu ứng âm thanh (8-bit) và nhạc nền (ngũ cung Việt Nam) cho Anh Hùng Đất Việt.

Chỉ dùng thư viện chuẩn Python (wave, struct, math, random, os).
Xuất tệp .wav mono 16-bit 22050 Hz vào assets/audio/sfx/ và assets/audio/music/.
Chạy trên Windows: python tools/audio/build_audio.py (hoặc py tools/audio/build_audio.py).
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 22050
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SFX_DIR = os.path.join(ROOT_DIR, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT_DIR, "assets", "audio", "music")

# Thang ngũ cung Việt Nam (Đô - Rê - Mi - Son - La) qua nhiều quãng tám
PENTA = {
    "C3": 130.81, "D3": 146.83, "E3": 164.81, "G3": 196.00, "A3": 220.00,
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "G4": 392.00, "A4": 440.00,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99, "A5": 880.00,
    "C6": 1046.50, "D6": 1174.66, "E6": 1318.51, "G6": 1567.98, "A6": 1760.00,
}


def save_wav(path: str, samples: list[float], peak: float = 0.85) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    max_abs = max((abs(x) for x in samples), default=0.0)
    scale = (peak / max_abs) if max_abs > 1e-6 else 1.0
    if max_abs > 0.0 and max_abs < peak and max_abs < 0.25:
        scale = peak / max_abs
    elif max_abs <= peak:
        scale = 1.0
    frames = bytearray()
    for x in samples:
        v = max(-1.0, min(1.0, x * scale))
        frames.extend(struct.pack("<h", int(round(v * 32767.0))))
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(bytes(frames))


def normalize(samples: list[float], target_peak: float = 0.78) -> list[float]:
    m = max((abs(x) for x in samples), default=0.0)
    if m < 1e-6:
        return samples
    k = target_peak / m
    return [x * k for x in samples]


def square(phase: float, duty: float = 0.5) -> float:
    return 1.0 if (phase % 1.0) < duty else -1.0


def triangle(phase: float) -> float:
    p = phase % 1.0
    return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p


def env_ad(t: float, dur: float, attack: float = 0.005, exp: float = 1.8) -> float:
    if t < 0.0 or t >= dur:
        return 0.0
    if t < attack and attack > 0.0:
        return t / attack
    rem = (dur - t) / max(dur - attack, 1e-6)
    return max(0.0, rem) ** exp


def env_asr(t: float, dur: float, attack: float = 0.03, release: float = 0.06) -> float:
    if t < 0.0 or t >= dur:
        return 0.0
    if t < attack and attack > 0.0:
        return t / attack
    if t > dur - release and release > 0.0:
        return max(0.0, (dur - t) / release)
    return 1.0


def add_tone_seq(buf: list[float], notes: list[tuple[float, float, str, float]], vol: float = 0.5) -> None:
    """Chèn chuỗi nốt 8-bit: (start_s, dur_s, wave_kind, freq_hz)."""
    for start_s, dur_s, kind, freq in notes:
        i0 = int(start_s * SAMPLE_RATE)
        n = int(dur_s * SAMPLE_RATE)
        phase = 0.0
        for j in range(n):
            idx = i0 + j
            if idx >= len(buf):
                break
            t = j / SAMPLE_RATE
            phase += freq / SAMPLE_RATE
            if kind == "sq":
                w = square(phase, 0.5)
            elif kind == "sq25":
                w = square(phase, 0.25)
            elif kind == "tri":
                w = triangle(phase)
            else:
                w = math.sin(2.0 * math.pi * phase)
            buf[idx] += w * env_ad(t, dur_s, 0.004, 1.4) * vol


def gen_sfx() -> dict[str, list[float]]:
    out: dict[str, list[float]] = {}

    # 1. slash: nhát chém cận chiến (vút gió + lóe kim khí)
    rng = random.Random(101)
    n = int(0.14 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 720.0 * (0.22 ** (t / 0.14))
        ph += f / SAMPLE_RATE
        noise = rng.uniform(-1.0, 1.0)
        lp = lp * 0.55 + noise * 0.45
        e = env_ad(t, 0.14, 0.004, 1.7)
        buf.append((0.65 * lp + 0.35 * triangle(ph)) * e)
    out["slash"] = normalize(buf, 0.8)

    # 2. arrow: bắn tên / cung nỏ (bật dây + tiếng vút)
    rng = random.Random(102)
    n = int(0.16 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 920.0 * (0.35 ** (t / 0.16)) + 120.0
        ph += f / SAMPLE_RATE
        e = env_ad(t, 0.16, 0.003, 2.1)
        w = 0.65 * triangle(ph) + 0.35 * rng.uniform(-1.0, 1.0) * max(0.0, 1.0 - t / 0.06)
        buf.append(w * e)
    out["arrow"] = normalize(buf, 0.78)

    # 3. shoot: bắn súng / đạn 8-bit
    rng = random.Random(103)
    n = int(0.15 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 660.0 * (0.14 ** (t / 0.15)) + 75.0
        ph += f / SAMPLE_RATE
        crack = rng.uniform(-1.0, 1.0) * (1.0 if t < 0.035 else 0.25)
        e = env_ad(t, 0.15, 0.002, 1.9)
        buf.append((0.55 * square(ph, 0.35) + 0.45 * crack) * e)
    out["shoot"] = normalize(buf, 0.82)

    # 4. explode: nổ (bass tụt sâu + nhiễu ầm)
    rng = random.Random(104)
    n = int(0.48 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 150.0 * (0.22 ** (t / 0.48)) + 32.0
        ph += f / SAMPLE_RATE
        lp = lp * 0.78 + rng.uniform(-1.0, 1.0) * 0.22
        e = env_ad(t, 0.48, 0.004, 1.6)
        buf.append((0.6 * math.sin(2.0 * math.pi * ph) + 0.75 * lp) * e)
    out["explode"] = normalize(buf, 0.88)

    # 5. player_hurt: người chơi trúng đòn
    rng = random.Random(105)
    n = int(0.22 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 280.0 - 150.0 * (t / 0.22)
        ph += f / SAMPLE_RATE
        e = env_ad(t, 0.22, 0.003, 1.3)
        buf.append((0.7 * square(ph, 0.25) + 0.25 * rng.uniform(-1.0, 1.0)) * e)
    out["player_hurt"] = normalize(buf, 0.82)

    # 6. enemy_hurt: giặc trúng đòn (gọn, nảy)
    n = int(0.09 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 420.0 * (0.45 ** (t / 0.09))
        ph += f / SAMPLE_RATE
        buf.append(square(ph, 0.5) * env_ad(t, 0.09, 0.002, 1.6))
    out["enemy_hurt"] = normalize(buf, 0.7)

    # 7. enemy_die: giặc gục (tụt cao độ + phập)
    rng = random.Random(107)
    n = int(0.22 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 360.0 * (0.2 ** (t / 0.22)) + 50.0
        ph += f / SAMPLE_RATE
        e = env_ad(t, 0.22, 0.003, 1.6)
        buf.append((0.65 * square(ph, 0.5) + 0.35 * rng.uniform(-1.0, 1.0)) * e)
    out["enemy_die"] = normalize(buf, 0.76)

    # 8. coin: nhặt xu (A5 -> E6 sáng kiểu 8-bit)
    buf = [0.0] * int(0.19 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.065, "sq25", PENTA["A5"]), (0.055, 0.13, "sq25", PENTA["E6"])], 0.55)
    out["coin"] = normalize(buf, 0.72)

    # 9. pickup_weapon: nhặt vũ khí / hồ lô (C5 -> E5 -> G5)
    buf = [0.0] * int(0.28 * SAMPLE_RATE)
    add_tone_seq(
        buf,
        [(0.0, 0.08, "sq", PENTA["C5"]), (0.075, 0.08, "sq", PENTA["E5"]), (0.15, 0.13, "sq", PENTA["G5"])],
        0.5,
    )
    out["pickup_weapon"] = normalize(buf, 0.76)

    # 10. chest_open: mở rương (bật chốt + rải ngũ cung C5..C6)
    buf = [0.0] * int(0.56 * SAMPLE_RATE)
    notes = ["C5", "D5", "E5", "G5", "A5", "C6"]
    seq = [(i * 0.065, 0.18 if i == len(notes) - 1 else 0.09, "sq25", PENTA[k]) for i, k in enumerate(notes)]
    add_tone_seq(buf, seq, 0.5)
    out["chest_open"] = normalize(buf, 0.78)

    # 11. buy: mua hàng thành công
    buf = [0.0] * int(0.28 * SAMPLE_RATE)
    add_tone_seq(
        buf,
        [(0.0, 0.07, "sq", PENTA["E5"]), (0.07, 0.07, "sq", PENTA["G5"]), (0.14, 0.14, "sq", PENTA["C6"])],
        0.5,
    )
    out["buy"] = normalize(buf, 0.76)

    # 12. buy_fail: không đủ xu
    buf = [0.0] * int(0.22 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.09, "sq", 165.0), (0.10, 0.12, "sq", 130.0)], 0.5)
    out["buy_fail"] = normalize(buf, 0.75)

    # 13. door_close: cửa phòng đóng sầm
    rng = random.Random(113)
    n = int(0.26 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 135.0 * (0.35 ** (t / 0.26)) + 38.0
        ph += f / SAMPLE_RATE
        lp = lp * 0.8 + rng.uniform(-1.0, 1.0) * 0.2
        e = env_ad(t, 0.26, 0.003, 1.9)
        buf.append((0.7 * math.sin(2.0 * math.pi * ph) + 0.55 * lp) * e)
    out["door_close"] = normalize(buf, 0.85)

    # 14. boss_appear: trùm xuất hiện (3 tiếng trống + chiêng trầm ngân)
    rng = random.Random(114)
    n = int(0.95 * SAMPLE_RATE)
    buf = [0.0] * n
    for hit_t in (0.0, 0.18, 0.36):
        i0 = int(hit_t * SAMPLE_RATE)
        hn = int(0.22 * SAMPLE_RATE)
        ph = 0.0
        lp = 0.0
        for j in range(hn):
            if i0 + j >= n:
                break
            t = j / SAMPLE_RATE
            f = 130.0 * (0.4 ** (t / 0.22)) + 40.0
            ph += f / SAMPLE_RATE
            lp = lp * 0.75 + rng.uniform(-1.0, 1.0) * 0.25
            buf[i0 + j] += (0.75 * math.sin(2.0 * math.pi * ph) + 0.45 * lp) * env_ad(t, 0.22, 0.003, 1.8)
    add_tone_seq(buf, [(0.36, 0.58, "sq", PENTA["C3"]), (0.36, 0.58, "tri", PENTA["G3"])], 0.38)
    out["boss_appear"] = normalize(buf, 0.85)

    # 15. boss_morph: trùm hiện nguyên hình (tà khí dâng + nổ rung)
    rng = random.Random(115)
    n = int(1.1 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    ph2 = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        vib = 1.0 + 0.08 * math.sin(2.0 * math.pi * 14.0 * t)
        f = (110.0 + 420.0 * (t / 1.1) ** 1.4) * vib
        ph += f / SAMPLE_RATE
        ph2 += (f * 0.503) / SAMPLE_RATE
        lp = lp * 0.72 + rng.uniform(-1.0, 1.0) * 0.28
        e = env_asr(t, 1.1, 0.08, 0.22)
        buf.append((0.45 * square(ph, 0.3) + 0.35 * triangle(ph2) + 0.4 * lp) * e)
    out["boss_morph"] = normalize(buf, 0.84)

    # 16. level_clear: qua màn / khải hoàn (C5-D5-E5-G5-C6)
    buf = [0.0] * int(0.75 * SAMPLE_RATE)
    seq = [
        (0.00, 0.11, "sq", PENTA["C5"]),
        (0.11, 0.11, "sq", PENTA["D5"]),
        (0.22, 0.11, "sq", PENTA["E5"]),
        (0.33, 0.12, "sq", PENTA["G5"]),
        (0.45, 0.30, "sq", PENTA["C6"]),
        (0.45, 0.30, "tri", PENTA["C5"]),
    ]
    add_tone_seq(buf, seq, 0.48)
    out["level_clear"] = normalize(buf, 0.8)

    # 17. ui_click: bấm nút
    buf = [0.0] * int(0.06 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.055, "sq25", PENTA["G5"])], 0.5)
    out["ui_click"] = normalize(buf, 0.65)

    # 18. player_die: gục ngã (A4-G4-E4-C4)
    buf = [0.0] * int(0.76 * SAMPLE_RATE)
    seq = [
        (0.00, 0.17, "sq", PENTA["A4"]),
        (0.17, 0.17, "sq", PENTA["G4"]),
        (0.34, 0.17, "sq", PENTA["E4"]),
        (0.51, 0.25, "sq", PENTA["C4"]),
    ]
    add_tone_seq(buf, seq, 0.48)
    out["player_die"] = normalize(buf, 0.78)

    # 19. skill: tung kỹ năng (trống đồng + quét ngũ cung sáng)
    rng = random.Random(119)
    n = int(0.42 * SAMPLE_RATE)
    buf = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 160.0 * (0.45 ** (t / 0.42)) + 55.0
        ph += f / SAMPLE_RATE
        buf[i] += (0.65 * math.sin(2.0 * math.pi * ph) + 0.2 * rng.uniform(-1.0, 1.0) * max(0.0, 1.0 - t / 0.1)) * env_ad(t, 0.42, 0.004, 1.6)
    add_tone_seq(buf, [(0.0, 0.10, "tri", PENTA["C5"]), (0.07, 0.12, "tri", PENTA["G5"]), (0.14, 0.24, "sq25", PENTA["C6"])], 0.35)
    out["skill"] = normalize(buf, 0.82)

    # 20. hit_flesh: chém hoặc đâm trúng giặc
    rng = random.Random(120)
    n = int(0.11 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 290.0 * (0.3 ** (t / 0.11)) + 65.0
        ph += f / SAMPLE_RATE
        lp = lp * 0.55 + rng.uniform(-1.0, 1.0) * 0.45
        buf.append((0.55 * math.sin(2.0 * math.pi * ph) + 0.5 * lp) * env_ad(t, 0.11, 0.002, 1.9))
    out["hit_flesh"] = normalize(buf, 0.8)

    # 21. hit_bullet: đạn, tên trúng giặc
    rng = random.Random(121)
    n = int(0.08 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 520.0 * (0.25 ** (t / 0.08)) + 90.0
        ph += f / SAMPLE_RATE
        w = 0.65 * triangle(ph) + 0.35 * rng.uniform(-1.0, 1.0) * max(0.0, 1.0 - t / 0.03)
        buf.append(w * env_ad(t, 0.08, 0.001, 2.0))
    out["hit_bullet"] = normalize(buf, 0.76)

    # 22. hit_metal: "keng", trúng khiên hoặc giáp
    n = int(0.22 * SAMPLE_RATE)
    buf = []
    for i in range(n):
        t = i / SAMPLE_RATE
        w = (
            0.45 * math.sin(2.0 * math.pi * 1180.0 * t)
            + 0.32 * math.sin(2.0 * math.pi * 1790.0 * t)
            + 0.23 * square(2520.0 * t, 0.35) * max(0.0, 1.0 - t / 0.06)
        )
        buf.append(w * env_ad(t, 0.22, 0.001, 2.3))
    out["hit_metal"] = normalize(buf, 0.8)

    # 23. hit_wall: đạn chạm tường hoặc đá
    rng = random.Random(123)
    n = int(0.09 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 190.0 * (0.35 ** (t / 0.09)) + 55.0
        ph += f / SAMPLE_RATE
        lp = lp * 0.68 + rng.uniform(-1.0, 1.0) * 0.32
        buf.append((0.5 * math.sin(2.0 * math.pi * ph) + 0.55 * lp) * env_ad(t, 0.09, 0.002, 2.4))
    out["hit_wall"] = normalize(buf, 0.72)

    # 24. hit_wood: trúng gỗ (hình nhân rơm, cọc, rương)
    rng = random.Random(124)
    n = int(0.11 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 330.0 * (0.55 ** (t / 0.11)) + 140.0
        ph += f / SAMPLE_RATE
        w = 0.75 * math.sin(2.0 * math.pi * ph) + 0.25 * rng.uniform(-1.0, 1.0) * max(0.0, 1.0 - t / 0.025)
        buf.append(w * env_ad(t, 0.11, 0.002, 2.5))
    out["hit_wood"] = normalize(buf, 0.78)

    # 25. hit_crit: chí mạng, nghe "đanh" và sáng
    buf = [0.0] * int(0.15 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.055, "sq25", PENTA["A5"]), (0.04, 0.11, "sq25", PENTA["E6"])], 0.58)
    out["hit_crit"] = normalize(buf, 0.85)

    # 26. hit_boss: trúng trùm, trầm và nặng hơn
    rng = random.Random(126)
    n = int(0.13 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 165.0 * (0.35 ** (t / 0.13)) + 45.0
        ph += f / SAMPLE_RATE
        lp = lp * 0.75 + rng.uniform(-1.0, 1.0) * 0.25
        buf.append((0.7 * math.sin(2.0 * math.pi * ph) + 0.35 * lp) * env_ad(t, 0.13, 0.002, 1.8))
    out["hit_boss"] = normalize(buf, 0.82)

    # 27. pickup_material: nhặt nguyên liệu (2 nốt ấm rõ nét)
    buf = [0.0] * int(0.22 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.07, "tri", PENTA["E5"]), (0.06, 0.15, "sq25", PENTA["A5"])], 0.52)
    out["pickup_material"] = normalize(buf, 0.76)

    # 28. forge: tiếng búa nện đe + lóe sáng khi rèn binh khí
    rng = random.Random(128)
    n = int(0.55 * SAMPLE_RATE)
    buf = [0.0] * n
    for hit_t, pitch_m in ((0.0, 1.0), (0.16, 1.08)):
        i0 = int(hit_t * SAMPLE_RATE)
        hn = int(0.26 * SAMPLE_RATE)
        for j in range(hn):
            if i0 + j >= n:
                break
            t = j / SAMPLE_RATE
            clang = (
                0.45 * math.sin(2.0 * math.pi * 1040.0 * pitch_m * t)
                + 0.30 * math.sin(2.0 * math.pi * 1620.0 * pitch_m * t)
                + 0.25 * rng.uniform(-1.0, 1.0) * max(0.0, 1.0 - t / 0.04)
            )
            buf[i0 + j] += clang * env_ad(t, 0.26, 0.001, 2.2) * 0.65
    add_tone_seq(buf, [(0.22, 0.10, "tri", PENTA["G5"]), (0.30, 0.24, "sq25", PENTA["C6"])], 0.36)
    out["forge"] = normalize(buf, 0.84)

    # 29. portal: dịch chuyển qua cổng (tầng hầm / cổng màn)
    rng = random.Random(129)
    n = int(0.46 * SAMPLE_RATE)
    buf = [0.0] * n
    ph = 0.0
    ph2 = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 260.0 + 540.0 * (t / 0.46) ** 1.3
        ph += f / SAMPLE_RATE
        ph2 += (f * 1.5) / SAMPLE_RATE
        lp = lp * 0.7 + rng.uniform(-1.0, 1.0) * 0.3
        e = env_asr(t, 0.46, 0.04, 0.14)
        buf[i] += (0.5 * math.sin(2.0 * math.pi * ph) + 0.28 * triangle(ph2) + 0.22 * lp) * e
    add_tone_seq(buf, [(0.04, 0.12, "tri", PENTA["E5"]), (0.14, 0.16, "tri", PENTA["A5"]), (0.24, 0.20, "sin", PENTA["E6"])], 0.32)
    out["portal"] = normalize(buf, 0.8)

    # 30. pickup: nhặt vật phẩm / tưới vườn / lộc nhẹ
    buf = [0.0] * int(0.16 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.06, "tri", PENTA["D5"]), (0.045, 0.11, "sin", PENTA["A5"])], 0.55)
    out["pickup"] = normalize(buf, 0.74)

    # 31. pickup_coin: nhặt xu / hồi sinh đồng đội
    buf = [0.0] * int(0.22 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.055, "sq25", PENTA["A5"]), (0.045, 0.06, "sq25", PENTA["C6"]), (0.095, 0.12, "sq25", PENTA["E6"])], 0.52)
    out["pickup_coin"] = normalize(buf, 0.76)

    # ------------------------------------------------------------------ 11 Kỹ năng tướng riêng biệt
    out.update(_gen_hero_skills())

    # ------------------------------------------------------------------ 32 Âm thanh nhóm vũ khí (w_*)
    out.update(_gen_weapon_archetypes())

    return out


def _sweep_buf(
    dur: float,
    f0: float,
    f1: float,
    seed: int,
    wave_kind: str = "tri",
    noise_mix: float = 0.25,
    noise_lp: float = 0.6,
    attack: float = 0.003,
    exp: float = 1.7,
    sweep_pow: float = 1.0,
    sub_ratio: float = 0.0,
) -> list[float]:
    """Bộ tổng hợp quét tần số + nhiễu lọc thông thấp dùng chung cho SFX."""
    rng = random.Random(seed)
    n = int(dur * SAMPLE_RATE)
    buf = []
    ph = 0.0
    ph_sub = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        u = min(1.0, t / max(dur, 1e-6)) ** sweep_pow
        f = f0 + (f1 - f0) * u
        ph += f / SAMPLE_RATE
        ph_sub += (f * 0.5) / SAMPLE_RATE
        if wave_kind == "sq":
            w = square(ph, 0.5)
        elif wave_kind == "sq25":
            w = square(ph, 0.25)
        elif wave_kind == "sin":
            w = math.sin(2.0 * math.pi * ph)
        elif wave_kind == "saw":
            w = 2.0 * (ph % 1.0) - 1.0
        else:
            w = triangle(ph)
        if sub_ratio > 0.0:
            w = (1.0 - sub_ratio) * w + sub_ratio * math.sin(2.0 * math.pi * ph_sub)
        lp = lp * noise_lp + rng.uniform(-1.0, 1.0) * (1.0 - noise_lp)
        e = env_ad(t, dur, attack, exp)
        buf.append(((1.0 - noise_mix) * w + noise_mix * lp) * e)
    return buf


def _add_bell(buf: list[float], start_s: float, dur: float, base_hz: float, partials: list[tuple[float, float]], vol: float = 0.45) -> None:
    i0 = int(start_s * SAMPLE_RATE)
    n = int(dur * SAMPLE_RATE)
    for j in range(n):
        idx = i0 + j
        if idx >= len(buf):
            break
        t = j / SAMPLE_RATE
        s = 0.0
        for ratio, amp in partials:
            s += amp * math.sin(2.0 * math.pi * base_hz * ratio * t) * math.exp(-t * (2.5 + ratio * 1.4))
        buf[idx] += s * env_ad(t, dur, 0.002, 1.3) * vol


def _gen_hero_skills() -> dict[str, list[float]]:
    skills: dict[str, list[float]] = {}

    # 1. Hai Bà Trưng (Song Trưng): song kiếm hòa tấu + song thanh vang đôi
    buf = [0.0] * int(0.48 * SAMPLE_RATE)
    add_tone_seq(
        buf,
        [
            (0.00, 0.14, "sq25", PENTA["C5"]),
            (0.04, 0.14, "tri", PENTA["G5"]),
            (0.10, 0.16, "sq25", PENTA["E5"]),
            (0.14, 0.28, "tri", PENTA["C6"]),
            (0.18, 0.26, "sq25", PENTA["G5"]),
        ],
        0.42,
    )
    sw = _sweep_buf(0.20, 1280.0, 420.0, 301, "tri", 0.45, 0.4, 0.002, 1.8)
    for i, x in enumerate(sw):
        buf[i] += x * 0.45
    skills["skill_hai_ba_trung"] = normalize(buf, 0.84)

    # 2. Bà Triệu (Voi chiến): tiếng voi rống + bước dậm rung đất
    rng = random.Random(302)
    n = int(0.56 * SAMPLE_RATE)
    buf = [0.0] * n
    ph = 0.0
    for i in range(int(0.38 * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        vib = 1.0 + 0.04 * math.sin(2.0 * math.pi * 22.0 * t)
        f = (260.0 + 380.0 * math.sin(math.pi * min(1.0, t / 0.34))) * vib
        ph += f / SAMPLE_RATE
        w = 0.55 * (2.0 * (ph % 1.0) - 1.0) + 0.45 * square(ph * 0.5, 0.35)
        buf[i] += w * env_asr(t, 0.38, 0.03, 0.10) * 0.6
    for stomp_t in (0.14, 0.32):
        st = _sweep_buf(0.18, 130.0, 36.0, 3020 + int(stomp_t * 100), "sin", 0.35, 0.78, 0.003, 1.7)
        i0 = int(stomp_t * SAMPLE_RATE)
        for j, x in enumerate(st):
            if i0 + j < n:
                buf[i0 + j] += x * 0.65
    skills["skill_ba_trieu"] = normalize(buf, 0.85)

    # 3. Ngô Quyền (Cọc Bạch Đằng): sóng nước cuồn cuộn + loạt cọc nhọn bật lên
    rng = random.Random(303)
    n = int(0.54 * SAMPLE_RATE)
    buf = [0.0] * n
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        lp = lp * 0.72 + rng.uniform(-1.0, 1.0) * 0.28
        buf[i] += lp * env_asr(t, 0.54, 0.06, 0.18) * 0.55
    for k, stake_t in enumerate((0.03, 0.10, 0.17, 0.24, 0.31)):
        st = _sweep_buf(0.11, 210.0 + k * 45.0, 95.0, 3030 + k, "tri", 0.30, 0.5, 0.002, 2.0)
        i0 = int(stake_t * SAMPLE_RATE)
        for j, x in enumerate(st):
            if i0 + j < n:
                buf[i0 + j] += x * 0.58
    skills["skill_ngo_quyen"] = normalize(buf, 0.84)

    # 4. Lý Thường Kiệt (Nam quốc sơn hà): chuông chùa trầm hùng + hào quang hộ thể
    n = int(0.60 * SAMPLE_RATE)
    buf = [0.0] * n
    _add_bell(buf, 0.0, 0.58, 392.0, [(1.0, 0.55), (1.5, 0.32), (2.4, 0.25), (3.1, 0.18)], 0.75)
    add_tone_seq(buf, [(0.06, 0.18, "sin", PENTA["G4"]), (0.14, 0.36, "tri", PENTA["D5"])], 0.35)
    skills["skill_ly_thuong_kiet"] = normalize(buf, 0.84)

    # 5. Trần Hưng Đạo (Hịch tướng sĩ): 3 hồi trống đồng dồn dập + kèn hiệu xuất quân
    n = int(0.58 * SAMPLE_RATE)
    buf = [0.0] * n
    for k, dt in enumerate((0.0, 0.12, 0.24)):
        dr = _sweep_buf(0.16, 155.0 + k * 10.0, 46.0, 3050 + k, "sin", 0.32, 0.75, 0.002, 1.8)
        i0 = int(dt * SAMPLE_RATE)
        for j, x in enumerate(dr):
            if i0 + j < n:
                buf[i0 + j] += x * 0.7
    add_tone_seq(buf, [(0.16, 0.11, "sq", PENTA["G4"]), (0.26, 0.12, "sq", PENTA["C5"]), (0.36, 0.20, "sq", PENTA["G5"])], 0.38)
    skills["skill_tran_hung_dao"] = normalize(buf, 0.85)

    # 6. Lê Lợi (Gươm Thuận Thiên): rút thần kiếm sáng lòa + vòng kiếm ngân vang
    n = int(0.52 * SAMPLE_RATE)
    buf = _sweep_buf(0.32, 520.0, 1780.0, 306, "tri", 0.28, 0.45, 0.01, 1.3, 1.2) + [0.0] * int(0.20 * SAMPLE_RATE)
    _add_bell(buf, 0.08, 0.42, 880.0, [(1.0, 0.5), (1.98, 0.35), (2.95, 0.22)], 0.55)
    add_tone_seq(buf, [(0.12, 0.14, "sq25", PENTA["A5"]), (0.22, 0.24, "sq25", PENTA["E6"])], 0.30)
    skills["skill_le_loi"] = normalize(buf, 0.84)

    # 7. Quang Trung (Thần tốc): cuồng phong bứt tốc + ngũ cung dồn dập + tia lửa
    n = int(0.46 * SAMPLE_RATE)
    buf = _sweep_buf(0.44, 240.0, 1180.0, 307, "tri", 0.52, 0.42, 0.01, 1.4, 1.4)
    add_tone_seq(
        buf,
        [
            (0.00, 0.07, "sq25", PENTA["C5"]),
            (0.055, 0.07, "sq25", PENTA["D5"]),
            (0.11, 0.07, "sq25", PENTA["E5"]),
            (0.165, 0.07, "sq25", PENTA["G5"]),
            (0.22, 0.08, "sq25", PENTA["A5"]),
            (0.28, 0.16, "sq25", PENTA["C6"]),
        ],
        0.42,
    )
    skills["skill_quang_trung"] = normalize(buf, 0.84)

    # 8. Nguyễn Trung Trực (Hỏa hồng Nhật Tảo): vỡ bầu rượu + biển lửa bùng cháy
    n = int(0.54 * SAMPLE_RATE)
    buf = _sweep_buf(0.54, 420.0, 90.0, 308, "saw", 0.72, 0.55, 0.004, 1.35, 0.8)
    _add_bell(buf, 0.0, 0.12, 1320.0, [(1.0, 0.5), (1.72, 0.4)], 0.45)
    skills["skill_nguyen_trung_truc"] = normalize(buf, 0.85)

    # 9. Hoàng Hoa Thám (Hùm thiêng Yên Thế): tiếng hổ gầm rền vang
    rng = random.Random(309)
    n = int(0.56 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        growl = 1.0 + 0.18 * math.sin(2.0 * math.pi * 34.0 * t)
        f = (205.0 - 115.0 * (t / 0.56) ** 0.8) * growl
        ph += f / SAMPLE_RATE
        lp = lp * 0.62 + rng.uniform(-1.0, 1.0) * 0.38
        w = 0.52 * (2.0 * (ph % 1.0) - 1.0) + 0.25 * square(ph * 0.5, 0.4) + 0.45 * lp
        buf.append(w * env_asr(t, 0.56, 0.035, 0.18))
    skills["skill_hoang_hoa_tham"] = normalize(buf, 0.86)

    # 10. Chiến sĩ Điện Biên (Kéo pháo vào trận): tiếng tời cóc kéo pháo + đặt bệ nòng nặng
    n = int(0.56 * SAMPLE_RATE)
    buf = [0.0] * n
    for k, ct in enumerate((0.0, 0.09, 0.18, 0.27)):
        cl = _sweep_buf(0.055, 980.0 + k * 70.0, 420.0, 3100 + k, "sq25", 0.45, 0.3, 0.001, 2.2)
        i0 = int(ct * SAMPLE_RATE)
        for j, x in enumerate(cl):
            if i0 + j < n:
                buf[i0 + j] += x * 0.55
    thud = _sweep_buf(0.22, 165.0, 42.0, 3109, "sin", 0.48, 0.78, 0.003, 1.7)
    i_thud = int(0.32 * SAMPLE_RATE)
    for j, x in enumerate(thud):
        if i_thud + j < n:
            buf[i_thud + j] += x * 0.85
    skills["skill_chien_si_dien_bien"] = normalize(buf, 0.85)

    # 11. Thánh Gióng (Ngựa sắt phun lửa): ngựa sắt hí vang + vó sắt + luồng lửa rồng
    rng = random.Random(311)
    n = int(0.58 * SAMPLE_RATE)
    buf = [0.0] * n
    ph = 0.0
    for i in range(int(0.28 * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        vib = 1.0 + 0.09 * math.sin(2.0 * math.pi * 26.0 * t)
        f = (680.0 + 420.0 * math.sin(math.pi * t / 0.25) - 220.0 * (t / 0.28)) * vib
        ph += f / SAMPLE_RATE
        buf[i] += (0.65 * square(ph, 0.35) + 0.35 * triangle(ph * 1.5)) * env_asr(t, 0.28, 0.02, 0.08) * 0.65
    lp = 0.0
    for i in range(int(0.20 * SAMPLE_RATE), n):
        t = (i - int(0.20 * SAMPLE_RATE)) / SAMPLE_RATE
        lp = lp * 0.58 + rng.uniform(-1.0, 1.0) * 0.42
        buf[i] += lp * env_asr(t, 0.38, 0.03, 0.14) * 0.7
    _add_bell(buf, 0.04, 0.16, 1180.0, [(1.0, 0.4), (1.6, 0.3)], 0.35)
    skills["skill_thanh_giong"] = normalize(buf, 0.86)

    return skills


def _gen_weapon_archetypes() -> dict[str, list[float]]:
    w: dict[str, list[float]] = {}

    # 1. w_bamboo: gậy tre, côn gỗ (tiếng đập gỗ tre rỗng + vút gió)
    w["w_bamboo"] = normalize(_sweep_buf(0.14, 380.0, 150.0, 401, "sin", 0.38, 0.55, 0.002, 2.1), 0.8)

    # 2. w_dagger: dao găm, liềm (vút ngắn, sắc, nhanh)
    w["w_dagger"] = normalize(_sweep_buf(0.09, 1450.0, 460.0, 402, "tri", 0.45, 0.35, 0.001, 2.2), 0.78)

    # 3. w_sword: kiếm, gươm, mã tấu (chém kim khí gọn sắc)
    buf = _sweep_buf(0.14, 920.0, 260.0, 403, "tri", 0.50, 0.42, 0.002, 1.8)
    _add_bell(buf, 0.01, 0.12, 1520.0, [(1.0, 0.35), (1.42, 0.2)], 0.35)
    w["w_sword"] = normalize(buf, 0.8)

    # 4. w_greatsword: đại đao, thần kiếm (chém nặng rộng + ngân vang trầm)
    buf = _sweep_buf(0.24, 520.0, 115.0, 404, "saw", 0.55, 0.60, 0.004, 1.6, 1.0, 0.3)
    _add_bell(buf, 0.02, 0.20, 740.0, [(1.0, 0.35), (1.55, 0.22)], 0.36)
    w["w_greatsword"] = normalize(buf, 0.82)

    # 5. w_spear: giáo, thương, kích, đinh ba (đâm vút gió thẳng)
    w["w_spear"] = normalize(_sweep_buf(0.13, 1220.0, 310.0, 405, "sin", 0.52, 0.38, 0.002, 1.9, 1.3), 0.78)

    # 6. w_axe: rìu đá, rìu chiến (bổ nặng + giòn)
    w["w_axe"] = normalize(_sweep_buf(0.19, 320.0, 72.0, 406, "sq", 0.48, 0.65, 0.003, 1.8, 1.0, 0.35), 0.82)

    # 7. w_hammer: chùy đồng, búa thiên lôi (nện ầm + rung kim loại)
    buf = _sweep_buf(0.28, 195.0, 40.0, 407, "sin", 0.42, 0.78, 0.002, 1.6, 1.0, 0.45)
    _add_bell(buf, 0.0, 0.22, 620.0, [(1.0, 0.4), (1.7, 0.25)], 0.42)
    w["w_hammer"] = normalize(buf, 0.85)

    # 8. w_scythe: lưỡi hái (quét âm u lượn rít)
    rng = random.Random(408)
    n = int(0.22 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 640.0 - 460.0 * (t / 0.22) + 60.0 * math.sin(2.0 * math.pi * 24.0 * t)
        ph += f / SAMPLE_RATE
        lp = lp * 0.52 + rng.uniform(-1.0, 1.0) * 0.48
        buf.append((0.45 * triangle(ph) + 0.55 * lp) * env_ad(t, 0.22, 0.006, 1.5))
    w["w_scythe"] = normalize(buf, 0.8)

    # 9. w_spin: côn nhị khúc, cưa máy (xoay nhịp liên hoàn)
    n = int(0.16 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        lfo = 0.55 + 0.45 * math.sin(2.0 * math.pi * 38.0 * t)
        f = 340.0 + 180.0 * math.sin(2.0 * math.pi * 18.0 * t)
        ph += f / SAMPLE_RATE
        buf.append((0.6 * (2.0 * (ph % 1.0) - 1.0) + 0.4 * square(ph, 0.3)) * lfo * env_ad(t, 0.16, 0.005, 1.3))
    w["w_spin"] = normalize(buf, 0.78)

    # 10. w_fan: quạt thép, quạt ba tiêu (bật nan quạt + luồng gió mạnh)
    buf = _sweep_buf(0.17, 780.0, 220.0, 410, "tri", 0.68, 0.45, 0.002, 1.5)
    add_tone_seq(buf, [(0.0, 0.035, "sq25", 980.0)], 0.35)
    w["w_fan"] = normalize(buf, 0.78)

    # 11. w_whip: roi sắt Thánh Gióng (quất gió rồi nổ tách giòn)
    rng = random.Random(411)
    n = int(0.18 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 400.0 + 1400.0 * (t / 0.07) if t < 0.07 else 1600.0 * (0.25 ** ((t - 0.07) / 0.11))
        ph += f / SAMPLE_RATE
        crack = rng.uniform(-1.0, 1.0) * (1.0 if 0.055 <= t <= 0.095 else 0.25)
        e = env_ad(t, 0.18, 0.012, 1.8)
        buf.append((0.45 * triangle(ph) + 0.55 * crack) * e)
    w["w_whip"] = normalize(buf, 0.82)

    # 12. w_bow: cung tên (bật dây cung + tên xé gió)
    buf = _sweep_buf(0.16, 880.0, 320.0, 412, "tri", 0.35, 0.40, 0.002, 2.0)
    add_tone_seq(buf, [(0.0, 0.07, "tri", 240.0)], 0.45)
    w["w_bow"] = normalize(buf, 0.78)

    # 13. w_crossbow: nỏ (lẫy cò bật sắc + mũi tên lao nhanh)
    buf = _sweep_buf(0.12, 1280.0, 460.0, 413, "sq25", 0.30, 0.35, 0.001, 2.3)
    add_tone_seq(buf, [(0.0, 0.025, "sq", 1600.0)], 0.35)
    w["w_crossbow"] = normalize(buf, 0.78)

    # 14. w_dart: phi tiêu, lá bài, đinh, ná (phóng cực gọn)
    w["w_dart"] = normalize(_sweep_buf(0.085, 1650.0, 720.0, 414, "tri", 0.35, 0.3, 0.001, 2.4), 0.75)

    # 15. w_boomerang: nón lá bay, chong chóng, luân hồi bàn (rung nhịp vòng xoáy)
    rng = random.Random(415)
    n = int(0.24 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        wob = 0.6 + 0.4 * math.sin(2.0 * math.pi * 20.0 * t)
        f = 540.0 + 180.0 * math.sin(2.0 * math.pi * 12.0 * t)
        ph += f / SAMPLE_RATE
        lp = lp * 0.55 + rng.uniform(-1.0, 1.0) * 0.45
        buf.append((0.55 * triangle(ph) + 0.45 * lp) * wob * env_asr(t, 0.24, 0.015, 0.06))
    w["w_boomerang"] = normalize(buf, 0.78)

    # 16. w_pistol: súng ngắn, súng lục (nổ gọn đanh)
    w["w_pistol"] = normalize(_sweep_buf(0.13, 820.0, 105.0, 416, "sq25", 0.48, 0.45, 0.001, 2.1), 0.82)

    # 17. w_rifle: súng trường, tiểu liên (tiếng nổ đạn xuyên sắc nét)
    w["w_rifle"] = normalize(_sweep_buf(0.15, 1050.0, 120.0, 417, "sq", 0.54, 0.40, 0.001, 2.0), 0.82)

    # 18. w_shotgun: súng săn, hai nòng (nổ chùm dày trầm mạnh)
    w["w_shotgun"] = normalize(_sweep_buf(0.26, 420.0, 58.0, 418, "sq", 0.72, 0.62, 0.002, 1.7, 1.0, 0.4), 0.85)

    # 19. w_musket: súng hỏa mai, súng thần cơ (xì thuốc súng + nổ trầm)
    buf = _sweep_buf(0.27, 360.0, 65.0, 419, "sq", 0.65, 0.65, 0.018, 1.6, 1.0, 0.35)
    w["w_musket"] = normalize(buf, 0.84)

    # 20. w_cannon: pháo đồng, đại bác (ầm rung sâu)
    w["w_cannon"] = normalize(_sweep_buf(0.40, 155.0, 32.0, 420, "sin", 0.58, 0.80, 0.003, 1.5, 1.0, 0.5), 0.88)

    # 21. w_rocket: hỏa tiễn, pháo hoa (rít lửa phóng lên)
    w["w_rocket"] = normalize(_sweep_buf(0.28, 320.0, 960.0, 421, "saw", 0.68, 0.50, 0.015, 1.3, 1.1), 0.8)

    # 22. w_grenade: phóng lựu, hồ lô (tiếng "bụp" ống phóng rỗng)
    w["w_grenade"] = normalize(_sweep_buf(0.18, 300.0, 88.0, 422, "sin", 0.30, 0.68, 0.004, 1.9), 0.82)

    # 23. w_fire: lửa, hỏa hổ, bùa cháy (phụt lửa rực cháy)
    rng = random.Random(423)
    n = int(0.22 * SAMPLE_RATE)
    buf = _sweep_buf(0.22, 340.0, 110.0, 423, "saw", 0.76, 0.58, 0.01, 1.4)
    for _ in range(6):
        idx = rng.randint(0, n - 40)
        buf[idx] += rng.choice((-0.8, 0.8))
    w["w_fire"] = normalize(buf, 0.8)

    # 24. w_ice: băng giá, sương mù (tinh thể băng ngân trong trẻo)
    buf = _sweep_buf(0.16, 1800.0, 950.0, 424, "sin", 0.25, 0.30, 0.003, 1.8) + [0.0] * int(0.05 * SAMPLE_RATE)
    _add_bell(buf, 0.0, 0.20, 1568.0, [(1.0, 0.45), (1.49, 0.35), (2.12, 0.25)], 0.55)
    w["w_ice"] = normalize(buf, 0.78)

    # 25. w_lightning: sấm sét, Tesla (tia điện giật tách tách)
    rng = random.Random(425)
    n = int(0.17 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = (1400.0 if (i // 140) % 2 == 0 else 580.0) * (0.45 ** (t / 0.17))
        ph += f / SAMPLE_RATE
        snap = rng.uniform(-1.0, 1.0) if (i % 19 < 4) else 0.2 * rng.uniform(-1.0, 1.0)
        buf.append((0.55 * square(ph, 0.2) + 0.45 * snap) * env_ad(t, 0.17, 0.001, 1.9))
    w["w_lightning"] = normalize(buf, 0.82)

    # 26. w_poison: độc tố, axit (sủi bọt xì hơi độc)
    n = int(0.20 * SAMPLE_RATE)
    buf = _sweep_buf(0.20, 290.0, 520.0, 426, "sin", 0.55, 0.52, 0.008, 1.4)
    add_tone_seq(buf, [(0.02, 0.045, "sin", 480.0), (0.075, 0.045, "sin", 640.0), (0.125, 0.05, "sin", 790.0)], 0.42)
    w["w_poison"] = normalize(buf, 0.78)

    # 27. w_jade: nước, ngọc, bong bóng (giọt ngọc thủy luân thanh mát)
    buf = [0.0] * int(0.19 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.07, "sin", PENTA["G5"]), (0.045, 0.13, "sin", PENTA["D6"])], 0.55)
    sw = _sweep_buf(0.14, 460.0, 920.0, 427, "sin", 0.22, 0.55, 0.004, 1.8)
    for i, x in enumerate(sw):
        buf[i] += x * 0.45
    w["w_jade"] = normalize(buf, 0.76)

    # 28. w_void: hư không, trọng lực, linh hồn (âm trầm xoáy huyền bí)
    n = int(0.25 * SAMPLE_RATE)
    buf = []
    ph1 = 0.0
    ph2 = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 220.0 * (0.35 ** (t / 0.25)) + 52.0
        ph1 += f / SAMPLE_RATE
        ph2 += (f * 1.498) / SAMPLE_RATE
        buf.append((0.55 * triangle(ph1) + 0.45 * math.sin(2.0 * math.pi * ph2)) * env_asr(t, 0.25, 0.02, 0.08))
    w["w_void"] = normalize(buf, 0.8)

    # 29. w_magic_orb: phép thuật, sao băng, ngân hà (chuỗi sao lấp lánh)
    buf = [0.0] * int(0.20 * SAMPLE_RATE)
    add_tone_seq(
        buf,
        [(0.0, 0.055, "tri", PENTA["E5"]), (0.045, 0.055, "tri", PENTA["G5"]), (0.09, 0.10, "sq25", PENTA["C6"])],
        0.48,
    )
    w["w_magic_orb"] = normalize(buf, 0.76)

    # 30. w_laser: laze, plasma, railgun (tia năng lượng quét nhanh)
    n = int(0.19 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = 1520.0 * (0.20 ** (t / 0.19)) + 160.0
        ph += f / SAMPLE_RATE
        fm = math.sin(2.0 * math.pi * ph + 1.4 * math.sin(2.0 * math.pi * ph * 2.0))
        buf.append((0.6 * fm + 0.4 * square(ph, 0.25)) * env_ad(t, 0.19, 0.002, 1.7))
    w["w_laser"] = normalize(buf, 0.8)

    # 31. w_drum: trống đồng, trống cơm, chấn địa (trống đồng ngân trầm)
    buf = _sweep_buf(0.34, 150.0, 44.0, 431, "sin", 0.34, 0.78, 0.002, 1.5, 1.0, 0.4)
    _add_bell(buf, 0.0, 0.30, 261.63, [(1.0, 0.35), (1.5, 0.22)], 0.38)
    w["w_drum"] = normalize(buf, 0.85)

    # 32. w_flute: sáo trúc, đàn thần, chuông (âm nhạc cụ dân gian vang ngân)
    n = int(0.30 * SAMPLE_RATE)
    buf = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        vib = 1.0 + 0.015 * math.sin(2.0 * math.pi * 6.0 * t)
        ph += (PENTA["G5"] * vib) / SAMPLE_RATE
        ang = 2.0 * math.pi * ph
        buf[i] += (0.75 * math.sin(ang) + 0.2 * math.sin(2.0 * ang)) * env_asr(t, 0.30, 0.025, 0.09) * 0.65
    _add_bell(buf, 0.02, 0.26, PENTA["C5"], [(1.0, 0.35), (2.0, 0.2)], 0.35)
    w["w_flute"] = normalize(buf, 0.8)

    return w


# ------------------------------------------------------------------ Nhạc nền ngũ cung Việt

def add_flute_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.32) -> None:
    """Tiếng sáo trúc: sóng sin + hài nhẹ + vibrato hơi thở, ghi vòng tròn để lặp liền mạch."""
    total = len(buf)
    i0 = int(round(start_s * SAMPLE_RATE))
    n = int(round(dur_s * SAMPLE_RATE))
    phase = 0.0
    attack = min(0.045, dur_s * 0.25)
    release = min(0.075, dur_s * 0.3)
    for j in range(n):
        t = j / SAMPLE_RATE
        vib = 1.0 + (0.011 if t > 0.06 else 0.0) * math.sin(2.0 * math.pi * 5.5 * t)
        phase += (freq * vib) / SAMPLE_RATE
        ang = 2.0 * math.pi * phase
        w = 0.82 * math.sin(ang) + 0.14 * math.sin(2.0 * ang) + 0.04 * math.sin(3.0 * ang)
        buf[(i0 + j) % total] += w * env_asr(t, dur_s, attack, release) * vol


def add_pluck_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.2) -> None:
    """Tiếng đàn gảy nhẹ (tam giác + sin suy giảm), ghi vòng tròn."""
    total = len(buf)
    i0 = int(round(start_s * SAMPLE_RATE))
    n = int(round(dur_s * SAMPLE_RATE))
    phase = 0.0
    for j in range(n):
        t = j / SAMPLE_RATE
        phase += freq / SAMPLE_RATE
        w = 0.65 * math.sin(2.0 * math.pi * phase) + 0.35 * triangle(phase)
        buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.005, 2.2) * vol


def add_drum_loop(buf: list[float], start_s: float, rng: random.Random, kind: str = "kick", vol: float = 0.35) -> None:
    """Tiếng trống (nhiễu có bao âm + màng trống trầm), ghi vòng tròn."""
    total = len(buf)
    i0 = int(round(start_s * SAMPLE_RATE))
    if kind == "kick":
        dur_s = 0.22
        n = int(dur_s * SAMPLE_RATE)
        ph = 0.0
        lp = 0.0
        for j in range(n):
            t = j / SAMPLE_RATE
            f = 135.0 * (0.28 ** (t / dur_s)) + 42.0
            ph += f / SAMPLE_RATE
            lp = lp * 0.72 + rng.uniform(-1.0, 1.0) * 0.28
            w = 0.75 * math.sin(2.0 * math.pi * ph) + 0.35 * lp
            buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.003, 2.2) * vol
    else:
        dur_s = 0.11
        n = int(dur_s * SAMPLE_RATE)
        lp = 0.0
        for j in range(n):
            t = j / SAMPLE_RATE
            lp = lp * 0.45 + rng.uniform(-1.0, 1.0) * 0.55
            w = lp + 0.25 * math.sin(2.0 * math.pi * 240.0 * t)
            buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.002, 2.8) * vol


def render_music_track(
    bpm: float,
    bars: int,
    melody_bars: list[list[tuple[float, float, str]]],
    bass_bars: list[list[tuple[float, float, str]]],
    drum_pattern: list[tuple[float, str, float]],
    seed: int,
    flute_vol: float,
    pluck_vol: float,
    drum_vol: float,
) -> list[float]:
    beat_s = 60.0 / bpm
    total_beats = bars * 4
    total_samples = int(round(total_beats * beat_s * SAMPLE_RATE))
    buf = [0.0] * total_samples
    rng = random.Random(seed)

    for b in range(bars):
        bar_beat = b * 4.0
        for beat_off, dur_beats, note in melody_bars[b % len(melody_bars)]:
            add_flute_loop(buf, (bar_beat + beat_off) * beat_s, dur_beats * beat_s, PENTA[note], flute_vol)
        for beat_off, dur_beats, note in bass_bars[b % len(bass_bars)]:
            add_pluck_loop(buf, (bar_beat + beat_off) * beat_s, dur_beats * beat_s, PENTA[note], pluck_vol)
        for beat_off, dkind, dmul in drum_pattern:
            add_drum_loop(buf, (bar_beat + beat_off) * beat_s, rng, dkind, drum_vol * dmul)

    return normalize(buf, 0.72)


def gen_music() -> dict[str, list[float]]:
    out: dict[str, list[float]] = {}

    # 1. Sảnh (lobby.wav): 85 BPM, 16 ô nhịp = 64 phách (~45.18s) - êm ả, dân gian
    lobby_mel = [
        [(0.0, 1.5, "E5"), (1.5, 0.5, "G5"), (2.0, 1.5, "A5"), (3.5, 0.5, "G5")],
        [(0.0, 1.5, "E5"), (1.5, 0.5, "D5"), (2.0, 2.0, "C5")],
        [(0.0, 1.0, "D5"), (1.0, 1.0, "E5"), (2.0, 1.5, "G5"), (3.5, 0.5, "E5")],
        [(0.0, 1.5, "D5"), (1.5, 0.5, "C5"), (2.0, 2.0, "A4")],
        [(0.0, 1.0, "C5"), (1.0, 1.0, "D5"), (2.0, 1.5, "E5"), (3.5, 0.5, "G5")],
        [(0.0, 1.5, "A5"), (1.5, 0.5, "C6"), (2.0, 2.0, "G5")],
        [(0.0, 1.0, "E5"), (1.0, 1.0, "G5"), (2.0, 1.0, "D5"), (3.0, 1.0, "E5")],
        [(0.0, 3.0, "C5"), (3.0, 1.0, "G4")],
    ]
    lobby_bass = [
        [(0.0, 1.5, "C3"), (2.0, 1.5, "G3")],
        [(0.0, 1.5, "C4"), (2.0, 1.5, "G3")],
        [(0.0, 1.5, "D3"), (2.0, 1.5, "A3")],
        [(0.0, 1.5, "A3"), (2.0, 1.5, "E3")],
    ]
    lobby_drums = [(0.0, "kick", 0.7), (2.0, "wood", 0.55), (3.0, "kick", 0.45)]
    out["lobby"] = render_music_track(85.0, 16, lobby_mel, lobby_bass, lobby_drums, 202601, 0.32, 0.18, 0.16)

    # 2. Trận đánh (battle.wav): 115 BPM, 20 ô nhịp = 80 phách (~41.74s) - hào hùng, dứt khoát
    battle_mel = [
        [(0.0, 0.75, "C5"), (0.75, 0.75, "D5"), (1.5, 0.5, "E5"), (2.0, 1.0, "G5"), (3.0, 1.0, "A5")],
        [(0.0, 1.0, "G5"), (1.0, 0.5, "E5"), (1.5, 0.5, "D5"), (2.0, 1.5, "C5"), (3.5, 0.5, "D5")],
        [(0.0, 0.75, "E5"), (0.75, 0.75, "G5"), (1.5, 0.5, "A5"), (2.0, 1.0, "C6"), (3.0, 1.0, "A5")],
        [(0.0, 1.0, "G5"), (1.0, 1.0, "E5"), (2.0, 2.0, "D5")],
        [(0.0, 0.5, "C5"), (0.5, 0.5, "E5"), (1.0, 1.0, "G5"), (2.0, 0.75, "A5"), (2.75, 0.75, "G5"), (3.5, 0.5, "E5")],
        [(0.0, 1.0, "D5"), (1.0, 0.5, "E5"), (1.5, 0.5, "G5"), (2.0, 1.5, "E5"), (3.5, 0.5, "D5")],
        [(0.0, 1.0, "A4"), (1.0, 1.0, "C5"), (2.0, 1.0, "D5"), (3.0, 1.0, "E5")],
        [(0.0, 1.5, "G5"), (1.5, 0.5, "E5"), (2.0, 2.0, "C5")],
        [(0.0, 1.0, "C5"), (1.0, 0.5, "D5"), (1.5, 0.5, "E5"), (2.0, 1.0, "G5"), (3.0, 1.0, "E5")],
        [(0.0, 1.0, "D5"), (1.0, 1.0, "G4"), (2.0, 2.0, "C5")],
    ]
    battle_bass = [
        [(0.0, 0.8, "C3"), (1.0, 0.8, "G3"), (2.0, 0.8, "C3"), (3.0, 0.8, "G3")],
        [(0.0, 0.8, "A3"), (1.0, 0.8, "E3"), (2.0, 0.8, "D3"), (3.0, 0.8, "G3")],
    ]
    battle_drums = [
        (0.0, "kick", 1.0), (1.0, "wood", 0.75), (1.5, "kick", 0.55),
        (2.0, "kick", 0.9), (3.0, "wood", 0.8), (3.5, "wood", 0.55),
    ]
    out["battle"] = render_music_track(115.0, 20, battle_mel, battle_bass, battle_drums, 202602, 0.34, 0.22, 0.24)

    # 3. Trùm (boss.wav): 135 BPM, 24 ô nhịp = 96 phách (~42.67s) - trống trận dồn dập, kịch tính
    boss_mel = [
        [(0.0, 0.5, "A4"), (0.5, 0.5, "C5"), (1.0, 0.5, "E5"), (1.5, 0.5, "A5"), (2.0, 1.0, "G5"), (3.0, 1.0, "E5")],
        [(0.0, 0.75, "D5"), (0.75, 0.75, "E5"), (1.5, 0.5, "G5"), (2.0, 1.5, "A5"), (3.5, 0.5, "G5")],
        [(0.0, 0.5, "C6"), (0.5, 0.5, "A5"), (1.0, 0.5, "G5"), (1.5, 0.5, "E5"), (2.0, 1.0, "D5"), (3.0, 1.0, "E5")],
        [(0.0, 1.0, "A5"), (1.0, 0.5, "G5"), (1.5, 0.5, "E5"), (2.0, 2.0, "A4")],
        [(0.0, 0.5, "E5"), (0.5, 0.5, "G5"), (1.0, 1.0, "A5"), (2.0, 0.5, "C6"), (2.5, 0.5, "D6"), (3.0, 1.0, "C6")],
        [(0.0, 1.0, "A5"), (1.0, 0.5, "G5"), (1.5, 0.5, "E5"), (2.0, 1.0, "D5"), (3.0, 1.0, "C5")],
        [(0.0, 0.5, "A4"), (0.5, 0.5, "C5"), (1.0, 0.5, "D5"), (1.5, 0.5, "E5"), (2.0, 1.0, "G5"), (3.0, 1.0, "E5")],
        [(0.0, 1.5, "A4"), (1.5, 0.5, "C5"), (2.0, 1.0, "E5"), (3.0, 1.0, "A4")],
    ]
    boss_bass = [
        [(0.0, 0.45, "A3"), (0.5, 0.45, "A3"), (1.0, 0.45, "E3"), (1.5, 0.45, "A3"),
         (2.0, 0.45, "A3"), (2.5, 0.45, "G3"), (3.0, 0.45, "E3"), (3.5, 0.45, "G3")],
        [(0.0, 0.45, "D3"), (0.5, 0.45, "D3"), (1.0, 0.45, "A3"), (1.5, 0.45, "D3"),
         (2.0, 0.45, "E3"), (2.5, 0.45, "G3"), (3.0, 0.45, "A3"), (3.5, 0.45, "E3")],
    ]
    boss_drums = [
        (0.0, "kick", 1.0), (0.5, "kick", 0.65), (1.0, "wood", 0.9), (1.5, "kick", 0.7),
        (2.0, "kick", 1.0), (2.5, "wood", 0.65), (3.0, "wood", 0.95), (3.5, "kick", 0.75),
    ]
    out["boss"] = render_music_track(135.0, 24, boss_mel, boss_bass, boss_drums, 202603, 0.35, 0.24, 0.28)

    return out


def main() -> None:
    sfx = gen_sfx()
    for name, samples in sfx.items():
        save_wav(os.path.join(SFX_DIR, f"{name}.wav"), samples)
    music = gen_music()
    for name, samples in music.items():
        save_wav(os.path.join(MUSIC_DIR, f"{name}.wav"), samples)
    print(f"Generated {len(sfx)} SFX and {len(music)} music tracks.")


if __name__ == "__main__":
    main()
