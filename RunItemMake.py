# Run's individual item makefile
# Requires a Format field in status file

import sys
import os
import re
import argparse
import ReadStatus as rs

# Necessary because python is an unholy pile of crap
def KErr(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

# Necessary because python is an unholy pile of crap
def KErrDie(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)
	sys.exit()

def KExec(c): return os.popen(c).read().strip().split("\n")

def KReplaceExt(f,extold,extnew):
	(root, ext)= os.path.splitext(f)
	if (ext!=extold): KErr("Error: extension for "+f+" is "+ext+" but expected "+extold)
	return root+extnew

def ParseCommandLine():
	p= argparse.ArgumentParser(description='Read a specific piece of info for a specific item in the status file.')
	p.add_argument('--status',help='Status file to use for story info. Mandatory.',type=str,required=True)
	p.add_argument('--author',help='Author. Mandatory.',type=str,required=True)
	p.add_argument('--book',help='Book name in status file to use. Mandatory.',type=str,required=True)
	p.add_argument('--item',help='Entry name in status file to use (1st field). Mandatory.',type=str,required=True)
	p.add_argument('--anon',help='Exclude author name.  Use this for certain contests. Optional.',action='store_true',default=False)
	c= p.parse_args()
	return c

def main():
	c= ParseCommandLine()
	x= rs.Status(c.status,True)		# Allow a blank last field value
	if (c.book not in x.books): KErrDie("Book "+c.book+" not found")
	b= x.books[c.book]
	l= x.RecLoc(c.book,c.item)
	if (l<0): KErrDie("Item "+c.item+" not found")
	r= b[l]
	if (not r.HasField("Format")): KErrDie("Status file has no Format field")
	title= r.GetTitleInfer()
	author= c.author
	prefix= "anon_" if (c.anon) else "self_"
	fmt= "flash"
	f= re.split(':',r.ValF("Format"))
	if ('P' in f): fmt= "poem"
	elif ('C' in f): fmt= "story"
	anon= " ANON=1 " if (c.anon) else ""
	tgt= "./out/"+prefix+KReplaceExt(r.Filename(),".md",".pdf")
	cmd= "TITLE=\"%s\" AUTHOR=\"%s\" ITEMTYPE=\"%s\" %s make -f Makefile.indiv %s" % (title, author, fmt, anon, tgt)
	print(cmd)

main()
