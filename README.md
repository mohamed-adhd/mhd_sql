<div align="center">

# mhd_sql

**A bare-metal SQLite file reader written in raw x86-64 NASM assembly — no libc, no `sqlite3` library, just direct Linux syscalls parsing the SQLite file format byte by byte to find a table and dump its rows.**

![NASM](https://img.shields.io/badge/NASM-x86--64-D64541?style=flat-square)
![Linux](https://img.shields.io/badge/Linux-Syscalls-FCC624?style=flat-square&logo=linux&logoColor=black)
![No libc](https://img.shields.io/badge/libc-none-8F6BFF?style=flat-square)
![SQLite](https://img.shields.io/badge/Format-SQLite%20File-003B57?style=flat-square&logo=sqlite&logoColor=white)
![ELF64](https://img.shields.io/badge/Output-ELF64-5B4CFF?style=flat-square)

</div>

<h2 align="center">Overview</h2>

`mhd_sql` opens a raw `.sqlite` file with a plain `open` syscall and manually walks its on-disk format: the 100-byte database header, the B-tree page structure, varint-encoded record headers, and the `sqlite_schema` table — all without touching the actual SQLite library. Given a table name as `argv[1]`, it locates that table's root page by scanning `sqlite_schema`, reads the page, and prints every row's column values to stdout, separated by `||`.

It's a from-scratch reimplementation of the read path SQLite itself uses internally, done entirely in assembly against raw syscalls (`open`, `fstat`, `lseek`, `read`, `write`, `exit`).

<h2 align="center">Core Workflow</h2>

```
_start
  |
  v
open(argv[1]) -> fd
  |
  v
fstat -> file size
  |
  v
read database header -> page size
  |
  v
read page 1 (sqlite_schema root page)
  |
  v
page type == 0x0D (leaf)? ---- no ----> exit
  |
  yes
  v
checkit: scan cell pointers, decode each record header,
extract table name, strcmp against argv[1]
  |
  v
match found? ---- no ----> print "table doesnt exist twin" -> exit
  |
  yes
  v
decode matched record -> extract rootpage varint (1-4 byte int)
  |
  v
seek to rootpage * page_size, read that page
  |
  v
page type == 0x0D (leaf)? ---- no ----> exit (interior not yet supported)
  |
  yes
  v
read_column loop: read_varint -> decode_serial_type -> process_column
  |
  v
print each column (TEXT / INTEGER) separated by "||", one row per cell
  |
  v
exit(0)
```

<h2 align="center">What It Does</h2>

| Area | Details |
|---|---|
| File access | Opens the target file directly via the `open` syscall, no `fopen`/libc involved. |
| Header parsing | Reads the 100-byte SQLite header to get page size, computes total page count via `fstat` + division. |
| Schema lookup | Walks `sqlite_schema` (page 1) cell pointer array, decodes each record's varint header, and string-compares the table name against `argv[1]`. |
| Root page resolution | Once the table's `sqlite_schema` row is found, decodes its `rootpage` column (1–4 byte big-endian integer depending on serial type) and seeks to that page. |
| Row decoding | Reads the leaf page's cell pointer array, then for each cell: reads the record header varints, decodes each column's serial type, and dispatches to print TEXT or INTEGER values. |
| Varint decoding | `read_varint` implements SQLite's variable-length integer encoding (up to 9 bytes, 7 bits per byte + continuation bit). |
| Serial type decoding | `decode_serial_type` / `get_len` map SQLite's column serial type codes to a concrete length + type (NULL, int1–int8, float8, TEXT, BLOB). |
| Output | Column values are written straight to stdout via the `write` syscall, separated by a `||` delimiter, one row per line. |

<h2 align="center">Code Map</h2>

Since this is a single-file assembly program, here's what each label does instead of a directory layout:

| Label | Role |
|---|---|
| `_start` | Entry point — opens the file, reads the header, dispatches on page 1's type. |
| `checkit` | Scans `sqlite_schema`'s cell pointers looking for a table name match. |
| `checkthashi` | Validates the `open` syscall return value (bails if negative). |
| `read_varint` | Decodes a SQLite varint at `[cursor]`, advances the cursor. |
| `decode_serial_type` | Maps a column's serial type varint to a concrete `(length, type)` pair. |
| `get_len` | Same idea as `decode_serial_type`, used during the schema-row scan. |
| `read_column` / `process_column` | Iterates a record's columns and prints TEXT/INTEGER values. |
| `load_int_be` / `itoa` | Reads a big-endian integer column and converts it to ASCII for printing. |
| `FOUNDIT` / `got_rootpage` | Extracts the matched table's root page number and seeks/reads that page. |
| `strcmp_name` | Manual byte-by-byte string comparison (table name vs. `argv[1]`). |
| `readnbytes` | Wraps `lseek` + `read` into a single seek-then-read helper. |
| `exit` | Single shared exit point (`sys_exit`, syscall 60). |

<h2 align="center">Current Limitations</h2>

- **B-tree leaf pages only.** Both the `sqlite_schema` scan and the target table's row scan only handle leaf pages (type `0x0D`). If either lands on an **interior page** (`0x05`/`0x02`), the program just exits — `schema_interior` and the `.interior` branches are present as stubs but not implemented.
- This means tables (or the schema table itself) that span **multiple pages** and require walking an interior B-tree to find the right leaf will not be read correctly.
- Only **TEXT** and **INTEGER** columns are printed; BLOB and FLOAT serial types are decoded (length/type resolved) but not yet handled in `process_column`.
- Exact, case-sensitive table name match only — no `WHERE` filtering, no partial matches, no multi-table queries.

<h2 align="center">Planned Improvements</h2>

- Implement interior B-tree page traversal (`schema_interior`, `.interior`) to recursively descend to the correct leaf page for both the schema table and target tables.
- Support tables large enough to span multiple leaf pages.
- Add BLOB and FLOAT8 column printing in `process_column`.
- Handle overflow pages for large cell payloads.

<h2 align="center">Build & Run</h2>

Build with NASM + `ld` via the included Makefile:

```bash
make sqldriver
```

Generate a test database:

```bash
make test.sqlite
```

Run it:

```bash
./sqldriver test.sqlite people
```

Clean build artifacts:

```bash
make clean
```

<h2 align="center">Tech Stack</h2>

| Tech | Usage |
|---|---|
| NASM | Assembling `sqldriver.asm` into ELF64 object code |
| `ld` | Linking the final static binary |
| Linux syscalls | `open`, `fstat`(via syscall 5), `lseek`, `read`, `write`, `exit` — no libc |
| SQLite file format | B-tree pages, varints, record headers, serial types — parsed manually |

<h2 align="center">Why I Built This</h2>

yea this may be my straight up worst repo i ever made ... just straight pain and terror , i dont like assembly at all yet it attracts me like a magnet , overall this repo helped me understand the sql schema on byte level , really enjoyed the header and records and the cells , still i stopped bcz i understood what i needed , anything more is an endless rabbit-hole for later , gg thou it was such a hellish experience

<h2 align="center">Developer Notes</h2>

- hours : 79
- only reads b-tree leaf pages 
- somehow with enough syscalls it works , only god knows how

