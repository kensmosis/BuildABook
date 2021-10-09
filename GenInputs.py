import sys
import re
import os.path
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

def KReplaceExt(f,extold,extnew):
	(root, ext)= os.path.splitext(f)
	if (ext!=extold): KErr("Error: extension for "+f+" is "+ext+" but expected "+extold)
	return root+extnew

def ParseCommandLine():
	p= argparse.ArgumentParser(description='Generate Book markdown file from chapters (novel) or pieces (collection)')
	p.add_argument('--status',help='Status file to use for story info. Mandatory.',type=str,required=True)
	p.add_argument('--srcdir',help='Source directory for pieces (markdown files). Mandatory.',type=str,required=True)
	p.add_argument('--book',help='Book name in status file to use. Mandatory.',type=str,required=True)
	p.add_argument('--item',help='If specified, only outputs the specific entry. Optional',type=str,default="")
	p.add_argument('--itemfile',help='If this and --item are specified, the input file in the relevant output is this rather than item.tex.  Optional.',type=str,default="")
	c= p.parse_args()
	return c

class FRec:
	def __init__(s,i,srcdir):
		s.sd= -1	# Is S, D1, or D2
		s.l= deflinespread
		s.k= False	# Some sort of kskip but not sure whether used
		s.v= 0		# vskip
		s.p= "flash"	# is poem (default= flash fiction)
		s.t= i.GetTitleInfer()	# Title
		s.f= srcdir+KReplaceExt(i.Filename(),".md",".tex")	# Path to file
		s.e= ""		# Error code
		s.fstr= i.ValF("Format")
		f= re.split(':',i.ValF("Format"))
		for j in f:
			if (j=="S"): s.sd=0
			elif (j=="D1"): s.sd=1
			elif (j=="D2"): s.sd=2
			elif (j[0]=="L"):  s.l= float(j[1:])
			elif (j[0]=="V"):  s.v= int(j[1:])
			elif (j[0]=='K'):  s.k= True
			elif (j[0]=='P'):  s.p= "poem"
			elif (j[0]=='C'):  s.p= "story"
			elif (j[0]=='F'):  s.p= "flash"
			else: s.e+= "[Unknown format token %s]" % (j)
		
	def IsValid(s): return not (s.sd<0 or s.sd>2 or s.l<=0 or s.v<0 or s.t=="" or s.f=="" or s.e!="" or s.p not in ["poem", "flash", "story"])
	def GetInputLine(s,fl): return "{\\ken%s{%s}{%s}{%4.2f}{%dpt}}" % (s.p,s.t,(s.f if (fl=="") else fl),s.l,s.v)

def processitemfull(r,ca,p):
	f= re.split(':',r.ValF("Format"))
	c= FRec(r,ca.srcdir)
	if (c.e!=""): KErrDie(c.e)
	elif (not c.IsValid()): KErrDie("Invalid status format record: "+c.fstr+" in record "+c.f)
	pf= None if (not p) else FRec(p,ca.srcdir)
	if (c.sd==0):
		if (pf and pf.sd==1): KErrDie("S while previous D1 active")
		print("\\renewcommand{\\kfootarrow}{}")
		print("\\knewpage")
		print("\\thispagestyle{plain}")
		print(c.GetInputLine(""))
	elif (c.sd==1):
		if (pf and pf.sd==1): KErrDie("D1 while previous D1 active")
	elif (c.sd==2):
		if (not pf or pf.sd!=1): KErrDie("D2 while no previous D1 active")
		print("\\renewcommand{\kfootarrow}{}")
		print("\\knewpage")
		print("\\thispagestyle{plain}")
		print("\\begin{minipage}[c][.48\\textheight][t]{\\textwidth}")
		print(pf.GetInputLine(""))
		print("\\end{minipage}")
		print("\\par\\nointerlineskip\\noindent")
		print("\\begin{minipage}[c][.48\\textheight][t]{\\textwidth}")
		print(c.GetInputLine(""))
		print("\\end{minipage}")

def processitemindiv(r,ca):
	f= re.split(':',r.ValF("Format"))
	c= FRec(r,ca.srcdir)
	if (c.e!=""): KErrDie(c.e)
	elif (not c.IsValid()): KErrDie("Invalid status format record: "+c.fstr+" in record "+c.f)
	print(c.GetInputLine(ca.itemfile))

def main():
	ca= ParseCommandLine()
	x= rs.Status(ca.status,True)		# Allow a blank last field value
	if (ca.book not in x.books): KErrDie("Book %s not found in %s" % (ca.book,ca.status))
	b= x.books[ca.book]
	if (ca.item==""):
		p= None
		for i in b:
			processitemfull(i,ca,p)
			p= i
		if (p and FRec(p,ca.srcdir).sd==1): KErrDie("Dangling D2 at end")
	else:
		l= x.RecLoc(ca.book,ca.item)
		if (l<0): KErrDie("Item "+ca.item+" not found")
		r= b[l]
		processitemindiv(r,ca)

main()
