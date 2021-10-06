# Prepare an .md file so pandoc can produce the ebook.
#
# It is the ebook counterpart of KenLatexTemplate.book.pandoc.
# NOT a generic script (like AssembleBook.py).  It is specific to the book, but quite adaptable.
#
# This should be run as part of a Makefile chain.
#
# NOTE:  Some of the oddities herein, the NeededDummyMetadata.md, and the KenEpubTemplate.pandoc are all becuase of 2 issues.  
#	(1) Pandoc autogen's a title page, which potentially can usurp epub title status even if left blank
#	(2) Pandoc insists on generating a TOC element for every 1st level header.  
#
# The 1st problem means that I have to put the title page image in the template file (where the title page is gen'ed).  However, this means slurping in the relevant image.  Pandoc doesn't scan the template file for images (like it does for markdown), so an image reference there will end up broken.  Therefore, we must include a ref to the image in the YAML.  We then refer to this variable (which now points to the internal file000n.png image in the epub that has been slurped in).  However, due to order of processing issues we have to use <img> rather than ![]() format in the YAML file.
#
# The 2nd problem means that the frontmatter (and backmatter, but those are titled anyway in my case) pages appear in the TOC.  If use empty headers (# followed by space), the TOC entries are blank.  Although pandoc has an .unlisted tag, it has not been implemented for epub.  If I use a title (# foo), foo appears in the TOC but also as a header --- which is no good for pages which shouldn't have a header, like the Thank You page or the image frontmatter (copyright page, etc).  To get around this, I use a silly method where the header is disposed of using the
#
# NOTE:  It is necessary to have Sigil generate a toc of its own before uploading to amazon.  Otherwise amazon complains!  This requires no book-specific editing, just a quick, simple, and generic manual step in Sigil.
#

import os
import subprocess
import argparse
import re
import sys
import ReadStatus as rs

