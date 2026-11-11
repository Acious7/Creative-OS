import os
from PIL import Image

artifact_dir = r"C:\Users\Etole\.gemini\antigravity-ide\brain\41d9e517-5821-419a-82c2-9746e5c15fde"
cards_dir = os.path.join(artifact_dir, "stage_cards")
frames_dir = os.path.join(artifact_dir, "stage_frames")

stage_front = Image.open(os.path.join(cards_dir, "stage_master_dark.png")).convert("RGBA")
stage_back = Image.open(os.path.join(cards_dir, "stage_flipped_back.png")).convert("RGBA")
stage_qr = Image.open(os.path.join(cards_dir, "stage_qr_overlay.png")).convert("RGBA")

w, h = 540, 1200
front_scaled = stage_front.resize((w, h), Image.Resampling.LANCZOS)
back_scaled = stage_back.resize((w, h), Image.Resampling.LANCZOS)
qr_scaled = stage_qr.resize((w, h), Image.Resampling.LANCZOS)

anim_frames = []
durations = []

# 1. Front of card under spotlight with pills & drawer (1.5s)
anim_frames.append(front_scaled)
durations.append(1500)

# 2. Flip animation sequence frames
for i in range(1, 9):
    f_path = os.path.join(frames_dir, f"stage_frame_{i:02d}.png")
    if os.path.exists(f_path):
        f_img = Image.open(f_path).convert("RGBA").resize((w, h), Image.Resampling.LANCZOS)
        anim_frames.append(f_img)
        durations.append(70)

# 3. Back of card (flipped) on stage (1.4s)
anim_frames.append(back_scaled)
durations.append(1400)

# 4. Opening QR sequence
for i in range(9, 11):
    f_path = os.path.join(frames_dir, f"stage_frame_{i:02d}.png")
    if os.path.exists(f_path):
        f_img = Image.open(f_path).convert("RGBA").resize((w, h), Image.Resampling.LANCZOS)
        anim_frames.append(f_img)
        durations.append(100)

# 5. Full screen high-contrast QR display (1.6s)
anim_frames.append(qr_scaled)
durations.append(1600)

out_webp = os.path.join(artifact_dir, "stage_journey_recording.webp")
anim_frames[0].save(
    out_webp,
    format="WEBP",
    save_all=True,
    append_images=anim_frames[1:],
    duration=durations,
    loop=0,
    quality=88
)

print(f"Generated stage recording at {out_webp} ({os.path.getsize(out_webp)} bytes)")
