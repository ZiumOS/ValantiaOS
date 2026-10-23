from PIL import Image, ImageDraw, ImageFont
import os

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

# Subtle accent rings
draw.ellipse((300, 55, 500, 255), outline=(37, 44, 76), width=2)
draw.ellipse((320, 75, 480, 235), outline=(29, 42, 70), width=1)

# Minimal geometric logo
cx, cy = 400, 155
draw.polygon(
    [(cx, cy - 45), (cx + 34, cy), (cx, cy + 45), (cx - 34, cy)],
    fill=(112, 100, 255)
)
draw.polygon(
    [(cx, cy - 23), (cx + 17, cy), (cx, cy + 23), (cx - 17, cy)],
    fill=(222, 226, 255)
)

font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
regular_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

title_font = ImageFont.truetype(font_path, 34)
sub_font = ImageFont.truetype(regular_path, 13)

def centered_text(text, y, font, fill):
    box = draw.textbbox((0, 0), text, font=font)
    x = (W - (box[2] - box[0])) // 2
    draw.text((x, y), text, font=font, fill=fill)

centered_text("VALANTIAOS", 225, title_font, (245, 246, 255))
centered_text(
    "YOUR SYSTEM. YOUR RULES.",
    270,
    sub_font,
    (155, 165, 195)
)

# Fine accent line
draw.rounded_rectangle(
    (345, 305, 455, 307),
    radius=1,
    fill=(112, 100, 255)
)

os.makedirs("branding/grub", exist_ok=True)
img.save("branding/grub/splash.png", optimize=True)
print("Created ValantiaOS GRUB splash.")