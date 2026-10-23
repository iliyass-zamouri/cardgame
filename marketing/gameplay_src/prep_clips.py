"""Cut recorded takes into all-intra clips the HTML scene can seek frame-exactly.

Usage: python3 prep_clips.py <hero_take> <side_take> [<side_take> ...]
Writes clips/hero.mp4, clips/side1.mp4 ... and clips/timeline.json (caption cues
in hero-clip seconds, taken from the TRAILER marks in each take's .log).
"""
import json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
TAKES, CLIPS = os.path.join(HERE, 'takes'), os.path.join(HERE, 'clips')
os.makedirs(CLIPS, exist_ok=True)
REC_LEAD = 1.5
MAX_TURNS = int(os.environ.get('MAX_TURNS', 3))  # capture_take.sh sleeps this long between starting the recorder and the app


def marks(name):
    start = int(open(os.path.join(TAKES, name + '.start')).read())
    out = []
    for line in open(os.path.join(TAKES, name + '.log')):
        m = re.search(r'TRAILER mark t=\S+ wall=(\d+) (.*)$', line)
        if m:
            out.append(((int(m.group(1)) - start) / 1000 + REC_LEAD, m.group(2).strip()))
    return out


def find(ms, prefix, nth=0):
    hits = [t for t, label in ms if label.startswith(prefix)]
    return hits[nth] if len(hits) > nth else None


def encode(src, segments, dst, height=1312):
    """Concatenate (start, end) source segments into one all-intra 30fps clip."""
    parts = ''.join(
        f'[0:v]trim={a:.3f}:{b:.3f},setpts=PTS-STARTPTS,fps=30,scale=-2:{height}[v{i}];'
        for i, (a, b) in enumerate(segments))
    concat = ''.join(f'[v{i}]' for i in range(len(segments)))
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', os.path.join(TAKES, src + '.mov'),
                    '-filter_complex', f'{parts}{concat}concat=n={len(segments)}:v=1:a=0[out]',
                    '-map', '[out]', '-c:v', 'libx264', '-g', '1', '-crf', '16', '-pix_fmt', 'yuv420p',
                    '-an', dst], check=True)


def hero(name):
    ms = marks(name)
    dealt, play = find(ms, 'dealt'), find(ms, 'play')
    result = find(ms, 'result')
    turns = [t for t, l in ms if re.match(r'turn \d+ (draw)', l)]
    # Deal + peek, then each turn from its draw to the next. Stops before the result screen.
    segs = [(dealt + 1.2, min(play - 0.4, find(ms, 'peek') + 3.2))]
    cues = [{'t': None, 'cap': 'PEEK AT TWO', 'sub': 'Four cards face down. Memorize two.', 'at': find(ms, 'peek')}]
    turns = turns[:MAX_TURNS]
    for i, t in enumerate(turns):
        end = turns[i + 1] - 0.2 if i + 1 < len(turns) else result - 0.1
        segs.append((t - 0.2, min(end, t + 2.8)))
    # Map source times to clip times.
    def to_clip(src_t):
        acc = 0.0
        for a, b in segs:
            if a <= src_t <= b:
                return acc + src_t - a
            acc += b - a
        return None
    cues[0]['t'] = max(0.0, to_clip(cues[0].pop('at')) - 0.6)
    labels = {'swap': ('DRAW & SWAP', 'Keep the cards worth the least.'),
              'throw': ('THROW IT AWAY', 'Bad draw? Send it to the discard.'),
              'jack': ('JACK: PEEK', 'Spy on your rival’s hand.'),
              'queen': ('QUEEN: SHUFFLE', 'Scramble their memory.')}
    seen = set()
    for t, l in ms:
        m = re.match(r'turn \d+ (swap|throw|jack|queen)', l)
        if m and m.group(1) not in seen:
            seen.add(m.group(1))
            ct = to_clip(t + 0.2)
            if ct is not None:
                cues.append({'t': ct, 'cap': labels[m.group(1)][0], 'sub': labels[m.group(1)][1]})
    cues.sort(key=lambda c: c['t'])
    encode(name, segs, os.path.join(CLIPS, 'hero.mp4'))
    return sum(b - a for a, b in segs), cues


def side(name, idx):
    ms = marks(name)
    a = find(ms, 'dealt') + 0.2
    b = min(find(ms, 'result') - 0.2, a + 20.0)
    encode(name, [(a, b)], os.path.join(CLIPS, f'side{idx}.mp4'), height=900)
    return b - a


if __name__ == '__main__':
    dur, cues = hero(sys.argv[1])
    sides = [side(n, i + 1) for i, n in enumerate(sys.argv[2:])]
    tl = {'hero': dur, 'cues': cues, 'sides': sides}
    json.dump(tl, open(os.path.join(CLIPS, 'timeline.json'), 'w'), indent=1)
    open(os.path.join(CLIPS, 'timeline.js'), 'w').write('window.TL=' + json.dumps(tl) + ';')
    print(json.dumps({'hero': round(dur, 2), 'sides': [round(s, 1) for s in sides]}))
    for c in cues:
        print(f"{c['t']:6.2f}  {c['cap']}")
