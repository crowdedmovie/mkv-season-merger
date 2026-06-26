# MKV Season Merger

Merge multiple MKV episodes into a single MKV file while automatically creating chapter markers from each episode.

Perfect for TV shows, anime, documentaries, or any multi-part content.

## Features

- Merge all `.mkv` files in the current folder
- No re-encoding (`-c copy`)
- No quality loss
- Streams concat and chapter metadata in memory
- Chapter titles are taken from the original filenames
- Episodes are merged in filename order

## Requirements

- Bash
- FFmpeg (includes `ffprobe`)
- FFmpeg must be available in your `PATH`

## Usage

Place the script in the folder containing your MKV files and run:

```bash
chmod +x script.sh
./script.sh
```

You can also override the output file name:

```bash
./script.sh --output-file "Season 1.mkv"
```

The script will:

1. Generate the FFmpeg concat file list in memory.
2. Calculate the duration of every episode.
3. Generate chapter metadata in memory.
4. Produce a single MKV containing every episode.

## Notes

- All MKV files should have compatible codecs and stream layouts.
- Files are processed in alphabetical order.
- The bash script does not write persistent `.txt` helper files.

## License

GNU General Public License v3.0 or later