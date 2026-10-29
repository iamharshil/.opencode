---
name: video-transcript
description: Learns from YouTube videos without watching them — fetches the transcript, saves it, and returns a structured digest (summary, frameworks, actionable rules, quotes). Use whenever the user shares a YouTube URL and wants to understand or learn from it ("summarize this video", "what does this video say", "extract the lessons", "video notes", "I don't want to watch the whole thing"), or when asked to compare/digest several videos.
---

# Video → Knowledge (transcript workflow)

Goal: turn video URL(s) into usable knowledge. No API keys, no paid tools, zero idle token cost.

## Step 1 — Fetch transcripts

For each video ID (the 11-char code in the URL, e.g. `watch?v=8EAYZe6y3I8`):

```sh
uv run --with youtube-transcript-api python3 -c "
from youtube_transcript_api import YouTubeTranscriptApi
ids = ['VIDEOID']          # extend the list; all fetched in one run
api = YouTubeTranscriptApi()
for vid in ids:
    t = api.fetch(vid, ['en'])
    # plain text, no timestamps: safe for any length, diffs cleanly
    txt = '\n'.join(s.text.replace('\n',' ').strip() for s in t.snippets)
    open(vid + '.txt','w').write(txt)
    print(vid, 'OK', len(txt.split()), 'words')
"
```

Run it in the session temp dir (this environment: `/private/var/folders/.../TempX/opencode/npm-shared_tmp`) or a `research/` folder if the notes belong in the repo. Notes:

- One run fetches many IDs — batch them.
- `['en']` requests English; yt otherwise auto-falls back. For other languages pass e.g. `['es']`.
- ~1000 words ≈ 1 hour talk; a 60-min video is ~10–13k words (~15–20k tokens).
- If a fetch fails (removed captions, region lock), get at least the title/channel with `yt-dlp --skip-download --print "%(title)s [%(channel)s]" URL` and tell the user that video has no usable captions.

## Step 2 — Digest

- **1–2 videos, short (< 4k words each)**: read the `.txt` files directly, then answer.
- **Long or 3+ videos**: dispatch `general` subagent(s) in parallel, one per batch of 3–4 transcripts, with this instruction template: *"Read transcript files <paths>. Each is a YouTube auto-caption transcript. Return a detailed structured digest (500–900 words per video): every named framework/heuristic with the creator's exact framing; concrete numbers, data, examples, app/product names; before/after patterns; and directly actionable rules for <user's context>. Make every rule concrete. Skip only filler/garbled caption noise."*
- **If the user only wants a quick answer to one question**: fetch, grep the transcripts for keywords, quote the relevant passages — skip the full digest.

## Step 3 — Output shape

Unless the user asked otherwise, deliver:
1. **One-line takeaway** per video (the thesis).
2. **Key frameworks/principles** — named, with exact framing.
3. **Concrete numbers/examples** — cited as the creator's claims (label unverified stats).
4. **Actionable rules** — how to apply them here (map to the user's actual project when known).
5. For multi-video batches: a **synthesis section** (where they agree/disagree) and a sources table (title, channel, URL).

If many notes were produced and they reference a repo topic, offer (don't auto-create) a notes file, e.g. `docs/research-<topic>.md`.

## Failed-calls fallback order

1. `youtube-transcript-api` (primary — handled 429 rate-limits that broke yt-dlp)
2. **Invidious instance captions API** (indirect: fetches from the instance's servers, keyless, free) — but flaky by design. YouTube's bot-crackdown waves also take down instance datacenter IPs, so expect dead instances most weeks. Rotate a few:
   ```sh
   for inst in https://inv.nadeko.net https://yewtu.be https://iv.ggtyler.dev https://invidious.jing.rocks https://inv.vern.cc; do
     curl -s -m 12 "$inst/api/v1/captions/VIDEO_ID" ...   # valid XML = working instance; then fetch ?label=English
   done
   ```
3. Freemium REST APIs (need one-time key signup, but their servers absorb blocks): **Supadata** `x-api-key` (100 req/mo free), **YouTubeTranscript.dev** (30 credits/mo), **transcriptapi.com** (100 credits). Only viable if the user accepts a key — otherwise skip.
4. `yt-dlp --skip-download --write-auto-sub --sub-lang=en` (writes `.vtt`; strip cue tags)
5. `webfetch` on `https://www.youtube.com/watch?v=ID` (title/description only)

Reality check (verified Oct 2026): the fully-indirect free paths — Piped (`/streams/{id}`), Invidious APIs, `youtubetranscript.com` — were ALL down simultaneously in YouTube's then-current blocking wave. There is no keyless indirect path that is reliably up. Practical priority: (a) wait out the direct-method throttle (it self-heals), (b) try the Invidious rotation, (c) offer a freemium key only if the user approves.

## Notes

- Heavy bursts (>6 videos in a row) can trigger YouTube's IP throttle: `IpBlocked` / HTTP 429 tools-side. It is temporary (~15–60 min). On throttle: report it, wait, retry once; don't burn retries — and prefer batching future runs modestly with pauses.
- MCP YouTube-transcript servers are deliberately NOT used: they tax every session's context with tool definitions and cap responses at 25k tokens. This shell-based flow is free and unlimited.
- Transcripts are auto-captions: expect garbled names ("Swift Metal" likely = SwiftUI) and cite numeric claims as "creator-reported".
