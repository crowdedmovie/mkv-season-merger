# MKV Season Merger

Merge multiple MKV episodes into a single MKV file while automatically creating chapter markers from each episode.

Perfect for TV shows, anime, documentaries, or any multi-part content.

## Features

- Merge all `.mkv` files in the current folder
- No re-encoding (`-c copy`)
- No quality loss
- Automatically generates `files.txt`
- Automatically generates chapter metadata
- Chapter titles are taken from the original filenames
- Episodes are merged in filename order

## Requirements

- Windows PowerShell
- FFmpeg (includes `ffprobe`)
- FFmpeg must be available in your `PATH`

## Usage

Place the script in the folder containing your MKV files and run:

```powershell
.\concat.ps1
```

The script will:

1. Generate the FFmpeg concat file list.
2. Calculate the duration of every episode.
3. Generate chapter metadata.
4. Produce a single MKV containing every episode.

## Notes

- All MKV files should have compatible codecs and stream layouts.
- Files are processed in alphabetical order.

## License

MIT