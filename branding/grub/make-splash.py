from PIL import Image, ImageDraw, ImageFont
import os

# GRUB's gfxterm is configured for 800x600 (see live-build's grub-pc
# config.cfg), so render the background at that exact size instead of letting
# the theme upscale a smaller image.
W, H = 800, 600
img = Image.new("RGB", (W, H))
pixels = img.load()

# Dark navy gradient
top = (9, 11, 20)
bottom = (17, 20, 36)

for y in range(H):
    t = y / (H - 1)
    color = tuple(
        int(top[i] * (1 - t) + bottom[i] * t)
        for i in range(3)
    )
    for x in range(W):
        pixels[x, y] = color

draw = ImageDraw.Draw(img)

# Subtle accent rings and geometric ValantiaOS mark.
draw.ellipse((375, 69, 625, 319), outline=(37, 44, 76), width=2)
draw.ellipse((400, 94, 600, 294), outline=(29, 42, 70), width=1)
cx, cy = 500, 194
draw.polygon([(cx - 48, cy - 42), (cx - 28, cy - 42), (cx - 4, cy + 28), (cx - 16, cy + 48)], fill=(112, 100, 255))
draw.polygon([(cx - 8, cy - 42), (cx + 12, cy - 42), (cx + 35, cy + 28), (cx + 23, cy + 48)], fill=(222, 226, 255))
draw.polygon([(cx + 31, cy - 42), (cx + 49, cy - 42), (cx + 25, cy + 28), (cx + 13, cy + 48)], fill=(112, 100, 255))

font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
regular_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

title_font = ImageFont.truetype(font_path, 42)
sub_font = ImageFont.truetype(regular_path, 16)


def centered_text(text, y, font, fill):
    box = draw.textbbox((0, 0), text, font=font)
    x = (W - (box[2] - box[0])) // 2
    draw.text((x, y), text, font=font, fill=fill)


centered_text("VALANTIAOS", 281, title_font, (245, 246, 255))
centered_text(
    "YOUR SYSTEM. YOUR RULES.",
    338,
    sub_font,
    (155, 165, 195)
)

# Fine accent line
draw.rounded_rectangle(
    (431, 381, 569, 384),
    radius=1,
    fill=(112, 100, 255)
)

# live-build expects the GRUB background at config/bootloaders/grub-pc/
# splash.png; the theme's desktop-image resolves to ../splash.png.
out_dir = os.path.join("config", "bootloaders", "grub-pc")
os.makedirs(out_dir, exist_ok=True)
img.save(os.path.join(out_dir, "splash.png"), optimize=True)
print("Created ValantiaOS GRUB splash.")
