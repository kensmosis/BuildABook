import os.path
import re

## Classes for generic reading of status.txt files for novels or collections.
## Status:  Class containing all info parsed from status.txt file.
## SRec:   Entry for individual unit of a particular book (ex. poem or chapter).
##
## See README.md for details of the status.txt file format and constraints.

# A chapter/story record.  f is a list of headers for fields.
class SRec:
	def __init__(s,book,pre,suff,head,f):
		s.book= book
		s.pre= pre
		s.suff= suff
		s.name= f[0]
		s.f= f[1:]
		s.rf= { head[i-1]:f[i] for i in range(1,len(f)) }

	def NumRecs(s): return len(s.f)
	def HasField(s,f):  return (f in s.rf)
	def ValF(s,f): return "" if (f not in s.rf) else s.rf[f]
	def ValN(s,n): return "" if (n<0 or n>=len(s.f)) else s.f[n]
	def IsChapter(s): return (s.ValF("Type")=="C")
	def IsSection(s): return (s.ValF("Type")=="S")
	def IsSilentSection(s): return (s.ValF("Type")=="I")	# Treat as if continuation of previous with no section or chapter header!!!
	def Filename(s): return s.pre+s.name+"."+s.suff		# Actual full filename
	def FileNameAbbrev(s): return s.name			# Abbreviation (no prefix or suffix)
	def FileNameBase(s): return s.pre_s.name		# Filename sans extension
	def Exists(s,srcdir): return os.path.exists(srcdir+"/"+s.Filename())
	def TidyLine(l): return re.sub("#.*","",re.sub("[^a-zA-Z0-9']+"," ",l)).strip()	  # Remove comment strings, anything inappropriate from start of line and any leading/trailing white space. 
	def Words(s,srcdir):  
		if (not s.Exists(srcdir)): return 0
		with open(srcdir+"/"+s.Filename(),'r') as f:  
			return sum([len(SRec.TidyLine(l).split()) for l in f])
	def IsCharField(s,c): return (s.HasField("Status") and c in s.ValF("Status"))
	def IsWritten(s): return IsCharField("W")
	def IsRound1(s): return IsCharField("1")
	def GetCharField(s): return s.ValF("Status") if s.HasField("Status") else ""
	def GetTitle(s): return s.ValF("Title") if s.HasField("Title") else ""
	def GetTitleInfer(s): return s.GetTitle() if (s.GetTitle()!="") else s.name.capitalize()	# Chapter title if provided, otherwise we take the listed name string but with the first char capitalized.  Useful if we make the last field (so can be blank) the title, and only provide it when it differs from the file's name.  Must use the allowblanklastfield=true in Status below in order for this to work.

def fileerr(err,n,fname): print("ERROR: %s.  Line %d in file %s" % (err,n,fname))

# The full table of chapters
class Status:
	def __init__(s,fname,allowblanklastfield=False):
		pre= ""				# Transient
		suff= "txt"			# Transient
		book= ""			# Transient
		s.fname= fname			# Status file it is read from
		s.recs= set()			# Set of all record
		s.head= list()			# List of header fields (must be common to all books)
		s.rhead= dict()			# Header field -> field number
		s.books= dict()			# Map from book to ordered list of records in the book
		s.booklist= list()		# Ordered list of books
		s.allrec= list()		# Ordered list of all entries (from all book)
		with open(fname,'r') as f:
			for s.n, l in enumerate(f):
				l= re.sub("#.*","",l)
				l= l.strip()
				if (len(l)==0): continue
				t= [x.strip() for x in re.split("\t+",l)]
				if (t[0]=="@PRE"): pre= t[1] if (len(t)>1) else ""
				elif (t[0]== "@SUFF"): suff= t[1] if (len(t)>1) else ""
				elif (t[0]== "@HEAD"):
					if len(s.head)!=0: fileerr("@HEADER appears twice",s.n,fname)
					s.head= t[1:]
					s.rhead= { s.head[i]:i for i in range(0,len(s.head)) }
				elif (t[0]== "@BOOK"):
					if len(s.head)==0: fileerr("@BOOK before @HEADER",s.n,fname)
					book= t[1]
					if (book in s.books): fileerr("Book declared twice",s.n,fname)
					s.books[book]= list()
					s.booklist.append(book)
				else:
					if (book==""): fileerr("Entry before book declared",s.n,fname)
					if (len(t)==len(s.head) and allowblanklastfield): t.append("")	# If last field is blank and we are allowing, tack on an empty string so the next test doesn't fail
					if (len(t)!=len(s.head)+1): fileerr("Entry has wrong number of fields. %d found %d expected: %s" % (len(t),len(s.head)+1,l),s.n,fname)
					r= SRec(book,pre,suff,s.head,t)
					if (len(s.recs)==0 and not r.IsChapter()): fileerr("First entry in book is not a chapter (i.e. Type C).  Are you sure this is what you want?",n,fname) 
					s.recs.add(r)
					s.books[book].append(r)
					s.allrec.append(r)

	def NumBooks(s): return len(s.books)
	def NumRecs(s): return len(s.allrec)

	# Does unit name sec (sans pre or suff) exist in book?  case-sensitive
	def HasRec(s,book,sec):
		if (book not in s.books): return False
		for i in s.books[book]:
			if (i.name == sec): return True
		return False

	# Location of unit in the book.  0= 1st, -1= error or not present or duplicated section name
	def RecLoc(s,book,sec):
		if (book not in s.books): return -1
		l= -1
		for i in range(0,len(s.books[book])):
			if (s.books[book][i].name == sec):
				if (l>=0): return -1		# Duplicate
				l= i
		return l

	# How many units apart are the two secs.  Returns absolute value.  1 if adjacent, 0 if same unit.  -1 if error
	def RecDist(s,book,u1,u2):
		l1= s.RecLoc(book,u1)
		l2= s.RecLoc(book,u2)
		if (l1<0 or l2<0): return -1
		return abs(l1-l2)
		
	# Return the set of values which a field takes
	def Vals(s,f):	return { x.ValF(f) for x in s.allrec if (x.ValF(f)!="") }

	# Check that all files listed in the status file exist in specified source directory
	def Verify(s,srcdir):
		for i in s.allrec:
			if (not i.Exists(srcdir)):
				print("ERROR: %s does not exist" % (srcdir+"/"+i.Filename()))

	# Count all words in all files.  If c!='', then only counts those with c appearing in the Status field.
	def TotalWords(s,book,c,srcdir):
		return sum([r.Words(srcdir) for r in s.books[book] if (c=='' or r.IsCharField(c))])

	# Return list of all character fields found (in order)
	def AllCharFields(s,book):
		x= set()
		l= list()
		for r in s.books[book]:
			for c in r.GetCharField():
				if c not in x: l.append(c)
				x.add(c)
		return l
