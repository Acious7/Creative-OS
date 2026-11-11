import os
from PIL import Image

artifact_dir = r"C:\Users\Etole\.gemini\antigravity-ide\brain\41d9e517-5821-419a-82c2-9746e5c15fde"
frames_dir = os.path.join(artifact_dir, "hub_frames")

hub_img = Image.open(os.path.join(artifact_dir, "hub_dark_master.png")).convert("RGBA")
world_img = Image.open(os.path.join(artifact_dir, "hub_world_entry.png")).convert("RGBA")

# Resize down slightly to 540x1200 for silky-smooth lightweight animation preview
w, h = 540, 1200
hub_scaled = hub_img.resize((w, h), Image.Resampling.LANCZOS)
world_scaled = world_img.resize((w, h), Image.Resampling.LANCZOS)

anim_frames = []
durations = []

# 1. Hub Screen holds for 1.2s
anim_frames.append(hub_scaled)
durations.append(1200)

# 2. Letter reveal transition sequence
for i in range(8):
    f_path = os.path.join(frames_dir, f"trans_frame_{i:02d}.png")
    if os.path.exists(f_path):
        f_img = Image.open(f_path).convert("RGBA").resize((w, h), Image.Resampling.LANCZOS)
        anim_frames.append(f_img)
        durations.append(85)

# 3. World Entry Screen holds for 1.4s
anim_frames.append(world_scaled)
durations.append(1400)

out_webp = os.path.join(artifact_dir, "hub_journey_recording.webp")
anim_frames[0].save(
    out_webp,
    format="WEBP",
    save_all=True,
    append_images=anim_frames[1:],
    duration=durations,
    loop=0,
    quality=88
)

print(f"Generated animated recording at {out_webp} ({os.path.getsize(out_webp)} bytes)")
