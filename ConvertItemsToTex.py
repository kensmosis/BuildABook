# Convert individual poem .md files to .tex
# ./gen must already exist

import sys
import re
import os.path
import os
import argparse
import ReadStatus as rs

deflinespread= 1.35

# Necessary because python is an unholy pile of crap
def KErr(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

# Necessary because python is an unholy pile of crap
def KErrDie(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)
	sys.exit()

def KDirExists(d): return os.path.isdir(d)

def KReplaceExt(f,extold,extnew):
	(root, ext)= os.path.splitext(f)
	if (ext!=extold): KErr("Error: extension for "+f+" is "+ext+" but expected "+extold)
	return root+extnew

def KExec(c): return os.popen(c).read().strip().split("\n")

def ParseCommandLine():
	p= argparse.ArgumentParser(description='Generate Book markdown file from chapters')
	p.add_argument('--status',help='Status file to use for story info. Mandatory.',type=str,required=True)
	p.add_argument('--srcdir',help='Source directory for pieces (markdown files). Mandatory.',type=str,required=True)
	p.add_argument('--tgtdir',help='Target directory for output latex files. Mandatory.',type=str,required=True)
	p.add_argument('--book',help='Book name in status file to use. Mandatory.',type=str,required=True)
	c= p.parse_args()
	return c

def main():
	c= ParseCommandLine()
	x= rs.Status(c.status,True)		# Allow a blank last field value
	if (c.book not in x.books): KErrDie("Book %s not found in %s" % (c.book,c.status))
	if (not KDirExists(c.tgtdir)): KErrDie("Target directory "+c.tgtdir+" not found")
	b= x.books[c.book]

	for i in b:
		ifil= c.srcdir+i.Filename()
		ofil= c.tgtdir+KReplaceExt(i.Filename(),".md",".tex")
		cmd= "pandoc --wrap=none --strip-comments --top-level-division=chapter -t latex -f markdown+smart-auto_identifiers -o \"%s\" \"%s\"" % (ofil,ifil)
		print("Executing: ",cmd)
		KExec(cmd)

main()
