#!/usr/bin/env python3
"""
Parallel FASTQ Remultiplexing Script

This optimized script processes multiple FASTQ files in parallel using multiple CPU cores,
significantly reducing processing time for large numbers of files.

Usage:
    python remultiplex_fastq_parallel.py input_dir output_file.fastq.gz --cores 8
"""

import os
import sys
import gzip
import argparse
from pathlib import Path
import itertools
import multiprocessing as mp
from concurrent.futures import ProcessPoolExecutor, as_completed
import time
from collections import defaultdict

def generate_barcodes(num_files, barcode_length=8):
    """Generate unique nucleotide barcodes for each file."""
    nucleotides = ['A', 'T', 'C', 'G']
    barcodes = []
    
    for combo in itertools.product(nucleotides, repeat=barcode_length):
        barcode = ''.join(combo)
        barcodes.append(barcode)
        if len(barcodes) >= num_files:
            break
    
    return barcodes[:num_files]

def process_single_file(args):
    """Process a single FASTQ file and return barcoded sequences."""
    file_path, barcode, chunk_size = args
    
    sequences = []
    
    # Handle both compressed and uncompressed files
    if str(file_path).endswith('.gz'):
        open_func = gzip.open
        mode = 'rt'
    else:
        open_func = open
        mode = 'r'
    
    try:
        with open_func(file_path, mode) as f:
            count = 0
            while count < chunk_size:
                header = f.readline().strip()
                if not header:
                    break
                
                sequence = f.readline().strip()
                quality_header = f.readline().strip()
                quality = f.readline().strip()
                
                # Prepend barcode to sequence
                barcoded_sequence = barcode + sequence
                barcoded_quality = 'I' * len(barcode) + quality
                
                sequences.append((header, barcoded_sequence, quality_header, barcoded_quality))
                count += 1
                
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return []
    
    return sequences

def write_sequences_to_file(sequences, output_file):
    """Write sequences to output file."""
    with gzip.open(output_file, 'at') as outf:
        for header, sequence, quality_header, quality in sequences:
            outf.write(f"{header}\n")
            outf.write(f"{sequence}\n")
            outf.write(f"{quality_header}\n")
            outf.write(f"{quality}\n")

def process_files_parallel(fastq_files, barcodes, output_file, num_cores, chunk_size=10000):
    """Process files in parallel with chunking for memory efficiency."""
    
    # Create output file
    with gzip.open(output_file, 'wt') as outf:
        pass  # Create empty file
    
    total_sequences = 0
    processed_files = 0
    
    print(f"Processing {len(fastq_files)} files using {num_cores} cores...")
    print(f"Chunk size: {chunk_size} sequences per chunk")
    
    # Process files in parallel
    with ProcessPoolExecutor(max_workers=num_cores) as executor:
        # Submit all file processing tasks
        future_to_file = {}
        for file_path, barcode in zip(fastq_files, barcodes):
            future = executor.submit(process_single_file, (file_path, barcode, chunk_size))
            future_to_file[future] = (file_path, barcode)
        
        # Process results as they complete
        for future in as_completed(future_to_file):
            file_path, barcode = future_to_file[future]
            try:
                sequences = future.result()
                if sequences:
                    write_sequences_to_file(sequences, output_file)
                    total_sequences += len(sequences)
                    processed_files += 1
                    print(f"✓ Processed {file_path.name} ({len(sequences)} sequences) - {processed_files}/{len(fastq_files)} files")
                else:
                    print(f"⚠ No sequences found in {file_path.name}")
            except Exception as e:
                print(f"✗ Error processing {file_path.name}: {e}")
    
    return total_sequences

def get_file_stats(input_dir):
    """Get statistics about files in the directory."""
    input_path = Path(input_dir)
    fastq_files = []
    
    for pattern in ['*.fastq', '*.fastq.gz', '*.fq', '*.fq.gz']:
        fastq_files.extend(input_path.glob(pattern))
    
    if not fastq_files:
        return [], 0, 0
    
    # Get file sizes
    total_size = sum(f.stat().st_size for f in fastq_files)
    avg_size = total_size / len(fastq_files)
    
    return fastq_files, total_size, avg_size

