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

    return out


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
