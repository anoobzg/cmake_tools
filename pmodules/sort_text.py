import sys
from pathlib import Path

def sort_text(source, dest):
    source_file = open(source, 'r', encoding='utf-8')
    params = source_file.readlines()
    for i in range(len(params)):
        params[i] = params[i].strip()

    params.sort()
    dest_file = open(dest, 'w', encoding='utf-8')
    for param in params:
        dest_file.write(param)
        dest_file.write('\n')
    dest_file.close()
    source_file.close()

if __name__ == "__main__":
    source = sys.argv[1]
    dest = source + '.s'
    sort_text(source, dest)
    