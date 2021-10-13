import os, os.path, sys

SRC = os.getenv('SRC')
LANG = os.getenv('LANGUAGE')

def main():
    print("LANG = " + LANG)
    print("Requirements PATH = " +SRC + '/requirements.txt')
    if (LANG == "python" and os.path.isfile(SRC + '/requirements.txt')):
        print("Install requirements:")
        sys.stdout.flush()
        os.system("pip3 install -r {requirements_path}".format(requirements_path=SRC + '/requirements.txt'))


if __name__ == '__main__':
  main()
