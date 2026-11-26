# 🧬 SAM Alignment Summary — Bash Script

> Bash + AWK tool that summarises one or several **SAM** alignment files using an **NCBI assembly report**: total reads, aligned reads and reads per chromosome.

---

## 📑 Table of contents

- [Background](#-background)
- [Features](#-features)
- [Requirements](#-requirements)
- [Usage](#-usage)
- [Workflow](#-workflow)
- [How it works](#-how-it-works)
- [Results](#-results)
- [Alternative approach: samtools](#-alternative-approach-samtools)
- [Repository structure](#-repository-structure)
- [Report](#-report)

---

## 📖 Background

The **Sequence Alignment/Map (SAM)** format is a text-based format that stores the results of aligning nucleotide sequences (DNA/RNA) against reference sequences. It supports short and long reads and can contain both mapped and unmapped reads.

An **assembly report** is a tab-delimited file that maps accession numbers (e.g. GenBank `CP122180.1`) to chromosome names (e.g. `X`).

This script combines both: it reads the SAM files, counts the alignments per reference and translates each accession into its chromosome using the assembly report.

## ✨ Features

- Accepts **one or multiple** `.sam` files plus one assembly report (`.txt`) in any order.
- Classifies the arguments by file extension; unsupported arguments are ignored with a warning.
- Validates the input and stops with a clear error if the assembly report or all SAM files are missing.
- For each SAM file reports:
  - total number of reads,
  - number of aligned reads,
  - number of reads per reference accession, with its chromosome (or `NA` if it is not in the assembly report).
- Writes everything to a single output file and logs the **execution time**.

## 🔧 Requirements

- Linux / macOS with `bash`
- `awk` (standard on any Unix system)

No further dependencies. (`samtools` is only used for the optional validation described [below](#-alternative-approach-samtools).)

## 🚀 Usage

```bash
chmod +x Report.sh
./Report.sh file1.sam [file2.sam ...] assemblyreport.txt
```

Examples:

```bash
# One SAM file
./Report.sh file.sam assemblyreport.txt

# Several SAM files
./Report.sh file.sam mbio.sample.sam assemblyreport.txt
```

The results are written to **`output1.txt`** (the file is overwritten on every run).

### Input validation

| Situation | Behaviour |
|---|---|
| Fewer than 2 arguments | Prints usage and exits |
| No `.txt` assembly report | `ERROR: Assembly report not provided (.txt)` and exits |
| No `.sam` file | `ERROR: No SAM files provided (.sam)` and exits |
| Argument with another extension | `Warning: ignored argument <arg>` and continues |

![Input validation messages](images/fig4_validation.png)
*Figure 4 — Errors and warnings displayed by the script.*

## 🗺️ Workflow

![Bash script workflow](images/fig1_workflow.png)
*Figure 1 — Bash script workflow.*

1. Read the arguments and classify them by extension (`.sam` → input files, `.txt` → assembly report).
2. Verify that the assembly report and at least one SAM file exist; otherwise, exit with an error.
3. Initialise `output1.txt` and start the timer.
4. For each SAM file, run the AWK process: parse the assembly report, count reads and map chromosomes.
5. Append a summary (number of processed files and execution time) to the output.

## ⚙️ How it works

The core of the script is the `process_alignment()` function, called once per SAM file inside a loop so that each file is processed independently. It pipes the SAM file through an AWK program with three blocks:

| Block | What it does |
|---|---|
| `BEGIN` | Runs once before reading the SAM file. Parses the assembly report and builds a dictionary **GenBank accession → chromosome** (column 5 → column 3). Comment lines (`#`) and rows with `na` are skipped. |
| Main | Processes the SAM file line by line, skipping header lines (those starting with `@`). For every read it increments the **total** count; if the reference field (`$3`) is not `*`, it increments the **aligned** count and the counter for that accession. |
| `END` | Prints total reads, aligned reads and a table `Accession / Chromosome / Count`. Accessions that are not in the assembly report are labelled `NA`. |

The distinction between header and alignment lines is based on the `@` character: header lines start with it, alignment lines do not.

## 📊 Results

### Input files used for testing

![Input files](images/fig3_input_files.png)
*Figure 3 — File sizes and content of the SAM file and the assembly report.*

### Execution

![Execution with one SAM file](images/fig2_execution.png)
*Figure 2 — Execution of the script with a SAM file and an assembly report.*

![Execution with two SAM files](images/fig5_two_sam.png)
*Figure 5 — Execution with two SAM files and an assembly report.*

### Output file

![Output file](images/fig6_output.png)
*Figure 6 — Output file result.*

Example output (`file.sam`):

```text
==== File: file.sam ====
Total reads processed: 368465
Aligned reads: 345231

Accession       Chromosome      Count
CP122177.1      3L      73734
CP122176.1      2R      63826
CP122179.1      4       3720
CP122175.1      2L      58436
CP122178.1      3R      77924
CP122180.1      X       67591

==== Summary ====
Processed 1 alignment file(s)
Execution time (seconds): 2
```

> ℹ️ The accession order in the table is not sorted, since AWK iterates over associative arrays in an arbitrary order. Pipe the table through `sort` if you need a fixed order.

## 🔬 Alternative approach: samtools

As an independent check of the alignment and read distribution, the same analysis was run with `samtools` (`idxstats`).

![samtools output](images/fig7_samtools.png)
*Figure 7 — Alternative output obtained with samtools.*

| | AWK script | samtools |
|---|---|---|
| Aligned reads (`file.sam`) | 345,231 | 341,858 |
| Execution time | ~2 s | ~8.5 s |

**Performance (SAM vs BAM).**
- **BAM** files (compressed, sorted, indexed) allow faster operations on large datasets but need additional preprocessing.
- **SAM** files are uncompressed plain text, so they are easy to parse but can be slower on large datasets.

For this small dataset, parsing the SAM directly with AWK was faster than going through `samtools`.

**Why the counts differ.**
- The AWK script is more **inclusive**: it counts every read with `$3 != "*"`, including secondary, supplementary, duplicate and low-quality alignments.
- `samtools` applies **stricter criteria**, counting only primary, high-quality alignments.
- AWK maps references through the **assembly report**, whereas `samtools idxstats` counts reads directly by reference name.

## 📁 Repository structure

```text
.
├── Report.sh                      # Main script
├── README.md
├── .gitignore
├── images/                        # Figures used in this README
│   ├── fig1_workflow.png
│   ├── fig2_execution.png
│   ├── fig3_input_files.png
│   ├── fig4_validation.png
│   ├── fig5_two_sam.png
│   ├── fig6_output.png
│   └── fig7_samtools.png
└── docs/
    └── Report_Assignment_1.pdf    # Full assignment report
```

> The SAM files and the assembly report used in the assignment are not included in the repository because of their size.

## Project context

Assignment for **Programming in Bioinformatics** — Master's in Bioinformatics, Universitat Autònoma de Barcelona (UAB).

**Authors:** Annalisa Monetta · Hafssa El Hany Milada
