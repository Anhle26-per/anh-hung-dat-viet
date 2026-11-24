"""Biểu tượng phúc lành 16x16 (vẽ tay bằng lưới ký tự)."""
from px import hexc, grid, outline, save, Image

PAL = {k: hexc(v) for k, v in {
    "g": "5a9a3a", "G": "3a6a24", "l": "8ad05a", "y": "fff0a0", "Y": "e8b04a", "o": "a86a2a",
    "r": "e04848", "R": "8e2632", "w": "ffffff", "k": "2a1d2e", "m": "c8cede", "M": "868ea8",
    "b": "4aa8ff", "B": "1a5ab0", "c": "62e0ff", "p": "f0a0c0", "P": "b05a7a", "n": "9a6234", "N": "5e3a20",
    "s": "f0c4a0", "j": "4ad6a0", "J": "1f8a6a", "z": "c4803e", "Z": "7a4622", "v": "b06aff",
}.items()}

ICONS = {
    "banh_chung": ["..GGGGGGGGGG..", ".GgggggggggggG", ".GglllllllllgG", ".GglyyyyyyylgG", ".GglyYYYYYylgG",
                   ".GgrrrrrrrrrgG", ".GglyYYYYYylgG", ".GglyyyyyyylgG", ".GglllllllllgG", ".GggggggggggG.", "..GGGGGGGGGG.."],
    "giap_dong": ["...zzzzzzzz...", "..zZzyyyyzZz..", ".zZzzyzzyzzZz.", ".zzzzzzzzzzzz.", ".zZzZzZzZzZzz.",
                  ".zzzzzzzzzzzz.", ".zZzZzZzZzZzz.", "..zzzzzzzzzz..", "..ZZZZZZZZZZ..", "...Z......Z..."],
    "ruou_thuoc": [".....nn.....", ".....NN.....", "....rrrr....", "...rwrrrR...", "..rwrrrrrR..", ".rrrrrrrrrR.",
                   ".rrrYYYYrrR.", ".rrrYrrYrrR.", ".rrrYYYYrrR.", "..rrrrrrRR..", "...RRRRRR..."],
    "ngua_o": ["........kk..", ".......kkkk.", "......kkkwk.", "..kkkkkkkk..", ".kkkkkkkkk..", "kkkkkkkkk...",
               "k.kkkkkkk...", "..k.k..k.k..", "..k.k..k.k..", "..n.n..n.n.."],
    "bua_ho_menh": ["....YYYY....", "...Y....Y...", "..rrrrrrrr..", "..ryyyyyyr..", "..ryrrrryr..", "..ryrYYryr..",
                    "..ryrrrryr..", "..ryyyyyyr..", "..rrrrrrrr..", "....r..r....", "....r..r...."],
    "da_mai": ["..........m", ".........mM", "........mM.", ".......mM..", "......mM...", ".....mM....",
               "...YmM.....", "..NNY......", "nnnnnnnnnn.", "NNNNNNNNNN."],
    "hoa_duoc": ["......y.....", ".....yr.....", "......k.....", "....kkkk....", "...kkkkkk...", "..kkwkkkkk..",
                 "..kkkkkkkk..", "..kkkkkkkk..", "...kkkkkk...", "....kkkk...."],
    "tra_tim_sen": ["...g..g.g...", "....g.gg....", ".....gg.....", "..wwwwwwww..", ".wjjjjjjjjw.", ".wjJJJJJJjww",
                    ".wjjjjjjjjw.", "..wwwwwwww..", "...wwwwww..."],
    "mat_than": ["...YYYYYY...", "..Y......Y..", ".Y.wwwwww.Y.", "Y.wwbbbbww.Y", "Y.wbBkkBbw.Y", "Y.wbBkkBbw.Y",
                 "Y.wwbbbbww.Y", ".Y.wwwwww.Y.", "..Y......Y..", "...YYYYYY..."],
    "linh_khi": ["....c.......", "...cbc......", "..cbBbc.....", ".cbBBBbc....", "..cbBbc..c..", "...cbc..cbc.",
                 "....c..cbBbc", ".......cbBbc", "........cbc.", ".........c.."],
    "huyet_sam": ["....r.r.....", ".....r......", "....ggg.....", "...gnnng....", "...nnnnn....", "..nnNnnnn...",
                  "..nnnnNnn...", "...nnnnn....", "...n.n.n....", "..n..n..n..."],
    "boi_thu": ["....YYYY....", "...YyyyyY...", "..YyYooYyY..", "..YyoYYoyY..", "..YyYooYyY..", "...YyyyyY...",
                "..YYYY.YYYY.", ".YyyyyYyyyyY", ".YyooyYyooyY", ".YyyyyYyyyyY", "..YYYY.YYYY."],
    "giay_co": [".......yy...", "......yy....", ".....yyyyy..", "........y...", ".......y....", "..nnnn......",
                ".nNnnnn.....", ".nnnnnnnn...", ".NNNNNNNNN.."],
    "ten_doi": ["mM.......mM.", ".mM.......mM", "..n.......n.", "...n.......n", "....n.......", ".....n......",
                "......rr....", ".......r....", "..mM......", "...mM....."],
    "khien_chan": ["..b..MMMM..b", ".b..MmmmmM..", "b..MmmYYmmM.", "b..MmYmmYmM.", "b..MmmYYmmM.", ".b..MmmmmM..",
                   "..b..MmmM..b", "......MM...."],
    "ngoc_bich": [".....jj.....", "....jJJj....", "...jJwjJj...", "..jJwjjjJj..", "..jJjjjjJj..", "...jJjjJj...",
                  "....jJJj....", ".....jj....."],
}


def build():
    for k, rows in ICONS.items():
        g = grid(rows, PAL)
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        img.alpha_composite(g, ((16 - g.width) // 2, (16 - g.height) // 2))
        save(outline(img), f"ui/buff_{k}.png")


if __name__ == "__main__":
    build()
