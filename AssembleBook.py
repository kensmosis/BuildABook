### Assemble the chapter files into a single markdown file for print-related books
### (i.e. everything except the ebook).   Warns of obvious problems
###
### It reads status.txt and generates a single unified .md file from all the individual section .md files in the source directory.
#
# Ex.  python3 ./AssembleBook.py --status ./status.txt --out ./gen/book.md --srcdir ./src --book MyNovel
#

import argparse
import re
import sys
sys.path.append(".")
import ReadStatus as rs

def KErr(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

def KErrDie(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)
	sys.exit()

def ParseCommandLine():
	p= argparse.ArgumentParser(description='Generate Book markdown file from chapters')
	p.add_argument('--status',help='Status file to use for story info. Mandatory.',type=str,required=True)
	p.add_argument('--out',help='Output markdown file. Mandatory.',type=str,required=True)
	p.add_argument('--srcdir',help='Source directory for chapter files. Mandatory.',type=str,required=True)
	p.add_argument('--book',help='Book name in status file to use. Mandatory.',type=str,required=True)

	c= p.parse_args()
	return c

def AccumSrcFile(cnum,sdir,r,l):
	if (not r.Exists(sdir)): KErrDie("Can't find source file "+r.Filename())
	ifil= sdir+"/"+r.Filename()
	ctype= -1
	n= 0
	tit= r.rf["Title"]
	if (r.IsChapter()):
		ctype= 0
		cnum= cnum+1
		l.append("\n\n# Chapter %d\n\n" % (cnum))	# Display "Chapter 4" type headers.
#		l.append("# %d. %s\n\n" % (cnum,tit))		# Use this instead if want "4. mychaptertitle" style headers (with mychaptertitle from the status.txt file).
		# Add a line with #### if desire subtitles of chapters (ex. day and location, or character, etc. 
	elif (r.IsSection()): l.append("\n##\n\n\n")
	elif (r.IsSilentSection()):  l.append("\n\n")	# No subsection/etc.  
	else: KErrDie("Src File %s has unknown type (not C or S) in status file" % (r.Filename()))
	l.append("\n### --------[%s]----------\n\n" % (r.Filename()))	# Display the file name.  In the relevant pandoc templates, we disable display of level-3 sections in all but draft-output modes --- so this doesn't affect non-draft output.
	with open(ifil,'r') as f:
		for i in f:
			if (re.match("[#\*]+\.?\ ",i)): KErr("Warning: File %s has md-like start to line %d" % (r.Filename(),n+1))
			l.append(i)
			n= n+1
	return (ctype,n)

def DumpMarkdown(l,ofil):
	with open(ofil,'wt') as f:
		f.write(''.join(l))

def main():
	c= ParseCommandLine()
	x= rs.Status(c.status)
	if (c.book not in x.books): bu.KErrDie("Book not present in status file")
	b= x.books[c.book]
	l= list()
	cnum= 0
	numsec= 0
	ntot= 0
	for i in b:
		(ctype,n)= AccumSrcFile(cnum,c.srcdir,i,l)
		if (ctype==0): cnum= cnum+1
		else: numsec= numsec+1
		ntot= ntot+n
	print("Read %d source file in %d chapters and %d sections.  %d lines total" % (len(b),cnum,numsec,ntot))
	DumpMarkdown(l,c.out)
	   
main()
