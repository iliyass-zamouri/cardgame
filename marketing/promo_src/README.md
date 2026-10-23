# ShadowHand promo video source

Output: `../shadowhand_promo.mp4` (1920x1080, 30fps, 28s)

To re-render, run these commands from this folder:

    ln -sfn ../../assets assets
    npm i playwright-core@1.56.1
    node render.mjs video.mp4 30          # frames -> video.mp4 (uses system Google Chrome)
    python3 music.py && python3 mix.py    # music.wav + game SFX -> audio.wav
    ffmpeg -i video.mp4 -i audio.wav -c:v copy -c:a aac -b:a 192k -shortest ../shadowhand_promo.mp4

Real app screenshots: put them in `shots/` and list them in `scene.html` (`SHOTS`).
SHOT[0] fills the center phone in "Learn in minutes"; SHOT[1] and SHOT[2] replace two of the side phones.
Preview any moment: `node render.mjs stills 30 4.2,10.5,26`
