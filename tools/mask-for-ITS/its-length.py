#!/usr/bin/env /hps/nobackup2/production/metagenomics/pipeline/tools-v5/miniconda3-4.6.14/bin/python3
import glob
import argparse
import sys
import os
from Bio import SeqIO
import gzip
import shutil


def get_avg_length(input_folder):  # get average length of longest ITS sequences - separated by 'N'
    masked_its = os.path.join(input_folder, 'ITS_masked.fasta.gz')
    if os.path.exists(masked_its):
        all_lengths = []
        with gzip.open(masked_its, 'rt') as unzipped_file:
            for record in SeqIO.parse(unzipped_file, 'fasta'):
                sequences = [x for x in record.seq.split('N') if x and x != '']
                longest_seq = {'num': 0, 'letters': ''}
                for seq in sequences:
                    length = len(seq)
                    if length > longest_seq['num']:
                        longest_seq['num'] = length
                        longest_seq['letters'] = seq
                all_lengths.append(longest_seq['num'])
        return int(sum(all_lengths) / len(all_lengths))
    else:
        return 0


def hits_to_num_ratio(rna_type, fasta, input_folder):  # ratio of mapseq hits to number of total seqs LSU/SSU
    rna_sum, rna_num = [0 for _ in range(2)]
    rna = os.path.join(input_folder, '*.tsv')
    with open(glob.glob(rna)[0], 'r') as rna_hits:
        for line in rna_hits:
            if not line.startswith('#'):
                rna_sum += float(line.split('\t')[1])
    if os.path.exists(fasta):
        rna_num = len([1 for line in gzip.open(fasta, 'rt') if line.startswith('>')])
        return float(rna_sum / rna_num)
    else:
        return 0


def validate_hits(ssu_fasta, lsu_fasta, ssu_folder, lsu_folder, len_avg):  # check length and ratio and assign tag
    if len_avg > 200:
        return 'ITS'
    elif 120 <= len_avg <= 199:
        ssu_ratio = hits_to_num_ratio('SSU', ssu_fasta, ssu_folder)
        lsu_ratio = hits_to_num_ratio('LSU', lsu_fasta, lsu_folder)
        if ssu_ratio or lsu_ratio > 0.1:
            return 'rRNA'
        else:
            return 'ITS'
    else:
        return 'rRNA'


def suppress_dir(flag, lsu, ssu, its):  # rename dir by tag
    new_ssu_folder, new_lsu_folder, new_its_folder = \
        [x for x in ['suppressed_SSU', 'suppressed_LSU', 'suppressed_its']]
    if flag == 'ITS':
        os.rename(lsu, new_lsu_folder)
        os.rename(ssu, new_ssu_folder)
        os.rename(its, 'its')
        return [os.path.relpath(x) for x in [new_lsu_folder, new_ssu_folder, its]]
    elif flag == 'rRNA':
        os.rename(its, new_its_folder)
        os.rename(lsu, 'LSU')
        os.rename(ssu, 'SSU')
        return [os.path.relpath(x) for x in [lsu, ssu, new_its_folder]]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="get average length of ITS sequences and suppress unwanted folders")
    parser.add_argument("--seq-dir", dest="seq_directory", help="masked input file")
    parser.add_argument("--lsu-dir", dest="lsu_directory", help="directory in path taxonomy-summary/LSU")
    parser.add_argument("--ssu-dir", dest="ssu_directory", help="directory in path taxonomy-summary/SSU")
    parser.add_argument("--its-dir", dest="its_directory", help="directory in path taxonomy-summary/its")


    if len(sys.argv) < 1:
        parser.print_help()
    else:
        args = parser.parse_args()
        avg = get_avg_length(args.seq_directory)
        print('average ITS length is ' + str(avg))
        ssu_fasta = os.path.join(args.seq_directory, 'SSU.fasta.gz')
        lsu_fasta = os.path.join(args.seq_directory, 'LSU.fasta.gz')
        suppress_flag = validate_hits(ssu_fasta, lsu_fasta, args.ssu_directory, args.lsu_directory, avg)
        suppress_dir(suppress_flag, args.lsu_directory, args.ssu_directory, args.its_directory)

