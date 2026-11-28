# Sound (0.87.0): real sounds and music made with ElevenLabs
Raul approved the plan (doc "Plan de sonido · Yu-Gi-Oh! Crossroads") on Nov 28 and lifted the credit cap.
- `spec.py` -> `sounds.json`: 118 sounds, 6 ambience loops (15 s), 14 music tracks. [name, seconds, prompt].
- Files land in `audio/sounds/<name>.ogg`, `audio/ambience/<name>.ogg`, `audio/music/<name>.ogg` (mono 44.1 kHz ogg for
  sounds; stereo for ambience and music). Sfx.own_file() finds them (a file of the player's in the card folder wins;
  with neither, the tone made by code plays). Names = the names the game already plays, plus: sig_<shape> (SigFx),
  st_<key> (StrikeFx.CARD_SOUNDS), ace_enter, boss_enter, fate_draw, attack_stopped, gone_<style>.
- Music.play_place(district, fallback) plays a world's own file ("newdomino" has no generated track);
  Music.ambience(name) loops audio/ambience/<name>.ogg under the music (worlds by district key, "arena" in duels).
- Made so far: see `made.json` (name -> credits balance after it). Nothing is "done" until its file is in audio/.
- Rules: all original, no voices, no imitation of the show's music; never repeat a generation call to retry
  (change the prompt, count it as a retake).
