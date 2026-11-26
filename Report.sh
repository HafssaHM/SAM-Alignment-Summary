#!/usr/bin/bash

# Check argument count
if [ "$#" -lt 2 ]; then  
  echo "Usage: $0 file1.sam [file2.sam ...] assemblyreport.txt"
  exit 1
fi

# Classify files depending on the extension
input_files=()
assembly_report=""

for arg in "$@"; do
  case "$arg" in
    *.sam) input_files+=("$arg") ;;
    *.txt) assembly_report="$arg" ;;
    *) echo "Warning: ignored argument $arg" ;;
  esac
done

# Verifications
if [ -z "$assembly_report" ]; then
  echo "ERROR: Assembly report not provided (.txt)"
  exit 1
fi

if [ "${#input_files[@]}" -eq 0 ]; then
  echo "ERROR: No SAM files provided (.sam)"
  exit 1
fi

# Start timer
start_timer=$(date +%s)

# Initialize the output
out="output1.txt"
: > "$out"

# Function to process one alignment file
process_alignment() {
  local file="$1"
  echo "==== File: $file ====" >> "$out"

  awk -v AR="$assembly_report" '
    BEGIN {
      FS = "\t"
      while ((getline line < AR) > 0) {
        if (line ~ /^#/ || line == "") continue
        n = split(line, f, "\t")
        genbank = f[5]
        chrom = f[3]
        if (genbank != "na") acc2chr[genbank] = chrom
      }
      close(AR)
    }
    $0 !~ /^@/ {
      total++
      if ($3 != "*") {
        aligned++
        counts[$3]++
      }
    }
    END {
      print "Total reads processed: " total
      print "Aligned reads: " aligned
      print ""
      print "Accession\tChromosome\tCount"
      for (acc in counts) {
        chr = (acc in acc2chr ? acc2chr[acc] : "NA")
        printf "%s\t%s\t%d\n", acc, chr, counts[acc]
      }
    }
  ' "$file" >> "$out"

  echo "" >> "$out"
}

# Main loop
for f in "${input_files[@]}"; do
  process_alignment "$f"
done

# Calculate and log execution time
end_time=$(date +%s)
elapsed=$((end_time - start_timer))

echo "==== Summary ====" >> "$out"
echo "Processed ${#input_files[@]} alignment file(s)" >> "$out"
echo "Execution time (seconds): $elapsed" >> "$out"

echo "[DONE] REPORT SAVED IN $out"
