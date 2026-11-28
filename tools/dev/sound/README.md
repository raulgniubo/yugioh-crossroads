# Sound (0.87.0): real sounds and music made with ElevenLabs
Raul approved the plan (doc "Plan de sonido · Yu-Gi-Oh! Crossroads") on Nov 28 and lifted the credit cap.
All of it is made: 140 short sounds, 10 loops of air (30 s), 18 music tracks. 24,443 credits (`made.json`).

## What is where
- `spec.py` -> `sounds.json`: [name, seconds, prompt] for every sound, loop and track.
- `audio/sounds/<name>.ogg` (mono), `audio/ambience/<kind>.ogg`, `audio/music/<track>.ogg` (stereo). 28 MB in all.
- `Sfx.own_file(folder, name)`: a file of the player's in the card folder wins, then the game's own (`Sfx.bundled`),
  and with neither the tone made by code plays, so a missing file never leaves a hole.
- Names = the names the game already played, plus: `sig_<shape>` (SigFx), `st_<key>` (StrikeFx.CARD_SOUNDS),
  ace_enter, boss_enter, fate_draw, attack_stopped, gone_<style>, notify, purchase, deck_save, star_chip, unlock.
  `Sfx.play_own(name)` says whether there was a real file; `Sfx.play_or(name, fallback)` plays the old one if not.
- The air of a place is `Sfx.ambience(kind)` / `Sfx.weather(kind)` as before: they play `audio/ambience/<kind>.ogg`
  when there is one (city night sea satellite newdomino heartland museum shop crowd rain); engine, tunnel and wind
  keep the loops made by code (their pitch follows the speed). It plays on the "Ambience" bus (under SFX), which has
  its own slider in Settings. There is NO second ambience player: an earlier `Music.ambience` doubled the air.
- `Music.play_place(district, fallback)` plays a world's own file ("newdomino" has no generated track).
- A hard limiter sits on the Master bus (Settings._ensure_buses): recorded sounds have sharper peaks than the tones.

## Making or remaking a sound
1. Flow `wWVEW1kMqjoFua8oGtTV` (ElevenLabs): 20 sfx nodes (`flow.json` "nodes") and 18 music nodes ("music_nodes").
   `python3 batch.py N [sounds|ambience]` prints the updates for creative_update_flow_nodes (batch N = entries 20N..).
   Run the nodes ONCE with generations_count 1. Never repeat a run to retry: a retake is a new prompt and is counted.
2. Collect by GENERATION id (not node id: a node gives its previous take while the new one is still cooking):
   creative_execute_sandbox(inputs=[{"generation_id": ...}]) copies them into the session; `pack.py` there joins the
   short sounds into one wav with fixed slots (spec seconds + 0.4 s each, a 0.1 s beep first).
3. Download: short sounds as the pack's preview mp3 (creative_get_available_assets -> preview_url, 128 kbps);
   ambience and music as the originals (creative_get_generations -> full_res_url, 4 ids a call). The sandbox here cannot
   reach that host: Blender on Raul's Mac fetches them (urllib) into Downloads/Yu-Gi-Oh! Crossroads/sound_work/, then
   device_stage_files.
4. `python3 -I process.py <downloads> <repo> <listen dir>`: cuts the pack (the last 70 ms of each slot are dropped: the
   mp3 smears the next attack back into it), trims silence, fades cut endings, levels each sound to the tone it
   replaces (loudest 100 ms = the tone's RMS + 3 dB, from `--sound-audit`), eases peaks so none passes -4 dB (a duel
   plays sounds 4 dB up, several at once), crossfades the ambience into a seamless loop, levels music to the old
   tracks (-20.5 dB RMS for battle, about -23.5 for places), writes ogg into audio/ and mp3 copies to listen to.
5. `godot --headless --path . --import`, then tests `_test_sound_087` (ONLY_TEST=_test_sound_087 runs it alone).

## Checking the mix without ears
`/tmp/movie.sh <tag> <frames> <game args>` runs the game with --write-movie: the avi holds the real mixed sound.
`match.py <recording.wav> <file.ogg>` finds a given file in it and says how loud it plays. Found that way in 0.87.0:
the menu track, a duel's theme, the crowd, the card draw, Mirror Force's own sound, Satellite's track and air; no
clipping. It is also how the silent-duel bug showed up (Music._switch, fixed in 0.87.0).

## Rules
All original, no voices, no imitation of the show's music. Each animation's sound ends with it (only air and music loop).
