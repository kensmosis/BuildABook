# Read the status file and return a specific piece of info for a specific item.
# Requires a Format field in the file.

import re
import argparse
import ReadStatus as rs

def ParseCommandLine():
	p= argparse.ArgumentParser(description='Read a specific piece of info for a specific item in the status file.')
	p.add_argument('--status',help='Status file to use for story info. Mandatory.',type=str,required=True)
	p.add_argument('--book',help='Book name in status file to use. Mandatory.',type=str,required=True)
	p.add_argument('--item',help='Entry name in status file to use (1st field). Mandatory.',type=str,required=True)
	p.add_argument('--info',help='What info to get: title or type of file.  title is the name or inferred title.  type returns poem, flash, or story.  file returns prefix+name.suffix. On failure, returns blank.  Mandatory.',type=str,required=True)
	c= p.parse_args()
	return c

def main():
	c= ParseCommandLine()
	x= rs.Status(c.status,True)		# Allow a blank last field value
	if (c.book not in x.books): return
	b= x.books[c.book]
	l= x.RecLoc(c.book,c.item)
	if (l<0): return
	r= b[l]
	if (c.info=="title"): print(r.GetTitleInfer())
	elif (c.info=="file"): print(r.Filename())
	elif (c.info!="type"): return			# Unknown info requested
	elif (not r.HasField("Format")): return		# Wrong type of status file
	else:
		f= re.split(':',r.ValF("Format"))
		if ('P' in f): print("poem")
		elif ('C' in f): print("story")
		else: print("flash")

main()
