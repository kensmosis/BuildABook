###  A script which displays certain status info about the book (such as how much has been written, edited, etc).  Relies on the info in status.txt to determine and estimate these things.
#
#   Call as 'python3 ./Status.py'  from the directory in which status.txt resides

import sys
sys.path.append(".")
import ReadStatus as rs

sdir= "./src"			# Where the source .md files reside
sfil= "./status.txt"		# The status.txt file to use
book= "MyNovel"			# This is the name of the book in the status.txt file
x= rs.Status(sfil)
w= x.TotalWords(book,'',sdir)

print("Total Units:",len(x.books[book]))
print("%6s %8s %8s" % ("Status","Words","Pct"))
print("%6s %8d %8d" % ("Total",w,100))
for c in x.AllCharFields(book):
	n= x.TotalWords(book,c,sdir)
	print("%6s %8d %8d" % (c,n,n*100/w))
