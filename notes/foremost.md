# Foremost -- File Carving & Recovery

## What It Does

Foremost recovers deleted and embedded files from disk images, memory dumps, and raw data by matching known file header and footer signatures (magic bytes). Unlike filesystem-based recovery tools, foremost works directly on raw binary data -- it doesn't need an intact filesystem.

## Running the Examples Script

```bash
# No target argument required
bash scripts/foremost/examples.sh

# Or with a disk image
bash scripts/foremost/examples.sh image.dd

# Or via Makefile
make foremost

# Examples
bash scripts/foremost/examples.sh
bash scripts/foremost/examples.sh /path/to/disk.img
```

The script prints 10 example commands with explanations, then offers to show the foremost version or run a demo on the provided image.

## Key Flags to Remember

| Flag | What It Does |
| ------ | ------------- |
| `-i <input>` | Input file (disk image, raw data, partition) |
| `-o <dir>` | Output directory (must not exist already) |
| `-t <types>` | File types to recover (jpg,pdf,doc,exe,zip,all) |
| `-v` | Verbose -- show progress and details |
| `-q` | Quick mode -- skip footer validation for faster processing |
| `-T` | Add timestamp to output directory name |
| `-c <config>` | Use custom configuration file |
| `-b <size>` | Block size in bytes (default: 512) |
| `-d` | Indirect block detection (ext2/3 filesystems) |
| `-s <blocks>` | Skip number of blocks before carving |

## Supported File Types

| Category | Types | Description |
| -------- | ----- | ----------- |
| Images | jpg, gif, png, bmp | Common image formats |
| Documents | pdf, doc, xls, ppt | PDF and Microsoft Office |
| Archives | zip, rar | Compressed archives |
| Web | htm | HTML files |
| Code | cpp | C++ source files |
| Executables | exe | Windows executables |
| Media | mp4, mov, avi, wav, wmv | Audio and video files |
| Other | ole | OLE compound documents |

## Carving Progression (recommended order)

1. `foremost -i image.dd -o recovered/` -- basic recovery, see what's there
2. `foremost -v -i image.dd -o recovered/` -- verbose for progress
3. `foremost -t jpg,pdf,doc -i image.dd -o specific/` -- target specific types
4. Review `recovered/audit.txt` for summary of recovered files
5. `ls -lR recovered/` -- verify recovered files

## Use-Case Scripts

### recover-deleted-files.sh -- Recover deleted files from disk images

Demonstrates how deleted files remain recoverable because the OS only removes directory entries, not the actual data blocks. Uses foremost to scan raw data for file signatures and reconstruct complete files.

**When to use:** Recovering accidentally deleted files, forensic investigation of deleted data, understanding why secure deletion matters.

**Key commands:**

```bash
# Recover all files from disk image
foremost -i disk.img -o recovered/

# Recover from USB drive image
foremost -i usb_backup.dd -o usb_recovered/

# Skip partition table blocks then recover
foremost -s 63 -i disk.img -o recovered/

# Recover from memory dump
foremost -i memdump.raw -o mem_recovered/

# Full recovery pipeline with audit
foremost -v -T -i disk.img -o recovered/ && ls -lR recovered/
```

**Make target:** `make recover-deleted TARGET=<image>`

---

### carve-specific-filetypes.sh -- Carve specific file types using magic bytes

Explains file signatures (magic bytes) and demonstrates how to target specific file types during recovery. Covers images, documents, archives, executables, and media files.

**When to use:** When you only need specific file types from a large image, when you want faster recovery by limiting scope, or when investigating what types of files existed on a disk.

**Key commands:**

```bash
# Extract only JPEG images
foremost -t jpg -i disk.img -o recovered_jpg/

# Extract Microsoft Office documents
foremost -t doc,xls,ppt -i disk.img -o recovered_office/

# Extract all image types
foremost -t jpg,gif,png,bmp -i disk.img -o recovered_images/

# Extract media files
foremost -t mov,mp4,avi,wav,wmv -i disk.img -o recovered_media/

# Extract archives
foremost -t zip,rar -i disk.img -o recovered_archives/
```

**Make target:** `make carve-filetypes TARGET=<image>`

---

### analyze-forensic-image.sh -- Forensic file carving with evidence preservation

Demonstrates forensic analysis workflows including evidence imaging, hash verification, audit trails, and batch processing. Emphasizes that foremost never modifies the source image.

**When to use:** Digital forensics investigations, incident response, evidence analysis where chain of custody matters.

**Key commands:**

```bash
# Verbose analysis with audit trail
foremost -v -i evidence.dd -o case001/ 2>&1 | tee foremost_log.txt

# Timestamped evidence extraction
foremost -T -i evidence.dd -o case001/

# Recover artifacts from memory dump
foremost -i memory.raw -t jpg,pdf,doc -o mem_artifacts/

# Batch process multiple evidence images
for img in evidence_*.dd; do foremost -T -i "$img" -o "case_${img%.dd}/"; done

# Full forensic workflow (image, hash, carve)
dd if=/dev/sdb of=evidence.dd bs=4k status=progress && sha256sum evidence.dd > evidence.sha256 && foremost -v -T -i evidence.dd -o case001/
```

**Make target:** `make analyze-forensic TARGET=<image>`

## Practice

Create a test disk image for safe practice without risking real data:

```bash
# Create a 10MB blank disk image
dd if=/dev/zero of=test_disk.img bs=1M count=10

# Format it (macOS)
# Note: mkfs is Linux -- on macOS use diskutil or hdiutil
hdiutil attach -nomount test_disk.img
# Then use diskutil to format the mounted device

# Simpler approach: create a file, embed it in raw data, then carve
dd if=/dev/zero of=test.img bs=1M count=5
# Copy a JPEG into the raw image at an offset
dd if=sample.jpg of=test.img bs=1 seek=1024 conv=notrunc
# Now recover it
foremost -v -t jpg -i test.img -o practice_recovered/
# Check audit.txt for results
cat practice_recovered/audit.txt
```

## Notes

- Output directory must not exist -- foremost will not overwrite. Use `-T` for timestamped dirs.
- Always work on copies for forensic work -- foremost reads input read-only but best practice is to image first.
- The `audit.txt` file in the output directory summarizes all recovered files.
- Foremost's config file (`/usr/local/etc/foremost.conf` or `/etc/foremost.conf`) defines file signatures.
- For custom file types, add new header/footer signatures to the config file.
- Compared to other carving tools: foremost is simple and fast; scalpel offers more precision; photorec is interactive.
- Foremost works on any raw binary data: disk images, memory dumps, network captures converted to raw.
- Large images take time -- use `-t` to target specific types for faster results.
