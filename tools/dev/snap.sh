#!/bin/bash
# Take a snapshot of the scripts so screenshot runs are not disturbed by edits in the repo.
R=/home/claude/yugioh-crossroads; S=/tmp/snap
rm -rf $S; mkdir -p $S
for x in $(ls -A $R); do
  case $x in
    .git|build|native) ;;
    scripts|scenes|tests|project.godot|export_presets.cfg|icon.png.import) cp -r $R/$x $S/$x ;;
    *) ln -s $R/$x $S/$x ;;
  esac
done
echo snapped
