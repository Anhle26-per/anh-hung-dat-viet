"""Sinh toàn bộ hiệu ứng âm thanh (mono 44.1 kHz) và nhạc nền (stereo 44.1 kHz ngũ cung Việt Nam) cho Anh Hùng Đất Việt.

Chỉ dùng thư viện chuẩn Python (wave, struct, math, random, os).
Xuất tệp .wav 16-bit 44100 Hz vào assets/audio/sfx/ (mono) và assets/audio/music/ (stereo có reverb).
Chạy trên Windows: python tools/audio/build_audio.py (hoặc py tools/audio/build_audio.py).
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
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

_TANH_NORM = math.tanh(1.15)


def _soft_clip(x: float) -> float:
    if -0.75 <= x <= 0.75:
        return x
    return math.tanh(x * 1.15) / _TANH_NORM


def save_wav(path: str, samples, peak: float = 0.85) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if isinstance(samples, tuple) and len(samples) == 2:
        left, right = samples
        channels = 2
        max_abs = max(
            max((abs(x) for x in left), default=0.0),
            max((abs(x) for x in right), default=0.0),
        )
        scale = (peak / max_abs) if (max_abs > 1e-6 and (max_abs > peak or max_abs < 0.25)) else 1.0
        pcm = []
        append = pcm.append
        for l_val, r_val in zip(left, right):
            lv = _soft_clip(l_val * scale)
            rv = _soft_clip(r_val * scale)
            append(max(-32767, min(32767, int(round(lv * 32767.0)))))
            append(max(-32767, min(32767, int(round(rv * 32767.0)))))
    else:
        channels = 1
        max_abs = max((abs(x) for x in samples), default=0.0)
        scale = (peak / max_abs) if (max_abs > 1e-6 and (max_abs > peak or max_abs < 0.25)) else 1.0
        pcm = [
            max(-32767, min(32767, int(round(_soft_clip(x * scale) * 32767.0))))
            for x in samples
        ]
    raw = struct.pack(f"<{len(pcm)}h", *pcm) if pcm else b""
    with wave.open(path, "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(raw)


def normalize(samples: list[float], target_peak: float = 0.78) -> list[float]:
    m = max((abs(x) for x in samples), default=0.0)
    if m < 1e-6:
        return samples
    k = target_peak / m
    return [x * k for x in samples]


def normalize_stereo(left: list[float], right: list[float], target_peak: float = 0.78) -> tuple[list[float], list[float]]:
    m = max(max((abs(x) for x in left), default=0.0), max((abs(x) for x in right), default=0.0))
    if m < 1e-6:
        return left, right
    k = target_peak / m
    return ([x * k for x in left], [x * k for x in right])


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

    # ------------------------------------------------------------------ 14 Kỹ năng tướng + Chiêu 2 + Cổ Loa + Ping + Thiên Phú/Thức Tỉnh
    out.update(_gen_hero_skills())
    out.update(_gen_v30_sfx())

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

    # 12. An Dương Vương (Mưa tên Cổ Loa): dây nỏ Kim Quy căng bật + chuông vàng thần khí + loạt tên xuyên
    n = int(0.56 * SAMPLE_RATE)
    buf = [0.0] * n
    snap = _sweep_buf(0.16, 1120.0, 290.0, 312, "tri", 0.36, 0.42, 0.002, 1.8)
    for j, x in enumerate(snap):
        buf[j] += x * 0.75
    _add_bell(buf, 0.03, 0.46, PENTA["D5"], [(1.0, 0.45), (1.5, 0.32), (2.5, 0.22)], 0.48)
    for k, off in enumerate((0.12, 0.21, 0.30, 0.38)):
        bolt = _sweep_buf(0.11, 1480.0 - k * 90.0, 520.0, 3120 + k, "sq25", 0.35, 0.38, 0.002, 2.0)
        i0 = int(off * SAMPLE_RATE)
        for j, x in enumerate(bolt):
            if i0 + j < n:
                buf[i0 + j] += x * 0.45
    skills["skill_an_duong_vuong"] = normalize(buf, 0.86)

    # 13. Lạc Long Quân (Thủy long triều): sóng biển dâng trào + tiếng rồng gầm trầm + linh thủy vang ngân
    rng = random.Random(313)
    n = int(0.62 * SAMPLE_RATE)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        lp = lp * 0.82 + rng.uniform(-1.0, 1.0) * 0.18
        f = 155.0 + 75.0 * math.sin(math.pi * t / 0.55)
        ph += f / SAMPLE_RATE
        wave_surf = lp * math.sin(math.pi * min(1.0, t / 0.55)) * 0.72
        roar = (0.55 * math.sin(2.0 * math.pi * ph) + 0.30 * triangle(ph * 1.5)) * env_asr(t, 0.62, 0.06, 0.22) * 0.55
        buf.append(wave_surf + roar)
    _add_bell(buf, 0.08, 0.44, PENTA["E5"], [(1.0, 0.42), (1.5, 0.26), (2.0, 0.20)], 0.42)
    skills["skill_lac_long_quan"] = normalize(buf, 0.86)

    # 14. Sơn Tinh (Dời non lấp bể): địa chấn gầm vang + 3 trụ đá trồi lên + chuông núi Tản Viên
    n = int(0.60 * SAMPLE_RATE)
    buf = [0.0] * n
    rumble = _sweep_buf(0.58, 128.0, 44.0, 314, "sin", 0.55, 0.82, 0.02, 1.4, 1.0, 0.5)
    for j, x in enumerate(rumble):
        buf[j] += x * 0.70
    for k, off in enumerate((0.02, 0.15, 0.28)):
        pillar = _sweep_buf(0.18, 220.0 + k * 45.0, 68.0, 3140 + k, "tri", 0.42, 0.68, 0.004, 1.9)
        i0 = int(off * SAMPLE_RATE)
        for j, x in enumerate(pillar):
            if i0 + j < n:
                buf[i0 + j] += x * 0.58
    _add_bell(buf, 0.05, 0.48, 293.66, [(1.0, 0.50), (1.49, 0.30), (2.02, 0.18)], 0.46)
    skills["skill_son_tinh"] = normalize(buf, 0.87)

    return skills


def _gen_v30_sfx() -> dict[str, list[float]]:
    out: dict[str, list[float]] = {}

    # skill2_cast: hào quang ngân vang khi tung Chiêu 2
    n = int(0.32 * SAMPLE_RATE)
    buf = [0.0] * n
    add_tone_seq(buf, [(0.0, 0.11, "tri", PENTA["D5"]), (0.05, 0.14, "tri", PENTA["A5"]), (0.10, 0.20, "sin", PENTA["D6"])], 0.45)
    _add_bell(buf, 0.02, 0.26, PENTA["A5"], [(1.0, 0.4), (1.5, 0.25)], 0.35)
    out["skill2_cast"] = normalize(buf, 0.80)

    # tower_build: đóng cọc gỗ & đặt bệ đá dựng tháp Cổ Loa
    n = int(0.28 * SAMPLE_RATE)
    buf = [0.0] * n
    thud = _sweep_buf(0.14, 195.0, 62.0, 501, "sin", 0.40, 0.65, 0.002, 1.9)
    for j, x in enumerate(thud):
        buf[j] += x * 0.72
    add_tone_seq(buf, [(0.06, 0.08, "tri", PENTA["D4"]), (0.13, 0.12, "tri", PENTA["A4"])], 0.46)
    out["tower_build"] = normalize(buf, 0.82)

    # tower_upgrade: gõ đe ánh kim + hợp âm thăng cấp 3 nốt
    n = int(0.34 * SAMPLE_RATE)
    buf = [0.0] * n
    _add_bell(buf, 0.0, 0.24, 920.0, [(1.0, 0.45), (1.52, 0.30), (2.3, 0.20)], 0.48)
    add_tone_seq(buf, [(0.04, 0.09, "tri", PENTA["E5"]), (0.11, 0.09, "tri", PENTA["G5"]), (0.18, 0.15, "sin", PENTA["C6"])], 0.44)
    out["tower_upgrade"] = normalize(buf, 0.82)

    # core_repair: hàn ngọc nỏ thần + hồi phục ánh sáng
    n = int(0.30 * SAMPLE_RATE)
    buf = [0.0] * n
    add_tone_seq(buf, [(0.0, 0.10, "sin", PENTA["C5"]), (0.06, 0.11, "sin", PENTA["E5"]), (0.12, 0.17, "sin", PENTA["G5"])], 0.48)
    _add_bell(buf, 0.08, 0.20, PENTA["C6"], [(1.0, 0.38), (1.5, 0.20)], 0.32)
    out["core_repair"] = normalize(buf, 0.78)

    # core_crossbow: Nỏ Thần Kim Quy bật dây + luồng sáng xuyên
    n = int(0.24 * SAMPLE_RATE)
    buf = _sweep_buf(0.24, 1320.0, 410.0, 504, "tri", 0.30, 0.35, 0.002, 1.8)
    _add_bell(buf, 0.01, 0.18, PENTA["A5"], [(1.0, 0.40), (2.0, 0.25)], 0.38)
    out["core_crossbow"] = normalize(buf, 0.84)

    # war_drum: hồi trống đồng Cổ Loa xuất quân (2 nhịp trống + ngân đồng)
    n = int(0.55 * SAMPLE_RATE)
    buf = [0.0] * n
    d1 = _sweep_buf(0.24, 155.0, 46.0, 505, "sin", 0.34, 0.78, 0.003, 1.5, 1.0, 0.45)
    d2 = _sweep_buf(0.36, 175.0, 42.0, 506, "sin", 0.36, 0.80, 0.003, 1.4, 1.0, 0.50)
    for j, x in enumerate(d1):
        buf[j] += x * 0.72
    i2 = int(0.16 * SAMPLE_RATE)
    for j, x in enumerate(d2):
        if i2 + j < n:
            buf[i2 + j] += x * 0.90
    _add_bell(buf, 0.16, 0.35, 220.0, [(1.0, 0.35), (1.5, 0.25), (2.1, 0.14)], 0.40)
    out["war_drum"] = normalize(buf, 0.88)

    # core_alarm: chuông cảnh báo Nỏ Thần nguy cấp (2 hồi ngân gấp)
    n = int(0.42 * SAMPLE_RATE)
    buf = [0.0] * n
    add_tone_seq(buf, [(0.0, 0.14, "sq25", 740.0), (0.18, 0.20, "sq25", 880.0)], 0.38)
    _add_bell(buf, 0.0, 0.18, 740.0, [(1.0, 0.45), (1.42, 0.30)], 0.36)
    _add_bell(buf, 0.18, 0.22, 880.0, [(1.0, 0.45), (1.42, 0.30)], 0.38)
    out["core_alarm"] = normalize(buf, 0.82)

    # 4 Ping chiến thuật LAN
    for name, notes in (
        ("ping_focus", [(0.0, 0.08, "tri", PENTA["G5"]), (0.06, 0.14, "sin", PENTA["D6"])]),
        ("ping_danger", [(0.0, 0.09, "sq25", 622.25), (0.08, 0.14, "sq25", 466.16)]),
        ("ping_loot", [(0.0, 0.07, "tri", PENTA["E5"]), (0.05, 0.08, "tri", PENTA["G5"]), (0.10, 0.14, "sin", PENTA["C6"])]),
        ("ping_combo", [(0.0, 0.08, "tri", PENTA["A5"]), (0.06, 0.15, "sin", PENTA["E6"])]),
    ):
        pbuf = [0.0] * int(0.24 * SAMPLE_RATE)
        add_tone_seq(pbuf, notes, 0.55)
        out[name] = normalize(pbuf, 0.78)

    # skill_tree_unlock: khánh ngọc thiên phú vang sáng
    buf = [0.0] * int(0.34 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.10, "tri", PENTA["C5"]), (0.07, 0.10, "tri", PENTA["E5"]), (0.14, 0.18, "sin", PENTA["G5"])], 0.45)
    _add_bell(buf, 0.12, 0.20, PENTA["C6"], [(1.0, 0.42), (1.5, 0.24)], 0.36)
    out["skill_tree_unlock"] = normalize(buf, 0.80)

    # pet_awaken: hồi chuông thức tỉnh Thần Thú
    buf = [0.0] * int(0.48 * SAMPLE_RATE)
    add_tone_seq(buf, [(0.0, 0.10, "tri", PENTA["D5"]), (0.08, 0.10, "tri", PENTA["G5"]), (0.16, 0.12, "tri", PENTA["A5"]), (0.25, 0.22, "sin", PENTA["D6"])], 0.46)
    _add_bell(buf, 0.22, 0.24, PENTA["D6"], [(1.0, 0.45), (1.5, 0.30)], 0.40)
    out["pet_awaken"] = normalize(buf, 0.84)

    return out


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

def _build_notes() -> dict[str, float]:
    """Bảng cao độ đầy đủ (chromatic + ngũ cung Bắc/Nam + quãng căng) quãng tám 2..6."""
    semis = {
        "C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3,
        "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8,
        "A": 9, "A#": 10, "Bb": 10, "B": 11,
    }
    notes: dict[str, float] = {}
    for octv in range(2, 7):
        for name, st in semis.items():
            midi = 12 * (octv + 1) + st
            notes[f"{name}{octv}"] = 440.0 * (2.0 ** ((midi - 69) / 12.0))
    return notes


NOTES: dict[str, float] = _build_notes()


def add_flute_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.32) -> None:
    """Tiếng sáo trúc: sóng sin + hài nhẹ + vibrato hơi thở, ghi vòng tròn để lặp liền mạch."""
    total = len(buf)
    sr = SAMPLE_RATE
    i0 = int(round(start_s * sr))
    n = int(round(dur_s * sr))
    if n <= 0:
        return
    phase = 0.0
    attack = min(0.045, dur_s * 0.25)
    release = min(0.075, dur_s * 0.3)
    pi2 = 2.0 * math.pi
    inv_sr = 1.0 / sr
    for j in range(n):
        t = j * inv_sr
        vib = 1.0 + (0.011 if t > 0.06 else 0.0) * math.sin(pi2 * 5.5 * t)
        phase += freq * vib * inv_sr
        ang = pi2 * phase
        w = 0.82 * math.sin(ang) + 0.14 * math.sin(2.0 * ang) + 0.04 * math.sin(3.0 * ang)
        buf[(i0 + j) % total] += w * env_asr(t, dur_s, attack, release) * vol


def add_pluck_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.2) -> None:
    """Tiếng đàn gảy nhẹ (tam giác + sin suy giảm), ghi vòng tròn."""
    total = len(buf)
    sr = SAMPLE_RATE
    i0 = int(round(start_s * sr))
    n = int(round(dur_s * sr))
    if n <= 0:
        return
    phase = 0.0
    pi2 = 2.0 * math.pi
    inc = freq / sr
    inv_sr = 1.0 / sr
    for j in range(n):
        t = j * inv_sr
        phase += inc
        w = 0.65 * math.sin(pi2 * phase) + 0.35 * triangle(phase)
        buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.005, 2.2) * vol


def add_dan_tranh_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.22) -> None:
    """Tiếng đàn tranh: gảy dây kim loại sáng + hài âm lấp lánh + ngân nhẹ, ghi vòng tròn."""
    total = len(buf)
    sr = SAMPLE_RATE
    i0 = int(round(start_s * sr))
    n = int(round(dur_s * sr))
    if n <= 0:
        return
    ph1 = 0.0
    ph2 = 0.0
    inc1 = freq / sr
    inc2 = (freq * 1.003) / sr
    pi2 = 2.0 * math.pi
    inv_sr = 1.0 / sr
    for j in range(n):
        t = j * inv_sr
        ph1 += inc1
        ph2 += inc2
        a1 = pi2 * ph1
        bright = math.exp(-t * 9.0)
        w = (
            0.52 * math.sin(a1)
            + 0.24 * math.sin(2.0 * a1) * (0.45 + 0.55 * bright)
            + 0.14 * math.sin(3.0 * a1) * bright
            + 0.10 * math.sin(pi2 * ph2 * 2.0)
        )
        buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.003, 1.9) * vol


def add_lead_sq_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.24, duty: float = 0.25) -> None:
    """Lead 8-bit xung 25% duty sắc nét cho giai điệu chiến trận, ghi vòng tròn."""
    total = len(buf)
    sr = SAMPLE_RATE
    i0 = int(round(start_s * sr))
    n = int(round(dur_s * sr))
    if n <= 0:
        return
    phase = 0.0
    attack = min(0.012, dur_s * 0.12)
    release = min(0.045, dur_s * 0.25)
    pi2 = 2.0 * math.pi
    inv_sr = 1.0 / sr
    for j in range(n):
        t = j * inv_sr
        vib = 1.0 + (0.006 if t > 0.08 else 0.0) * math.sin(pi2 * 6.0 * t)
        phase += freq * vib * inv_sr
        w = 0.82 * square(phase, duty) + 0.18 * triangle(phase)
        buf[(i0 + j) % total] += w * env_asr(t, dur_s, attack, release) * vol


def add_brass_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.26) -> None:
    """Tiếng kèn đồng hào hùng (saw + square ấm có lọc thông thấp nhẹ), ghi vòng tròn."""
    total = len(buf)
    sr = SAMPLE_RATE
    i0 = int(round(start_s * sr))
    n = int(round(dur_s * sr))
    if n <= 0:
        return
    ph1 = 0.0
    ph2 = 0.0
    lp = 0.0
    inc1 = freq / sr
    inc2 = (freq * 1.004) / sr
    attack = min(0.032, dur_s * 0.2)
    release = min(0.06, dur_s * 0.25)
    inv_sr = 1.0 / sr
    for j in range(n):
        t = j * inv_sr
        ph1 += inc1
        ph2 += inc2
        saw = 2.0 * (ph1 % 1.0) - 1.0
        sq = square(ph2, 0.42)
        raw = 0.6 * saw + 0.4 * sq
        lp = lp * 0.42 + raw * 0.58
        buf[(i0 + j) % total] += lp * env_asr(t, dur_s, attack, release) * vol


def add_pad_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.16) -> None:
    """Nền hợp âm / drone ấm áp (sin + quãng 5 + quãng 8 ngân chậm), ghi vòng tròn."""
    total = len(buf)
    sr = SAMPLE_RATE
    i0 = int(round(start_s * sr))
    n = int(round(dur_s * sr))
    if n <= 0:
        return
    ph1 = 0.0
    ph2 = 0.0
    inc1 = freq / sr
    inc2 = (freq * 1.0025) / sr
    attack = min(0.18, dur_s * 0.3)
    release = min(0.24, dur_s * 0.35)
    pi2 = 2.0 * math.pi
    inv_sr = 1.0 / sr
    for j in range(n):
        t = j * inv_sr
        ph1 += inc1
        ph2 += inc2
        a1 = pi2 * ph1
        a2 = pi2 * ph2
        w = 0.55 * math.sin(a1) + 0.22 * math.sin(2.0 * a1) + 0.15 * math.sin(1.5 * a2) + 0.08 * triangle(ph2)
        buf[(i0 + j) % total] += w * env_asr(t, dur_s, attack, release) * vol


def add_bass_loop(buf: list[float], start_s: float, dur_s: float, freq: float, vol: float = 0.28) -> None:
    """Tiếng bass dày (tam giác + sub-sine quãng tám dưới), ghi vòng tròn."""
    total = len(buf)
    sr = SAMPLE_RATE
    i0 = int(round(start_s * sr))
    n = int(round(dur_s * sr))
    if n <= 0:
        return
    ph = 0.0
    ph_sub = 0.0
    inc = freq / sr
    inc_sub = (freq * 0.5) / sr
    pi2 = 2.0 * math.pi
    inv_sr = 1.0 / sr
    for j in range(n):
        t = j * inv_sr
        ph += inc
        ph_sub += inc_sub
        w = 0.58 * triangle(ph) + 0.42 * math.sin(pi2 * ph_sub)
        buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.005, 1.35) * vol


def add_drum_loop(buf: list[float], start_s: float, rng: random.Random, kind: str = "kick", vol: float = 0.35) -> None:
    """Bộ gõ dân gian + chiến trận (kick, wood, snare, hat, gong), ghi vòng tròn."""
    total = len(buf)
    sr = SAMPLE_RATE
    i0 = int(round(start_s * sr))
    pi2 = 2.0 * math.pi
    inv_sr = 1.0 / sr
    if kind == "kick":
        dur_s = 0.22
        n = int(dur_s * sr)
        ph = 0.0
        lp = 0.0
        for j in range(n):
            t = j * inv_sr
            f = 138.0 * (0.26 ** (t / dur_s)) + 42.0
            ph += f * inv_sr
            lp = lp * 0.72 + rng.uniform(-1.0, 1.0) * 0.28
            w = 0.78 * math.sin(pi2 * ph) + 0.32 * lp
            buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.003, 2.2) * vol
    elif kind == "snare":
        dur_s = 0.14
        n = int(dur_s * sr)
        ph = 0.0
        prev = 0.0
        for j in range(n):
            t = j * inv_sr
            f = 215.0 * (0.55 ** (t / dur_s)) + 95.0
            ph += f * inv_sr
            nz = rng.uniform(-1.0, 1.0)
            hp = nz - 0.55 * prev
            prev = nz
            w = 0.38 * math.sin(pi2 * ph) + 0.62 * hp
            buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.002, 2.5) * vol
    elif kind == "hat":
        dur_s = 0.055
        n = int(dur_s * sr)
        prev = 0.0
        for j in range(n):
            t = j * inv_sr
            nz = rng.uniform(-1.0, 1.0)
            hp = nz - 0.82 * prev
            prev = nz
            buf[(i0 + j) % total] += hp * env_ad(t, dur_s, 0.001, 3.2) * vol * 0.65
    elif kind == "gong":
        dur_s = 1.35
        n = int(dur_s * sr)
        ph = 0.0
        base_f = 132.0
        partials = ((1.0, 0.45), (1.48, 0.28), (2.13, 0.18), (2.86, 0.10))
        for j in range(n):
            t = j * inv_sr
            f = 115.0 * (0.35 ** (t / 0.35)) + 52.0
            ph += f * inv_sr
            bell = 0.0
            for ratio, amp in partials:
                bell += amp * math.sin(pi2 * base_f * ratio * t) * math.exp(-t * (1.8 + ratio * 0.9))
            w = 0.35 * math.sin(pi2 * ph) * math.exp(-t * 3.8) + 0.65 * bell
            buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.006, 1.2) * vol
    else:
        # "wood": mõ / phách tre gõ giòn
        dur_s = 0.095
        n = int(dur_s * sr)
        ph = 0.0
        for j in range(n):
            t = j * inv_sr
            f = 690.0 * (0.68 ** (t / dur_s)) + 190.0
            ph += f * inv_sr
            click = rng.uniform(-1.0, 1.0) * max(0.0, 1.0 - t / 0.015)
            w = 0.78 * math.sin(pi2 * ph) + 0.22 * click
            buf[(i0 + j) % total] += w * env_ad(t, dur_s, 0.0015, 2.9) * vol


def _add_layer_note(buf: list[float], inst: str, start_s: float, dur_s: float, note: str, vol: float) -> None:
    freq = NOTES[note]
    if inst == "flute":
        add_flute_loop(buf, start_s, dur_s, freq, vol)
    elif inst == "dan_tranh":
        add_dan_tranh_loop(buf, start_s, dur_s, freq, vol)
    elif inst == "sq25":
        add_lead_sq_loop(buf, start_s, dur_s, freq, vol, 0.25)
    elif inst == "brass":
        add_brass_loop(buf, start_s, dur_s, freq, vol)
    elif inst == "pad":
        add_pad_loop(buf, start_s, dur_s, freq, vol)
    elif inst == "bass":
        add_bass_loop(buf, start_s, dur_s, freq, vol)
    else:
        add_pluck_loop(buf, start_s, dur_s, freq, vol)


_INST_PAN = {
    "flute": -0.22,
    "dan_tranh": 0.28,
    "pluck": 0.18,
    "sq25": -0.14,
    "brass": 0.0,
    "pad": 0.0,
    "bass": 0.0,
}


def _apply_warm_lp(buf: list[float], alpha: float) -> list[float]:
    prev = buf[-1] if buf else 0.0
    out = [0.0] * len(buf)
    a1 = 1.0 - alpha
    for i, x in enumerate(buf):
        prev = alpha * x + a1 * prev
        out[i] = prev
    return out


def _apply_circular_stereo_reverb(left: list[float], right: list[float], wet: float = 0.16) -> tuple[list[float], list[float]]:
    total = len(left)
    if total == 0 or wet <= 0.0:
        return left, right
    taps_ms = (29, 43, 61, 83)
    dels = [int(ms * SAMPLE_RATE / 1000.0) % total for ms in taps_ms]
    gains = (0.38, 0.28, 0.20, 0.14)
    out_l = [0.0] * total
    out_r = [0.0] * total
    d0, d1, d2, d3 = dels
    g0, g1, g2, g3 = gains
    for i in range(total):
        rev_l = (
            right[(i - d0) % total] * g0
            + left[(i - d1) % total] * g1
            + right[(i - d2) % total] * g2
            + left[(i - d3) % total] * g3
        )
        rev_r = (
            left[(i - d0) % total] * g0
            + right[(i - d1) % total] * g1
            + left[(i - d2) % total] * g2
            + right[(i - d3) % total] * g3
        )
        out_l[i] = left[i] + wet * rev_l
        out_r[i] = right[i] + wet * rev_r
    return out_l, out_r


def render_arranged_track(
    bpm: float,
    bars: int,
    layers: list[tuple[str, float, list[list[tuple[float, float, str]]]]],
    drum_bars: list[list[tuple[float, str, float]]],
    seed: int,
    drum_vol: float,
    beats_per_bar: float = 4.0,
    peak: float = 0.74,
) -> tuple[list[float], list[float]]:
    beat_s = 60.0 / bpm
    total_beats = bars * beats_per_bar
    total_samples = int(round(total_beats * beat_s * SAMPLE_RATE))
    buf_l = [0.0] * total_samples
    buf_r = [0.0] * total_samples
    rng = random.Random(seed)
    haas_wide = int(0.014 * SAMPLE_RATE)
    haas_brass = int(0.009 * SAMPLE_RATE)

    for inst, vol, pat_bars in layers:
        lbuf = [0.0] * total_samples
        for b in range(bars):
            bar_beat = b * beats_per_bar
            for beat_off, dur_beats, note in pat_bars[b % len(pat_bars)]:
                _add_layer_note(lbuf, inst, (bar_beat + beat_off) * beat_s, dur_beats * beat_s, note, vol)
        if inst == "sq25":
            lbuf = _apply_warm_lp(lbuf, 0.56)
        if inst in ("pad", "brass"):
            d_off = haas_wide if inst == "pad" else haas_brass
            for i in range(total_samples):
                x = lbuf[i]
                xd = lbuf[(i - d_off) % total_samples]
                buf_l[i] += 0.78 * x + 0.24 * xd
                buf_r[i] += 0.78 * xd + 0.24 * x
        else:
            pan = _INST_PAN.get(inst, 0.0)
            gl = 0.5 * (1.0 - pan) * 1.35
            gr = 0.5 * (1.0 + pan) * 1.35
            for i, x in enumerate(lbuf):
                if x != 0.0:
                    buf_l[i] += x * gl
                    buf_r[i] += x * gr

    if drum_bars:
        dc_buf = [0.0] * total_samples
        ds_buf = [0.0] * total_samples
        dh_buf = [0.0] * total_samples
        dw_buf = [0.0] * total_samples
        for b in range(bars):
            bar_beat = b * beats_per_bar
            for beat_off, dkind, dmul in drum_bars[b % len(drum_bars)]:
                target = dc_buf
                if dkind == "snare":
                    target = ds_buf
                elif dkind == "hat":
                    target = dh_buf
                elif dkind == "wood":
                    target = dw_buf
                add_drum_loop(target, (bar_beat + beat_off) * beat_s, rng, dkind, drum_vol * dmul)
        for i in range(total_samples):
            c = dc_buf[i]
            s = ds_buf[i]
            h = dh_buf[i]
            w = dw_buf[i]
            buf_l[i] += c + 0.74 * s + 0.52 * h + 0.80 * w
            buf_r[i] += c + 0.62 * s + 0.84 * h + 0.56 * w

    buf_l, buf_r = _apply_circular_stereo_reverb(buf_l, buf_r, 0.16)
    return normalize_stereo(buf_l, buf_r, peak)


def gen_music() -> dict[str, tuple[list[float], list[float]]]:
    out: dict[str, tuple[list[float], list[float]]] = {}

    # 1. lobby.wav (~45.18s, 85 BPM, 16 bars) - Doanh Trại Yên Bình
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
    lobby_dan = [
        [(0.0, 0.9, "C5"), (0.5, 0.9, "E5"), (1.0, 0.9, "G5"), (2.0, 0.9, "G4"), (2.5, 0.9, "C5"), (3.0, 0.9, "E5")],
        [(0.0, 0.9, "A4"), (0.5, 0.9, "C5"), (1.0, 0.9, "E5"), (2.0, 0.9, "G4"), (2.5, 0.9, "D5"), (3.0, 0.9, "G5")],
    ]
    lobby_pad = [[(0.0, 3.9, "C3")], [(0.0, 3.9, "G3")], [(0.0, 3.9, "D3")], [(0.0, 3.9, "A3")]]
    lobby_bass = [
        [(0.0, 1.6, "C3"), (2.0, 1.6, "G3")],
        [(0.0, 1.6, "A2"), (2.0, 1.6, "E3")],
        [(0.0, 1.6, "D3"), (2.0, 1.6, "A3")],
        [(0.0, 1.6, "G2"), (2.0, 1.6, "D3")],
    ]
    lobby_drums = [[(0.0, "kick", 0.65), (2.0, "wood", 0.55), (3.0, "kick", 0.45), (3.5, "hat", 0.35)]]
    out["lobby"] = render_arranged_track(
        85.0, 16,
        [("flute", 0.30, lobby_mel), ("dan_tranh", 0.16, lobby_dan), ("pad", 0.12, lobby_pad), ("bass", 0.22, lobby_bass)],
        lobby_drums, 202601, 0.16, peak=0.70,
    )

    # 2. basement.wav (~38.40s, 75 BPM, 12 bars) - Tầng Hầm Chiến Tích
    base_pad = [
        [(0.0, 3.9, "A2"), (0.0, 3.9, "E3")],
        [(0.0, 3.9, "F2"), (0.0, 3.9, "C3")],
        [(0.0, 3.9, "D3"), (0.0, 3.9, "A3")],
        [(0.0, 3.9, "E2"), (0.0, 3.9, "B2")],
    ]
    base_dan = [
        [(0.0, 1.2, "A4"), (1.0, 1.2, "C5"), (2.0, 1.2, "E5"), (3.0, 1.0, "B4")],
        [(0.0, 1.2, "F4"), (1.0, 1.2, "A4"), (2.0, 1.2, "C5"), (3.0, 1.0, "E5")],
        [(0.0, 1.2, "D4"), (1.0, 1.2, "F4"), (2.0, 1.2, "A4"), (3.0, 1.0, "G4")],
        [(0.0, 1.2, "E4"), (1.0, 1.2, "G#4"), (2.0, 1.2, "B4"), (3.0, 1.0, "E5")],
    ]
    base_flute = [
        [(0.5, 2.2, "E5"), (3.0, 1.0, "D5")],
        [(0.0, 2.5, "C5")],
        [(0.5, 1.8, "A4"), (2.5, 1.5, "B4")],
        [(0.0, 3.2, "E4")],
    ]
    base_bass = [[(0.0, 3.5, "A2")], [(0.0, 3.5, "F2")], [(0.0, 3.5, "D2")], [(0.0, 3.5, "E2")]]
    base_drums = [
        [(0.0, "gong", 0.55), (2.0, "wood", 0.45), (3.5, "hat", 0.35)],
        [(0.0, "kick", 0.5), (2.0, "wood", 0.5), (3.0, "hat", 0.3)],
    ]
    out["basement"] = render_arranged_track(
        75.0, 12,
        [("flute", 0.25, base_flute), ("dan_tranh", 0.22, base_dan), ("pad", 0.17, base_pad), ("bass", 0.22, base_bass)],
        base_drums, 202602, 0.16, peak=0.70,
    )

    # 3. battle.wav (~41.74s, 115 BPM, 20 bars) - Hành Quân Khởi Nghĩa (Bắc pentatonic C-D-E-G-A)
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
    battle_brass = [
        [(0.0, 0.6, "C4"), (2.0, 0.8, "G4")],
        [(0.0, 0.6, "E4"), (2.0, 0.8, "C4")],
        [(0.0, 0.6, "A3"), (2.0, 0.8, "E4")],
        [(0.0, 0.6, "G3"), (2.0, 0.8, "D4")],
    ]
    battle_bass = [
        [(0.0, 0.85, "C3"), (1.0, 0.85, "G3"), (2.0, 0.85, "C3"), (3.0, 0.85, "G3")],
        [(0.0, 0.85, "A2"), (1.0, 0.85, "E3"), (2.0, 0.85, "D3"), (3.0, 0.85, "G3")],
    ]
    battle_drums = [[
        (0.0, "kick", 1.0), (0.5, "hat", 0.5), (1.0, "snare", 0.78), (1.5, "kick", 0.58),
        (2.0, "kick", 0.92), (2.5, "hat", 0.5), (3.0, "snare", 0.82), (3.5, "wood", 0.6),
    ]]
    out["battle"] = render_arranged_track(
        115.0, 20,
        [("flute", 0.28, battle_mel), ("sq25", 0.18, battle_mel), ("brass", 0.16, battle_brass), ("bass", 0.25, battle_bass)],
        battle_drums, 202603, 0.24,
    )

    # 4. battle_forest.wav (~37.24s, 116 BPM, 18 bars) - Đại Ngàn Mai Phục (D minor / Nam pentatonic)
    forest_flute = [
        [(0.0, 0.75, "D5"), (0.75, 0.75, "F5"), (1.5, 0.5, "G5"), (2.0, 1.0, "A5"), (3.0, 1.0, "F5")],
        [(0.0, 0.75, "E5"), (0.75, 0.75, "D5"), (1.5, 0.5, "C5"), (2.0, 2.0, "D5")],
        [(0.0, 0.5, "A5"), (0.5, 0.5, "Bb5"), (1.0, 1.0, "A5"), (2.0, 0.75, "G5"), (2.75, 0.75, "F5"), (3.5, 0.5, "E5")],
        [(0.0, 1.5, "F5"), (1.5, 0.5, "E5"), (2.0, 2.0, "D5")],
        [(0.0, 0.5, "D5"), (0.5, 0.5, "A4"), (1.0, 1.0, "F5"), (2.0, 1.0, "G5"), (3.0, 1.0, "A5")],
        [(0.0, 1.0, "C6"), (1.0, 0.5, "Bb5"), (1.5, 0.5, "A5"), (2.0, 2.0, "G5")],
    ]
    forest_dan = [
        [(0.0, 0.5, "D4"), (0.5, 0.5, "A4"), (1.0, 0.5, "F5"), (1.5, 0.5, "A4"), (2.0, 0.5, "D4"), (2.5, 0.5, "A4"), (3.0, 0.5, "F5"), (3.5, 0.5, "A4")],
        [(0.0, 0.5, "Bb3"), (0.5, 0.5, "F4"), (1.0, 0.5, "D5"), (1.5, 0.5, "F4"), (2.0, 0.5, "C4"), (2.5, 0.5, "G4"), (3.0, 0.5, "E5"), (3.5, 0.5, "G4")],
    ]
    forest_bass = [
        [(0.0, 0.85, "D3"), (1.5, 0.45, "A2"), (2.0, 0.85, "D3"), (3.0, 0.85, "C3")],
        [(0.0, 0.85, "Bb2"), (1.5, 0.45, "F3"), (2.0, 0.85, "C3"), (3.0, 0.85, "A2")],
    ]
    forest_drums = [[
        (0.0, "kick", 0.95), (0.5, "wood", 0.65), (1.0, "wood", 0.85), (1.5, "hat", 0.6),
        (2.0, "kick", 0.9), (2.5, "wood", 0.55), (3.0, "snare", 0.72), (3.5, "wood", 0.75),
    ]]
    out["battle_forest"] = render_arranged_track(
        116.0, 18,
        [("flute", 0.30, forest_flute), ("dan_tranh", 0.21, forest_dan), ("pad", 0.11, [[(0.0, 3.8, "D3")], [(0.0, 3.8, "Bb2")]]), ("bass", 0.25, forest_bass)],
        forest_drums, 202604, 0.24,
    )

    # 5. battle_river.wav (~38.57s, 112 BPM, 18 bars) - Sóng Gió Bạch Đằng (G Dorian / flowing wave arps)
    river_mel = [
        [(0.0, 1.0, "G5"), (1.0, 0.5, "A5"), (1.5, 0.5, "Bb5"), (2.0, 1.0, "D6"), (3.0, 1.0, "C6")],
        [(0.0, 0.75, "Bb5"), (0.75, 0.75, "A5"), (1.5, 0.5, "G5"), (2.0, 2.0, "F5")],
        [(0.0, 1.0, "Eb5"), (1.0, 1.0, "F5"), (2.0, 1.0, "G5"), (3.0, 1.0, "Bb5")],
        [(0.0, 1.5, "A5"), (1.5, 0.5, "G5"), (2.0, 2.0, "D5")],
        [(0.0, 0.75, "G5"), (0.75, 0.75, "Bb5"), (1.5, 0.5, "C6"), (2.0, 1.0, "D6"), (3.0, 1.0, "Bb5")],
        [(0.0, 1.0, "C6"), (1.0, 0.5, "Bb5"), (1.5, 0.5, "A5"), (2.0, 2.0, "G5")],
    ]
    river_dan = [
        [(0.0, 0.55, "G4"), (0.5, 0.55, "D5"), (1.0, 0.55, "Bb5"), (1.5, 0.55, "D5"), (2.0, 0.55, "G4"), (2.5, 0.55, "D5"), (3.0, 0.55, "A5"), (3.5, 0.55, "D5")],
        [(0.0, 0.55, "Eb4"), (0.5, 0.55, "Bb4"), (1.0, 0.55, "G5"), (1.5, 0.55, "Bb4"), (2.0, 0.55, "F4"), (2.5, 0.55, "C5"), (3.0, 0.55, "A5"), (3.5, 0.55, "C5")],
    ]
    river_brass = [
        [(0.0, 0.9, "G3"), (2.0, 0.9, "D4")],
        [(0.0, 0.9, "Eb3"), (2.0, 0.9, "F3")],
    ]
    river_bass = [
        [(0.0, 0.9, "G2"), (1.0, 0.9, "D3"), (2.0, 0.9, "G2"), (3.0, 0.9, "D3")],
        [(0.0, 0.9, "Eb2"), (1.0, 0.9, "Bb2"), (2.0, 0.9, "F2"), (3.0, 0.9, "C3")],
    ]
    river_drums = [
        [(0.0, "kick", 0.95), (1.0, "snare", 0.72), (1.5, "kick", 0.65), (2.0, "kick", 0.9), (2.5, "hat", 0.55), (3.0, "snare", 0.78), (3.5, "wood", 0.6)],
        [(0.0, "gong", 0.7), (0.0, "kick", 0.95), (1.0, "snare", 0.75), (2.0, "kick", 0.9), (3.0, "snare", 0.8), (3.5, "hat", 0.55)],
    ]
    out["battle_river"] = render_arranged_track(
        112.0, 18,
        [("flute", 0.26, river_mel), ("dan_tranh", 0.20, river_dan), ("brass", 0.18, river_brass), ("bass", 0.25, river_bass)],
        river_drums, 202605, 0.24,
    )

    # 6. battle_citadel.wav (~37.38s, 122 BPM, 19 bars) - Khí Phách Thăng Long (E minor heroic royal march)
    cit_lead = [
        [(0.0, 0.75, "E5"), (0.75, 0.25, "G5"), (1.0, 1.0, "B5"), (2.0, 0.5, "A5"), (2.5, 0.5, "G5"), (3.0, 1.0, "F#5")],
        [(0.0, 0.75, "G5"), (0.75, 0.75, "F#5"), (1.5, 0.5, "E5"), (2.0, 1.5, "B4"), (3.5, 0.5, "D5")],
        [(0.0, 0.75, "E5"), (0.75, 0.75, "G5"), (1.5, 0.5, "B5"), (2.0, 1.0, "D6"), (3.0, 1.0, "B5")],
        [(0.0, 1.0, "A5"), (1.0, 0.5, "G5"), (1.5, 0.5, "F#5"), (2.0, 2.0, "E5")],
    ]
    cit_brass = [
        [(0.0, 0.7, "E3"), (0.0, 0.7, "B3"), (2.0, 0.7, "E4")],
        [(0.0, 0.7, "C3"), (0.0, 0.7, "G3"), (2.0, 0.7, "D4")],
        [(0.0, 0.7, "A3"), (0.0, 0.7, "E4"), (2.0, 0.7, "B3")],
        [(0.0, 0.7, "B3"), (0.0, 0.7, "F#4"), (2.0, 0.7, "E4")],
    ]
    cit_bass = [
        [(0.0, 0.45, "E3"), (0.5, 0.45, "E3"), (1.0, 0.45, "B2"), (1.5, 0.45, "E3"), (2.0, 0.45, "E3"), (2.5, 0.45, "G3"), (3.0, 0.45, "F#3"), (3.5, 0.45, "D3")],
        [(0.0, 0.45, "C3"), (0.5, 0.45, "C3"), (1.0, 0.45, "G2"), (1.5, 0.45, "C3"), (2.0, 0.45, "D3"), (2.5, 0.45, "A2"), (3.0, 0.45, "B2"), (3.5, 0.45, "B2")],
    ]
    cit_drums = [[
        (0.0, "kick", 1.0), (0.5, "hat", 0.55), (1.0, "snare", 0.85), (1.5, "kick", 0.65),
        (2.0, "kick", 0.95), (2.5, "hat", 0.55), (3.0, "snare", 0.9), (3.5, "snare", 0.55),
    ]]
    out["battle_citadel"] = render_arranged_track(
        122.0, 19,
        [("sq25", 0.20, cit_lead), ("flute", 0.22, cit_lead), ("brass", 0.20, cit_brass), ("bass", 0.26, cit_bass)],
        cit_drums, 202606, 0.26,
    )

    # 7. battle_modern.wav (~36.19s, 126 BPM, 19 bars) - Tiến Quân Điện Biên (G major / F# militant anthem)
    mod_lead = [
        [(0.0, 0.75, "D5"), (0.75, 0.25, "D5"), (1.0, 1.0, "G5"), (2.0, 0.75, "G5"), (2.75, 0.25, "A5"), (3.0, 1.0, "B5")],
        [(0.0, 0.75, "D6"), (0.75, 0.25, "C6"), (1.0, 1.0, "B5"), (2.0, 1.0, "A5"), (3.0, 1.0, "G5")],
        [(0.0, 0.75, "E5"), (0.75, 0.25, "G5"), (1.0, 1.0, "A5"), (2.0, 0.75, "B5"), (2.75, 0.25, "A5"), (3.0, 1.0, "G5")],
        [(0.0, 1.0, "E5"), (1.0, 1.0, "F#5"), (2.0, 2.0, "G5")],
    ]
    mod_brass = [
        [(0.0, 0.45, "G3"), (0.5, 0.45, "G3"), (1.0, 0.85, "D4"), (2.0, 0.85, "B3"), (3.0, 0.85, "G4")],
        [(0.0, 0.85, "C4"), (1.0, 0.85, "A3"), (2.0, 0.85, "D4"), (3.0, 0.85, "G3")],
    ]
    mod_bass = [
        [(0.0, 0.45, "G2"), (0.5, 0.45, "G2"), (1.0, 0.45, "D3"), (1.5, 0.45, "G2"), (2.0, 0.45, "G2"), (2.5, 0.45, "B2"), (3.0, 0.45, "D3"), (3.5, 0.45, "G2")],
        [(0.0, 0.45, "C3"), (0.5, 0.45, "C3"), (1.0, 0.45, "A2"), (1.5, 0.45, "D3"), (2.0, 0.45, "G2"), (2.5, 0.45, "D3"), (3.0, 0.45, "G2"), (3.5, 0.45, "D2")],
    ]
    mod_drums = [[
        (0.0, "kick", 1.0), (0.5, "hat", 0.55), (1.0, "snare", 0.9), (1.5, "snare", 0.45),
        (2.0, "kick", 1.0), (2.5, "kick", 0.65), (3.0, "snare", 0.92), (3.5, "hat", 0.6),
    ]]
    out["battle_modern"] = render_arranged_track(
        126.0, 19,
        [("brass", 0.24, mod_brass), ("sq25", 0.22, mod_lead), ("bass", 0.26, mod_bass)],
        mod_drums, 202607, 0.26,
    )

    # 8. battle_sprint.wav (~33.75s, 128 BPM, 18 bars) - Thần Tốc Xung Phong (bright rapid A minor / C major rush)
    spr_lead = [
        [(0.0, 0.5, "A5"), (0.5, 0.5, "C6"), (1.0, 0.5, "D6"), (1.5, 0.5, "E6"), (2.0, 0.75, "C6"), (2.75, 0.25, "D6"), (3.0, 1.0, "E6")],
        [(0.0, 0.5, "G5"), (0.5, 0.5, "A5"), (1.0, 0.5, "C6"), (1.5, 0.5, "A5"), (2.0, 1.0, "G5"), (3.0, 1.0, "E5")],
        [(0.0, 0.5, "F5"), (0.5, 0.5, "G5"), (1.0, 0.5, "A5"), (1.5, 0.5, "C6"), (2.0, 0.75, "B5"), (2.75, 0.25, "A5"), (3.0, 1.0, "G5")],
        [(0.0, 0.5, "E5"), (0.5, 0.5, "G5"), (1.0, 0.5, "A5"), (1.5, 0.5, "C6"), (2.0, 2.0, "A5")],
    ]
    spr_dan = [
        [(0.0, 0.35, "A4"), (0.5, 0.35, "E5"), (1.0, 0.35, "A5"), (1.5, 0.35, "E5"), (2.0, 0.35, "C5"), (2.5, 0.35, "G5"), (3.0, 0.35, "C6"), (3.5, 0.35, "G5")],
        [(0.0, 0.35, "F4"), (0.5, 0.35, "C5"), (1.0, 0.35, "F5"), (1.5, 0.35, "C5"), (2.0, 0.35, "G4"), (2.5, 0.35, "D5"), (3.0, 0.35, "E5"), (3.5, 0.35, "B4")],
    ]
    spr_bass = [
        [(0.0, 0.4, "A2"), (0.5, 0.4, "A3"), (1.0, 0.4, "A2"), (1.5, 0.4, "A3"), (2.0, 0.4, "C3"), (2.5, 0.4, "C4"), (3.0, 0.4, "G2"), (3.5, 0.4, "G3")],
        [(0.0, 0.4, "F2"), (0.5, 0.4, "F3"), (1.0, 0.4, "F2"), (1.5, 0.4, "F3"), (2.0, 0.4, "G2"), (2.5, 0.4, "G3"), (3.0, 0.4, "E2"), (3.5, 0.4, "E3")],
    ]
    spr_drums = [[
        (0.0, "kick", 1.0), (0.5, "hat", 0.65), (1.0, "snare", 0.85), (1.5, "hat", 0.65),
        (2.0, "kick", 1.0), (2.5, "kick", 0.72), (3.0, "snare", 0.9), (3.5, "wood", 0.7),
    ]]
    out["battle_sprint"] = render_arranged_track(
        128.0, 18,
        [("sq25", 0.22, spr_lead), ("dan_tranh", 0.19, spr_dan), ("bass", 0.25, spr_bass)],
        spr_drums, 202608, 0.26,
    )

    # 9. battle_mythic.wav (~38.64s, 118 BPM, 19 bars) - Lĩnh Nam Huyền Ảo (E Phrygian dominant / mystical pentatonic)
    myt_flute = [
        [(0.0, 1.0, "E5"), (1.0, 0.5, "F5"), (1.5, 0.5, "G#5"), (2.0, 1.0, "A5"), (3.0, 1.0, "B5")],
        [(0.0, 0.75, "C6"), (0.75, 0.75, "B5"), (1.5, 0.5, "A5"), (2.0, 1.5, "G#5"), (3.5, 0.5, "F5")],
        [(0.0, 1.0, "E5"), (1.0, 0.5, "G#5"), (1.5, 0.5, "B5"), (2.0, 1.0, "E6"), (3.0, 1.0, "D6")],
        [(0.0, 1.0, "C6"), (1.0, 0.5, "B5"), (1.5, 0.5, "A5"), (2.0, 2.0, "E5")],
    ]
    myt_dan = [
        [(0.0, 0.55, "E4"), (0.5, 0.55, "B4"), (1.0, 0.55, "G#5"), (1.5, 0.55, "B4"), (2.0, 0.55, "E4"), (2.5, 0.55, "C5"), (3.0, 0.55, "A5"), (3.5, 0.55, "C5")],
        [(0.0, 0.55, "F4"), (0.5, 0.55, "C5"), (1.0, 0.55, "A5"), (1.5, 0.55, "C5"), (2.0, 0.55, "D4"), (2.5, 0.55, "A4"), (3.0, 0.55, "F5"), (3.5, 0.55, "A4")],
    ]
    myt_pad = [[(0.0, 3.8, "E2"), (0.0, 3.8, "B2")], [(0.0, 3.8, "F2"), (0.0, 3.8, "C3")]]
    myt_bass = [
        [(0.0, 0.85, "E2"), (1.0, 0.85, "B2"), (2.0, 0.85, "E2"), (3.0, 0.85, "F2")],
        [(0.0, 0.85, "F2"), (1.0, 0.85, "C3"), (2.0, 0.85, "D2"), (3.0, 0.85, "E2")],
    ]
    myt_drums = [
        [(0.0, "gong", 0.65), (0.0, "kick", 0.95), (1.0, "wood", 0.75), (1.5, "hat", 0.5), (2.0, "kick", 0.9), (2.5, "wood", 0.6), (3.0, "snare", 0.78), (3.5, "hat", 0.55)],
        [(0.0, "kick", 0.95), (1.0, "wood", 0.75), (1.5, "kick", 0.6), (2.0, "kick", 0.9), (2.5, "hat", 0.55), (3.0, "snare", 0.8), (3.5, "wood", 0.65)],
    ]
    out["battle_mythic"] = render_arranged_track(
        118.0, 19,
        [("flute", 0.28, myt_flute), ("dan_tranh", 0.21, myt_dan), ("pad", 0.14, myt_pad), ("bass", 0.24, myt_bass)],
        myt_drums, 202609, 0.24,
    )

    # 10. boss.wav (~41.74s, 138 BPM, 24 bars) - Quyết Chiến Đại Tướng
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
    boss_brass = [
        [(0.0, 0.65, "A3"), (2.0, 0.65, "E4")],
        [(0.0, 0.65, "F3"), (2.0, 0.65, "G3")],
        [(0.0, 0.65, "D3"), (2.0, 0.65, "E4")],
        [(0.0, 0.65, "E3"), (2.0, 0.65, "A3")],
    ]
    boss_bass = [
        [(0.0, 0.42, "A2"), (0.5, 0.42, "A2"), (1.0, 0.42, "E3"), (1.5, 0.42, "A2"),
         (2.0, 0.42, "A2"), (2.5, 0.42, "G2"), (3.0, 0.42, "E2"), (3.5, 0.42, "G2")],
        [(0.0, 0.42, "D3"), (0.5, 0.42, "D3"), (1.0, 0.42, "A2"), (1.5, 0.42, "D3"),
         (2.0, 0.42, "E3"), (2.5, 0.42, "G2"), (3.0, 0.42, "A2"), (3.5, 0.42, "E2")],
    ]
    boss_drums = [
        [(0.0, "gong", 0.65), (0.0, "kick", 1.0), (0.5, "kick", 0.68), (1.0, "snare", 0.9), (1.5, "kick", 0.72),
         (2.0, "kick", 1.0), (2.5, "wood", 0.65), (3.0, "snare", 0.95), (3.5, "kick", 0.78)],
        [(0.0, "kick", 1.0), (0.5, "hat", 0.6), (1.0, "snare", 0.9), (1.5, "kick", 0.72),
         (2.0, "kick", 1.0), (2.5, "hat", 0.6), (3.0, "snare", 0.95), (3.5, "wood", 0.7)],
    ]
    out["boss"] = render_arranged_track(
        138.0, 24,
        [("sq25", 0.22, boss_mel), ("flute", 0.22, boss_mel), ("brass", 0.20, boss_brass), ("bass", 0.27, boss_bass)],
        boss_drums, 202610, 0.27,
    )

    # 11. boss_frenzy.wav (~37.89s, 152 BPM, 24 bars) - Bạo Nộ Huyết Chiến (chromatic/Phrygian shred 152 BPM)
    fr_lead = [
        [(0.0, 0.25, "E5"), (0.25, 0.25, "F5"), (0.5, 0.25, "G#5"), (0.75, 0.25, "A5"), (1.0, 0.5, "B5"), (1.5, 0.5, "C6"), (2.0, 0.5, "B5"), (2.5, 0.5, "A5"), (3.0, 0.5, "G#5"), (3.5, 0.5, "F5")],
        [(0.0, 0.5, "E5"), (0.5, 0.5, "B5"), (1.0, 0.5, "D6"), (1.5, 0.5, "C6"), (2.0, 0.5, "B5"), (2.5, 0.5, "A5"), (3.0, 1.0, "G#5")],
        [(0.0, 0.25, "A5"), (0.25, 0.25, "B5"), (0.5, 0.25, "C6"), (0.75, 0.25, "D6"), (1.0, 0.5, "E6"), (1.5, 0.5, "D6"), (2.0, 0.5, "C6"), (2.5, 0.5, "B5"), (3.0, 0.5, "A5"), (3.5, 0.5, "F5")],
        [(0.0, 0.75, "E5"), (0.75, 0.75, "F5"), (1.5, 0.5, "G#5"), (2.0, 1.0, "B5"), (3.0, 1.0, "E5")],
    ]
    fr_brass = [
        [(0.0, 0.45, "E3"), (1.0, 0.45, "F3"), (2.0, 0.45, "E3"), (3.0, 0.45, "G#3")],
        [(0.0, 0.45, "A3"), (1.0, 0.45, "D3"), (2.0, 0.45, "E3"), (3.0, 0.45, "B2")],
    ]
    fr_bass = [
        [(0.0, 0.4, "E2"), (0.5, 0.4, "E2"), (1.0, 0.4, "F2"), (1.5, 0.4, "E2"), (2.0, 0.4, "E2"), (2.5, 0.4, "B2"), (3.0, 0.4, "G#2"), (3.5, 0.4, "F2")],
        [(0.0, 0.4, "A2"), (0.5, 0.4, "A2"), (1.0, 0.4, "G2"), (1.5, 0.4, "F2"), (2.0, 0.4, "E2"), (2.5, 0.4, "E2"), (3.0, 0.4, "B2"), (3.5, 0.4, "E2")],
    ]
    fr_drums = [[
        (0.0, "kick", 1.0), (0.5, "kick", 0.82), (1.0, "snare", 0.95), (1.5, "kick", 0.8),
        (2.0, "kick", 1.0), (2.5, "kick", 0.82), (3.0, "snare", 1.0), (3.5, "snare", 0.65),
    ]]
    out["boss_frenzy"] = render_arranged_track(
        152.0, 24,
        [("sq25", 0.24, fr_lead), ("brass", 0.22, fr_brass), ("bass", 0.28, fr_bass)],
        fr_drums, 202611, 0.28,
    )

    # 12. boss_legend.wav (~38.87s, 142 BPM, 23 bars) - Tam Yêu Hiện Hình (C# minor / eerie folk beast)
    leg_mel = [
        [(0.0, 0.5, "C#5"), (0.5, 0.5, "E5"), (1.0, 0.5, "G#5"), (1.5, 0.5, "A5"), (2.0, 1.0, "G#5"), (3.0, 1.0, "F#5")],
        [(0.0, 0.75, "E5"), (0.75, 0.75, "D#5"), (1.5, 0.5, "C#5"), (2.0, 1.5, "G#4"), (3.5, 0.5, "B4")],
        [(0.0, 0.5, "C#5"), (0.5, 0.5, "G#5"), (1.0, 0.5, "A5"), (1.5, 0.5, "B5"), (2.0, 1.0, "C#6"), (3.0, 1.0, "B5")],
        [(0.0, 1.0, "A5"), (1.0, 0.5, "G#5"), (1.5, 0.5, "F#5"), (2.0, 2.0, "G#5")],
    ]
    leg_dan = [
        [(0.0, 0.45, "C#5"), (0.5, 0.45, "G#5"), (1.0, 0.45, "E5"), (1.5, 0.45, "G#5"), (2.0, 0.45, "A4"), (2.5, 0.45, "E5"), (3.0, 0.45, "B4"), (3.5, 0.45, "F#5")],
    ]
    leg_bass = [
        [(0.0, 0.45, "C#3"), (0.5, 0.45, "C#3"), (1.0, 0.45, "G#2"), (1.5, 0.45, "C#3"), (2.0, 0.45, "A2"), (2.5, 0.45, "A2"), (3.0, 0.45, "B2"), (3.5, 0.45, "G#2")],
    ]
    leg_drums = [
        [(0.0, "gong", 0.72), (0.0, "kick", 0.95), (1.0, "wood", 0.8), (1.5, "kick", 0.7), (2.0, "kick", 0.95), (2.5, "hat", 0.6), (3.0, "snare", 0.85), (3.5, "wood", 0.75)],
        [(0.0, "kick", 0.95), (0.5, "hat", 0.55), (1.0, "snare", 0.85), (1.5, "kick", 0.72), (2.0, "kick", 0.95), (2.5, "wood", 0.65), (3.0, "snare", 0.88), (3.5, "hat", 0.6)],
    ]
    out["boss_legend"] = render_arranged_track(
        142.0, 23,
        [("flute", 0.25, leg_mel), ("sq25", 0.19, leg_mel), ("dan_tranh", 0.18, leg_dan), ("bass", 0.27, leg_bass)],
        leg_drums, 202612, 0.26,
    )

    # 13. boss_mythic.wav (~37.30s, 148 BPM, 23 bars) - Thần Thoại Đại Chiến (grand apocalyptic D minor / harmonic)
    mytb_lead = [
        [(0.0, 0.5, "D5"), (0.5, 0.5, "A5"), (1.0, 0.5, "Bb5"), (1.5, 0.5, "C#6"), (2.0, 1.0, "D6"), (3.0, 1.0, "A5")],
        [(0.0, 0.75, "Bb5"), (0.75, 0.75, "A5"), (1.5, 0.5, "G5"), (2.0, 1.0, "F5"), (3.0, 1.0, "E5")],
        [(0.0, 0.5, "D5"), (0.5, 0.5, "F5"), (1.0, 0.5, "A5"), (1.5, 0.5, "D6"), (2.0, 1.0, "C6"), (3.0, 1.0, "Bb5")],
        [(0.0, 1.0, "A5"), (1.0, 0.5, "G5"), (1.5, 0.5, "E5"), (2.0, 2.0, "A4")],
    ]
    mytb_brass = [
        [(0.0, 0.85, "D3"), (0.0, 0.85, "A3"), (2.0, 0.85, "Bb3")],
        [(0.0, 0.85, "G3"), (0.0, 0.85, "D4"), (2.0, 0.85, "A3")],
    ]
    mytb_pad = [[(0.0, 3.8, "D2"), (0.0, 3.8, "A2")], [(0.0, 3.8, "Bb2"), (0.0, 3.8, "A2")]]
    mytb_bass = [
        [(0.0, 0.42, "D2"), (0.5, 0.42, "D3"), (1.0, 0.42, "D2"), (1.5, 0.42, "A2"), (2.0, 0.42, "Bb2"), (2.5, 0.42, "Bb2"), (3.0, 0.42, "A2"), (3.5, 0.42, "A2")],
        [(0.0, 0.42, "G2"), (0.5, 0.42, "G2"), (1.0, 0.42, "F2"), (1.5, 0.42, "E2"), (2.0, 0.42, "A2"), (2.5, 0.42, "A2"), (3.0, 0.42, "C#3"), (3.5, 0.42, "A2")],
    ]
    mytb_drums = [
        [(0.0, "gong", 0.8), (0.0, "kick", 1.0), (0.5, "kick", 0.72), (1.0, "snare", 0.92), (1.5, "kick", 0.75),
         (2.0, "kick", 1.0), (2.5, "hat", 0.65), (3.0, "snare", 0.95), (3.5, "wood", 0.7)],
        [(0.0, "kick", 1.0), (0.5, "kick", 0.72), (1.0, "snare", 0.92), (1.5, "hat", 0.65),
         (2.0, "kick", 1.0), (2.5, "kick", 0.75), (3.0, "snare", 0.98), (3.5, "snare", 0.6)],
    ]
    out["boss_mythic"] = render_arranged_track(
        148.0, 23,
        [("sq25", 0.22, mytb_lead), ("brass", 0.22, mytb_brass), ("pad", 0.14, mytb_pad), ("bass", 0.27, mytb_bass)],
        mytb_drums, 202613, 0.28,
    )

    # 14. victory.wav (~35.56s, 108 BPM, 16 bars) - Khải Hoàn Ca (triumphant radiant C major pentatonic)
    vic_mel = [
        [(0.0, 1.0, "C5"), (1.0, 0.5, "D5"), (1.5, 0.5, "E5"), (2.0, 1.0, "G5"), (3.0, 1.0, "C6")],
        [(0.0, 1.5, "A5"), (1.5, 0.5, "G5"), (2.0, 2.0, "E5")],
        [(0.0, 1.0, "G5"), (1.0, 0.5, "A5"), (1.5, 0.5, "C6"), (2.0, 1.0, "D6"), (3.0, 1.0, "C6")],
        [(0.0, 1.5, "A5"), (1.5, 0.5, "G5"), (2.0, 2.0, "G5")],
        [(0.0, 1.0, "E5"), (1.0, 0.5, "G5"), (1.5, 0.5, "A5"), (2.0, 1.0, "C6"), (3.0, 1.0, "E6")],
        [(0.0, 1.0, "D6"), (1.0, 1.0, "C6"), (2.0, 2.0, "A5")],
        [(0.0, 1.0, "G5"), (1.0, 1.0, "E5"), (2.0, 1.0, "D5"), (3.0, 1.0, "E5")],
        [(0.0, 3.0, "C5"), (3.0, 1.0, "G5")],
    ]
    vic_brass = [
        [(0.0, 1.2, "C4"), (2.0, 1.2, "G4")],
        [(0.0, 1.2, "F4"), (2.0, 1.2, "E4")],
        [(0.0, 1.2, "A3"), (2.0, 1.2, "D4")],
        [(0.0, 1.2, "G3"), (2.0, 1.2, "C4")],
    ]
    vic_dan = [
        [(0.0, 0.65, "C5"), (0.5, 0.65, "E5"), (1.0, 0.65, "G5"), (1.5, 0.65, "C6"), (2.0, 0.65, "G5"), (2.5, 0.65, "E5"), (3.0, 0.65, "C5"), (3.5, 0.65, "G4")],
        [(0.0, 0.65, "F4"), (0.5, 0.65, "A4"), (1.0, 0.65, "C5"), (1.5, 0.65, "F5"), (2.0, 0.65, "G4"), (2.5, 0.65, "B4"), (3.0, 0.65, "D5"), (3.5, 0.65, "G5")],
    ]
    vic_bass = [
        [(0.0, 0.9, "C3"), (1.0, 0.9, "G3"), (2.0, 0.9, "C3"), (3.0, 0.9, "E3")],
        [(0.0, 0.9, "F2"), (1.0, 0.9, "C3"), (2.0, 0.9, "G2"), (3.0, 0.9, "D3")],
    ]
    vic_drums = [
        [(0.0, "gong", 0.75), (0.0, "kick", 0.9), (1.0, "snare", 0.65), (2.0, "kick", 0.85), (3.0, "snare", 0.7), (3.5, "wood", 0.55)],
        [(0.0, "kick", 0.9), (1.0, "snare", 0.65), (2.0, "kick", 0.85), (2.5, "hat", 0.5), (3.0, "snare", 0.72), (3.5, "wood", 0.55)],
    ]
    out["victory"] = render_arranged_track(
        108.0, 16,
        [("flute", 0.26, vic_mel), ("brass", 0.22, vic_brass), ("dan_tranh", 0.18, vic_dan), ("bass", 0.24, vic_bass)],
        vic_drums, 202614, 0.22,
    )

    # 15. coloa_defense.wav (~36.61s, 118 BPM, 18 bars) - Hào Khí Thành Cổ Loa (D pentatonic heroic fortress march)
    cl_mel = [
        [(0.0, 1.0, "D5"), (1.0, 0.5, "E5"), (1.5, 0.5, "G5"), (2.0, 1.5, "A5"), (3.5, 0.5, "G5")],
        [(0.0, 1.0, "A5"), (1.0, 0.5, "C6"), (1.5, 0.5, "D6"), (2.0, 2.0, "A5")],
        [(0.0, 0.75, "G5"), (0.75, 0.75, "E5"), (1.5, 0.5, "D5"), (2.0, 1.5, "E5"), (3.5, 0.5, "D5")],
        [(0.0, 1.5, "C5"), (1.5, 0.5, "D5"), (2.0, 2.0, "A4")],
        [(0.0, 1.0, "D5"), (1.0, 0.5, "G5"), (1.5, 0.5, "A5"), (2.0, 1.5, "D6"), (3.5, 0.5, "C6")],
        [(0.0, 2.0, "D5"), (2.0, 1.0, "E5"), (3.0, 1.0, "A4")],
    ]
    cl_dan = [
        [(0.0, 0.45, "D5"), (0.5, 0.45, "A5"), (1.0, 0.45, "G5"), (1.5, 0.45, "E5"), (2.0, 0.45, "D5"), (2.5, 0.45, "A4"), (3.0, 0.45, "C5"), (3.5, 0.45, "E5")],
        [(0.0, 0.45, "G4"), (0.5, 0.45, "D5"), (1.0, 0.45, "A5"), (1.5, 0.45, "G5"), (2.0, 0.45, "A4"), (2.5, 0.45, "E5"), (3.0, 0.45, "D5"), (3.5, 0.45, "A4")],
    ]
    cl_brass = [
        [(0.0, 1.5, "D3"), (2.0, 1.5, "A3")],
        [(0.0, 1.5, "G3"), (2.0, 1.5, "C4")],
    ]
    cl_bass = [
        [(0.0, 0.9, "D3"), (1.0, 0.9, "A2"), (2.0, 0.9, "D3"), (3.0, 0.9, "C3")],
        [(0.0, 0.9, "G2"), (1.0, 0.9, "D3"), (2.0, 0.9, "A2"), (3.0, 0.9, "A2")],
    ]
    cl_drums = [
        [(0.0, "gong", 0.65), (0.0, "kick", 0.9), (1.0, "wood", 0.72), (2.0, "kick", 0.85), (2.5, "hat", 0.48), (3.0, "snare", 0.78), (3.5, "wood", 0.65)],
        [(0.0, "kick", 0.9), (1.0, "snare", 0.75), (1.5, "kick", 0.65), (2.0, "kick", 0.88), (2.5, "hat", 0.5), (3.0, "snare", 0.8), (3.5, "wood", 0.65)],
    ]
    out["coloa_defense"] = render_arranged_track(
        118.0, 18,
        [("flute", 0.25, cl_mel), ("dan_tranh", 0.20, cl_dan), ("brass", 0.20, cl_brass), ("bass", 0.25, cl_bass)],
        cl_drums, 202615, 0.25,
    )

    # 16. coloa_siege.wav (~34.74s, 152 BPM, 22 bars) - Cổ Loa Công Thành (D minor furious siege)
    cs_lead = [
        [(0.0, 0.5, "D5"), (0.5, 0.5, "F5"), (1.0, 0.5, "A5"), (1.5, 0.5, "Bb5"), (2.0, 1.0, "A5"), (3.0, 1.0, "G5")],
        [(0.0, 0.75, "F5"), (0.75, 0.75, "E5"), (1.5, 0.5, "D5"), (2.0, 1.5, "A4"), (3.5, 0.5, "C#5")],
        [(0.0, 0.5, "D5"), (0.5, 0.5, "A5"), (1.0, 0.5, "D6"), (1.5, 0.5, "C6"), (2.0, 1.0, "Bb5"), (3.0, 1.0, "A5")],
        [(0.0, 1.0, "G5"), (1.0, 0.5, "F5"), (1.5, 0.5, "E5"), (2.0, 2.0, "A4")],
    ]
    cs_brass = [
        [(0.0, 0.8, "D3"), (0.0, 0.8, "A3"), (2.0, 0.8, "Bb3")],
        [(0.0, 0.8, "G3"), (2.0, 0.8, "A3")],
    ]
    cs_bass = [
        [(0.0, 0.45, "D2"), (0.5, 0.45, "D3"), (1.0, 0.45, "D2"), (1.5, 0.45, "A2"), (2.0, 0.45, "Bb2"), (2.5, 0.45, "Bb2"), (3.0, 0.45, "A2"), (3.5, 0.45, "C#3")],
    ]
    cs_drums = [
        [(0.0, "gong", 0.76), (0.0, "kick", 0.98), (0.5, "kick", 0.72), (1.0, "snare", 0.90), (1.5, "kick", 0.75),
         (2.0, "kick", 0.98), (2.5, "hat", 0.62), (3.0, "snare", 0.94), (3.5, "wood", 0.74)],
        [(0.0, "kick", 0.98), (0.5, "hat", 0.58), (1.0, "snare", 0.90), (1.5, "kick", 0.72),
         (2.0, "kick", 0.98), (2.5, "kick", 0.75), (3.0, "snare", 0.95), (3.5, "snare", 0.60)],
    ]
    out["coloa_siege"] = render_arranged_track(
        152.0, 22,
        [("sq25", 0.21, cs_lead), ("brass", 0.24, cs_brass), ("bass", 0.27, cs_bass)],
        cs_drums, 202616, 0.28,
    )

    # 17. secret_thuy_cung.wav (~40.00s, 96 BPM, 16 bars) - Thủy Cung Long Vương (E minor mystic underwater)
    tc_mel = [
        [(0.0, 1.5, "E5"), (1.5, 0.5, "G5"), (2.0, 1.5, "B5"), (3.5, 0.5, "A5")],
        [(0.0, 1.5, "G5"), (1.5, 0.5, "E5"), (2.0, 2.0, "D5")],
        [(0.0, 1.0, "E5"), (1.0, 1.0, "A5"), (2.0, 1.5, "B5"), (3.5, 0.5, "D6")],
        [(0.0, 1.5, "B5"), (1.5, 0.5, "A5"), (2.0, 2.0, "E5")],
    ]
    tc_dan = [
        [(0.0, 0.7, "E5"), (0.5, 0.7, "B5"), (1.0, 0.7, "E6"), (1.5, 0.7, "B5"), (2.0, 0.7, "G5"), (2.5, 0.7, "D5"), (3.0, 0.7, "A4"), (3.5, 0.7, "B4")],
        [(0.0, 0.7, "C5"), (0.5, 0.7, "G5"), (1.0, 0.7, "B5"), (1.5, 0.7, "G5"), (2.0, 0.7, "D5"), (2.5, 0.7, "A5"), (3.0, 0.7, "B5"), (3.5, 0.7, "E5")],
    ]
    tc_pad = [[(0.0, 3.9, "E3")], [(0.0, 3.9, "C3")], [(0.0, 3.9, "D3")], [(0.0, 3.9, "B2")]]
    tc_bass = [[(0.0, 1.8, "E2"), (2.0, 1.8, "B2")], [(0.0, 1.8, "C3"), (2.0, 1.8, "D3")]]
    tc_drums = [[(0.0, "gong", 0.65), (0.0, "kick", 0.72), (2.0, "wood", 0.55), (3.0, "hat", 0.42)]]
    out["secret_thuy_cung"] = render_arranged_track(
        96.0, 16,
        [("flute", 0.28, tc_mel), ("dan_tranh", 0.22, tc_dan), ("pad", 0.16, tc_pad), ("bass", 0.22, tc_bass)],
        tc_drums, 202617, 0.21,
    )

    # 18. secret_tan_vien.wav (~38.57s, 112 BPM, 18 bars) - Đỉnh Tản Viên Linh Thiêng (G major sacred peak)
    tv_mel = [
        [(0.0, 1.0, "G5"), (1.0, 0.5, "A5"), (1.5, 0.5, "B5"), (2.0, 1.5, "D6"), (3.5, 0.5, "B5")],
        [(0.0, 1.5, "A5"), (1.5, 0.5, "G5"), (2.0, 2.0, "E5")],
        [(0.0, 1.0, "D5"), (1.0, 1.0, "G5"), (2.0, 1.0, "B5"), (3.0, 1.0, "A5")],
        [(0.0, 2.0, "G5"), (2.0, 2.0, "D5")],
    ]
    tv_dan = [
        [(0.0, 0.5, "G5"), (0.5, 0.5, "D5"), (1.0, 0.5, "B4"), (1.5, 0.5, "D5"), (2.0, 0.5, "E5"), (2.5, 0.5, "G5"), (3.0, 0.5, "A5"), (3.5, 0.5, "D5")],
    ]
    tv_brass = [[(0.0, 1.6, "G3"), (2.0, 1.6, "D4")], [(0.0, 1.6, "E3"), (2.0, 1.6, "B3")]]
    tv_bass = [[(0.0, 0.9, "G2"), (1.0, 0.9, "D3"), (2.0, 0.9, "E3"), (3.0, 0.9, "D3")]]
    tv_drums = [[(0.0, "gong", 0.68), (0.0, "kick", 0.84), (1.0, "wood", 0.65), (2.0, "kick", 0.8), (3.0, "snare", 0.68), (3.5, "hat", 0.48)]]
    out["secret_tan_vien"] = render_arranged_track(
        112.0, 18,
        [("flute", 0.27, tv_mel), ("dan_tranh", 0.19, tv_dan), ("brass", 0.21, tv_brass), ("bass", 0.24, tv_bass)],
        tv_drums, 202618, 0.23,
    )

    # 19. boss_hon_mang.wav (~36.92s, 156 BPM, 24 bars) - Hỗn Mang Diệt Thế (C minor apocalyptic true ending)
    hm_lead = [
        [(0.0, 0.5, "C5"), (0.5, 0.5, "Eb5"), (1.0, 0.5, "G5"), (1.5, 0.5, "B5"), (2.0, 1.0, "C6"), (3.0, 1.0, "Ab5")],
        [(0.0, 0.75, "G5"), (0.75, 0.75, "F5"), (1.5, 0.5, "Eb5"), (2.0, 1.5, "D5"), (3.5, 0.5, "B4")],
        [(0.0, 0.5, "C5"), (0.5, 0.5, "G5"), (1.0, 0.5, "C6"), (1.5, 0.5, "Eb6"), (2.0, 1.0, "D6"), (3.0, 1.0, "B5")],
        [(0.0, 1.0, "C6"), (1.0, 0.5, "G5"), (1.5, 0.5, "Eb5"), (2.0, 2.0, "G4")],
    ]
    hm_brass = [
        [(0.0, 0.9, "C3"), (0.0, 0.9, "G3"), (2.0, 0.9, "Ab3")],
        [(0.0, 0.9, "F3"), (0.0, 0.9, "C4"), (2.0, 0.9, "G3")],
    ]
    hm_pad = [[(0.0, 3.8, "C3"), (0.0, 3.8, "G3")], [(0.0, 3.8, "Ab2"), (0.0, 3.8, "G2")]]
    hm_bass = [
        [(0.0, 0.42, "C2"), (0.5, 0.42, "C3"), (1.0, 0.42, "C2"), (1.5, 0.42, "G2"), (2.0, 0.42, "Ab2"), (2.5, 0.42, "Ab2"), (3.0, 0.42, "G2"), (3.5, 0.42, "B2")],
    ]
    hm_drums = [
        [(0.0, "gong", 0.85), (0.0, "kick", 1.0), (0.5, "kick", 0.76), (1.0, "snare", 0.95), (1.5, "kick", 0.78),
         (2.0, "kick", 1.0), (2.5, "hat", 0.65), (3.0, "snare", 0.98), (3.5, "wood", 0.75)],
        [(0.0, "kick", 1.0), (0.5, "kick", 0.76), (1.0, "snare", 0.95), (1.5, "hat", 0.65),
         (2.0, "kick", 1.0), (2.5, "kick", 0.78), (3.0, "snare", 1.0), (3.5, "snare", 0.66)],
    ]
    out["boss_hon_mang"] = render_arranged_track(
        156.0, 24,
        [("sq25", 0.22, hm_lead), ("brass", 0.23, hm_brass), ("pad", 0.14, hm_pad), ("bass", 0.28, hm_bass)],
        hm_drums, 202619, 0.29,
    )

    return out


def main() -> None:
    sfx = gen_sfx()
    for name, samples in sfx.items():
        save_wav(os.path.join(SFX_DIR, f"{name}.wav"), samples)
    music = gen_music()
    for name, stereo_samples in music.items():
        save_wav(os.path.join(MUSIC_DIR, f"{name}.wav"), stereo_samples)
    print(f"Generated {len(sfx)} SFX and {len(music)} music tracks.")


if __name__ == "__main__":
    main()
