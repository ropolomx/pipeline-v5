import argparse
import sys
import os
from Bio import SeqIO
import gzip


def get_avg_length(input_folder):
    masked_its = os.path.join(input_folder, 'ITS_masked.fasta.gz')
    if os.path.exists(masked_its):
        all_lengths = []
        with gzip.open(masked_its, "rt") as unzipped_file:
            for record in SeqIO.parse(unzipped_file, "fasta"):
                sequences = [x for x in record.seq.split('N') if x and x != '']
                longest_seq = {'num': 0, 'letters': ''}
                for seq in sequences:
                    length = len(seq)
                    if length > longest_seq['num']:
                        longest_seq['num'] = length
                        longest_seq['letters'] = seq
                all_lengths.append(longest_seq['num'])
        return sum(all_lengths)/len(all_lengths)
    else:
        return 0


def suppress_dir(its_length, taxonomy_dir):
    ssu_folder, lsu_folder, its_folder, new_ssu_folder, new_lsu_folder, new_its_folder = \
        [os.path.join(taxonomy_dir, x) for x in ['SSU', 'LSU', 'its', 'suppressed_SSU', 'suppressed_LSU', 'suppressed_its']]
    if its_length >= 200:
        os.rename(lsu_folder, new_lsu_folder)
        os.rename(ssu_folder, new_ssu_folder)
    else:
        os.rename(its_folder, new_its_folder)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="get average length of ITS sequences and suppress unwanted folders")
    parser.add_argument("--seq-dir", dest="seq_directory", help="masked input file")
    parser.add_argument("--tax-dir", dest="tax_directory", help="directory usually named taxonomy-summary")

    if len(sys.argv) < 1:
        parser.print_help()
    else:
        args = parser.parse_args()
        avg = get_avg_length(args.seq_directory)
        print('average ITS length is ' + str(avg))
        if avg > 0:
            suppress_dir(avg, args.tax_directory)