def estimate_processing_time(num_files, total_size_gb, num_cores):
    """Estimate processing time based on file size and cores."""
    # Rough estimates: 100MB/s per core for I/O + processing
    base_time_per_gb = 10  # seconds per GB
    time_per_gb = base_time_per_gb / num_cores
    
    estimated_time = total_size_gb * time_per_gb
    return estimated_time

def main():
    parser = argparse.ArgumentParser(description='Parallel FASTQ remultiplexing with nucleotide barcodes')
    parser.add_argument('input_dir', help='Directory containing input FASTQ files')
    parser.add_argument('output_file', help='Output remultiplexed FASTQ file (will be gzipped)')
    parser.add_argument('--barcode-length', type=int, default=8, 
                       help='Length of nucleotide barcodes (default: 8)')
    parser.add_argument('--cores', type=int, default=None,
                       help='Number of CPU cores to use (default: auto-detect)')
    parser.add_argument('--chunk-size', type=int, default=10000,
                       help='Number of sequences to process per chunk (default: 10000)')
    
    args = parser.parse_args()
    
    # Auto-detect CPU cores if not specified
    if args.cores is None:
        args.cores = min(mp.cpu_count(), 16)  # Cap at 16 to avoid overwhelming system
    
    # Ensure output file has .fastq.gz extension
    if not args.output_file.endswith('.fastq.gz'):
        args.output_file += '.fastq.gz'
    
    print("Parallel FASTQ Remultiplexing Tool")
    print("=" * 50)
    print(f"Input directory: {args.input_dir}")
    print(f"Output file: {args.output_file}")
    print(f"Barcode length: {args.barcode_length}")
    print(f"CPU cores: {args.cores}")
    print(f"Chunk size: {args.chunk_size}")
    print()
    
    # Get file statistics
    fastq_files, total_size, avg_size = get_file_stats(args.input_dir)
    
    if not fastq_files:
        print(f"No FASTQ files found in {args.input_dir}")
        return
    
    total_size_gb = total_size / (1024**3)
    print(f"Found {len(fastq_files)} FASTQ files")
    print(f"Total size: {total_size_gb:.2f} GB")
    print(f"Average file size: {avg_size / (1024**2):.1f} MB")
    
    # Estimate processing time
    estimated_time = estimate_processing_time(len(fastq_files), total_size_gb, args.cores)
    print(f"Estimated processing time: {estimated_time/60:.1f} minutes")
    print()
    
    # Generate barcodes
    barcodes = generate_barcodes(len(fastq_files), args.barcode_length)
    
    # Create barcode mapping
    barcode_mapping = {}
    for i, file_path in enumerate(fastq_files):
        barcode_mapping[file_path.name] = barcodes[i]
    
    # Write barcode mapping to file
    mapping_file = args.output_file.replace('.fastq.gz', '_barcode_mapping.txt')
    with open(mapping_file, 'w') as f:
        f.write("Original_File\tBarcode\n")
        for filename, barcode in barcode_mapping.items():
            f.write(f"{filename}\t{barcode}\n")
    
    print(f"Barcode mapping saved to: {mapping_file}")
    print("\nBarcode assignments (first 10):")
    for i, (filename, barcode) in enumerate(list(barcode_mapping.items())[:10]):
        print(f"  {filename}: {barcode}")
    if len(barcode_mapping) > 10:
        print(f"  ... and {len(barcode_mapping) - 10} more files")
    print()
    
    # Start processing
    start_time = time.time()
    
    try:
        total_sequences = process_files_parallel(fastq_files, barcodes, args.output_file, args.cores, args.chunk_size)
        
        end_time = time.time()
        processing_time = end_time - start_time
        
        print(f"\n" + "="*50)
        print(f"Remultiplexing complete!")
        print(f"Total sequences processed: {total_sequences:,}")
        print(f"Processing time: {processing_time/60:.1f} minutes")
        print(f"Sequences per second: {total_sequences/processing_time:.0f}")
        print(f"Output file: {args.output_file}")
        print(f"Barcode mapping: {mapping_file}")
        
    except KeyboardInterrupt:
        print("\nProcessing interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nError during processing: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