def KErr(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

def KErrDie(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)
	sys.exit()

def ParseCommandLine():
	p= argparse.ArgumentParser(description='Generate Book markdown file from chapters')
	p.add_argument('--status',help='Status file to use for chapter info. Mandatory.',type=str,required=True)
	p.add_argument('--out',help='output markdown file in prep for epub. Mandatory.',type=str,required=True)
	p.add_argument('--srcdir',help='Source directory for chapter files. Mandatory.',type=str,required=True)
	p.add_argument('--book',help='Book name in status file to use. Mandatory.',type=str,required=True)
	p.add_argument('--booktype',help='novel or stories. Mandatory.',type=str,required=True)

	c= p.parse_args()
	return c

### Code for the "The End" flourish at end of last chapter
def AccumEndFlourish(l):
	l.append("<p><br/></p>\n")
	l.append("\n<p style=\"text-align: center; white-space: pre-line; text-indent:0\">\n")
	l.append("• • • The End • • •\n")
	l.append("</p>\n")
	l.append("<p><br/></p>\n")
	l.append("<p><br/></p>\n")

### Code for the section flourishes (sections within a chapter)
def AccumSecFlourish(l):
	l.append("\n<p style=\"text-align: center; white-space: pre-line; text-indent:0\">\n")
	l.append("• • • • • •\n")
	l.append("</p>\n")
	l.append("<p><br/></p>\n")

### Read a source file as a chapter or a section (as described in status.txt)
def AccumSrcFileNovel(cnum,sdir,r,l):
	if (not r.Exists(sdir)): KErrDie("Can't find source file "+r.Filename())
	ifil= sdir+"/"+r.Filename()
	ctype= -1
	n= 0
	if (r.IsChapter()):
		ctype= 0
		cnum= cnum+1
		l.append("\n\n# Chapter %d\n\n" % (cnum))
	elif (r.IsSection()):  AccumSecFlourish(l)
	elif (r.IsSilentSection()):  l.append("\n\n")	# No subsection/etc
	else: KErrDie("Src File %s has unknown type (not C or S) in status file" % (r.Filename()))
	with open(ifil,'r') as f:
		for i in f:
			if (re.match("[#\*]+\.?\ ",i)): KErr("Warning: File %s has md-like start to line %d" % (r.Filename(),n+1))
			l.append(i)
			n= n+1
	return (ctype,n)

def AccumSrcFileStory(sdir,r,l):
	if (not r.Exists(sdir)): KErrDie("Can't find source file "+r.Filename())
	ifil= sdir+"/"+r.Filename()
	n= 0
	fl= re.split(':',r.ValF("Format"))
	sstyle= ".flashstyle"
	if ("C" in fl): sstyle= ".chapstyle"
	elif ("P" in fl): sstyle= ".poemstyle"
	l.append("\n\n# %s {%s .unnumbered}\n\n" % (r.GetTitleInfer(),sstyle))
	with open(ifil,'r') as f:
		for i in f:
			l.append(i)
			n= n+1
	return n

### Read a source file as a chapter or a section
def AccumFile(ifil,tit,stype,noheader,l):
	if (not os.path.exists(ifil)): KErrDie("Can't find source file "+ifil)
	if (not noheader): l.append("\n\n# "+tit+" {epub:type="+stype+" .unnumbered}\n\n")
	l.append("::: {.flatpar}\n\n")
	with open(ifil,'r') as f:
		for i in f:
			l.append(i)
	l.append("\n\n")
	l.append(":::\n\n")

### 'Thank you for reading page', which is headerless
def AccumThankYou(ifil,tit,stype,l):
	if (not os.path.exists(ifil)): KErrDie("Can't find source file "+ifil)
	l.append("::: {.flatpar .hidetext}\n\n")
	l.append("\n\n# "+tit+" {epub:type="+stype+" .unnumbered}\n\n")
	with open(ifil,'r') as f:
		for i in f:
			l.append(i)
	l.append("\n\n")
	l.append(":::\n\n")

### Frontispiece and copyright pages, which are png images of pages from the print book
def AccumImg(f,t,n,l):
	l.append("::: {.hidetext}\n")
	l.append("\n\n# "+n+" {epub:type="+t+" .unnumbered .unlisted}\n")
	l.append("<center>\n")
#	l.append("![]("+f+"){data-custom-style=\"imgFull\" style=\"width:100.0%;height:100.0%\"}\n\n")
	l.append("<img data-custom-style=\"imgFull\" style=\"width:100.0%;height:100.0%\" alt=\""+t+"\" src=\""+f+"\"/>")
	l.append("</center>\n")
	l.append(":::\n")

### The "buy, buy, buy" adverts at the end.  Each incorporates a cover and a blurb.  They have headers.
def AccumAdvert(blurb,img,tit,l):
	l.append("\n\n# Other Works: "+tit+" {epub:type=appendix .unnumbered}\n")
	l.append("<center>\n")
	l.append("![Other Works: "+tit+"]("+img+"){height=30% width=100% custom-style=\"imgCenter\"}\n")	
	l.append("</center>\n\n")
	l.append("<p><br/></p>")
	AccumFile(blurb,"","",True,l)
	
def DumpMarkdown(l,ofil):
	with open(ofil,'wt') as f:
		f.write(''.join(l))

def main():
	c= ParseCommandLine()
	isnovel= (c.booktype=="novel")
	x= rs.Status(c.status,not isnovel)
	if (c.book not in x.books): bu.KErrDie("Book not present in status file")
	b= x.books[c.book]
	l= list()

	# Front Matter.  Note that we omitted the half-title and we put the title (page image) in the template.
	AccumImg("gen/eb_"+c.booktype+"_copyright.png","copyright-page","Copyright",l)		# Image of print book copyright page
	AccumImg("img/frontispiece.ebook.png","frontmatter","Frontispiece",l)	# Frontispiece image

	if (isnovel):
		cnum= 0
		numsec= 0
		ntot= 0
		for i in b:
			(ctype,n)= AccumSrcFileNovel(cnum,c.srcdir,i,l)
			if (ctype==0): cnum= cnum+1
			else: numsec= numsec+1
			ntot= ntot+n
		print("Read %d source file in %d chapters and %d sections.  %d lines total" % (len(b),cnum,numsec,ntot))
		if isnovel: AccumEndFlourish(l)
	else:
		ntot= 0
		for i in b: 
			ntot= ntot+ AccumSrcFileStory(c.srcdir,i,l)
		print("Read %d source files.  %d lines total" % (len(b),ntot))


	# Back Matter
	AccumThankYou("src/thankyou.html","Thank You","appendix",l)	# 'Thank you for reading' page
	AccumAdvert("gen/book1_blurb.md","img/book1.small.jpg","MyFirstBook",l)
	AccumAdvert("gen/book2_blurb.md","img/book2.small.jpg","MySecondBook",l)
	AccumFile("src/ack.md","Acknowledgments","appendix",False,l)	# Acknowledgements page
	AccumFile("src/about.md","About the Author","appendix",False,l)	# Bio page
	DumpMarkdown(l,c.out)

main()

