# ShadowHand gameplay promo source

Output: `../shadowhand_gameplay.mp4` (1920x1080, 30fps, 30.5s). Every phone shows real
recorded gameplay from the app's TRAILER_SHOT build (offline vs Robot); nothing is mocked.

1. Build and install the capture build on the booted simulator (from the repo root):

       fvm flutter build ios --simulator --debug --dart-define-from-file=flavors/dev.json --dart-define=TRAILER_SHOT=match
       xcrun simctl install booted build/ios/iphonesimulator/Runner.app

2. Record takes (writes takes/<name>.mov, .log with TRAILER marks, .start):

       ./capture_take.sh t9 "shot=match stake=500 deck=royal_crimson avatar=golden-king name=Ace turns=8"

3. Cut clips: the first take is the hero, the rest go on the side phones in the fan.
   The hero stops before the result screen.

       MAX_TURNS=5 python3 prep_clips.py t5 t2 t3 t4 t7

4. Render the video and audio, then mux:

       ln -sfn ../../assets assets && npm i playwright-core@1.56.1
       node render.mjs video.mp4 30
       python3 music.py && python3 mix.py
       ffmpeg -i video.mp4 -i audio.wav -c:v copy -c:a aac -b:a 192k -shortest ../shadowhand_gameplay.mp4

Caption text per move lives in `prep_clips.py` (labels); layout and timing in `scene.html`.
