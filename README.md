K.M. Halpern's sample book production framework.

# Introduction

If you find this hard to read as a markdown file, run `make readme` and look at `gen/README.pdf`.

If this document seems long and complicated, I'll repeat the immortal words of Douglas Adams: Don't Panic.  I combined two types of book builds in one, so things may seem bigger than they actually are.  In practice, you'd use a smaller makefile and a subset of the scripts specific to you book type.  I merged them to avoid replication of the example files --- which I felt would be more confusing.  

The scripts are ones I developed after doing this several times.  The code provided isn't the bare minimum to make stuff work.  It's the result of a long evolution of tries, and (for me at least) gets things right.  I'm not a scripter (most of my coding has been in C/C++), so these aren't perfect or elegant.  But I hope they are suitably well-documented to be of use for the purposes of learning and adaptation.

This is a full, working implementation of a command-line book production system as described in my blog post on www.kmhalpern.com.  It is based on the one I use for publishing my own books (adapted for illustrative purposes).  The images are random ones from the web (either PD or with suitable CC licenses), and the text was generated using an online "lorem ipsum" random generator.

As mentioned in the blog post, I highly recommend that you copy and adapt this code rather than try to generalize and centralize it to all your books in an effort to avoid code reuse.  I won't reiterate the reasons I provide there (see the post for details), but my experience has shown this to be the least time-consuming and most flexible approach.  In this sense, the sample code is the opposite of what you should do.  I consolidated two build systems for the purpose of illustration, but in practice you would be much better served to use the bare minimum needed for each project.

Note that this git repo includes the original image files.  I do not recommend including image files (or any large files) in your git repo in practice.  I only included them here so the sample build would be complete and self-contained.  In my actual system, I keep the originals in various locations outside the git repo, and any generated or copied files (such as in `img/`) are not managed by git.

Two types of book builds are included:  a novel and a collection of short works. From laziness, I reused the same cover and frontispiece images, as well as much of the same front and back matter. 

There is a key difference between novel and collection production.  For the novel, we assemble individual chapter markdown files into a single big markdown file, then run it through pandoc using a book-level template.  With a collection, we use a book level LaTeX file, which loads a list of input `.tex` files.  Each of these individually is generated by running the piece's markdown file through pandoc using an appropriate template.  This allows more flexibility, including the ability to format different pieces differently, put two poems on a page, etc.  I also provide machinery to generate individual standalone pdf's for the pieces in a collection.  This is useful for editing, submissions, etc.

# How to run

Note that the `:` at the end of each command is not part of the command, and is included for legibility only.

## Overall commands

`make clean`:		Clean book files, but (not) most image files

`make cleanall`:		Clean all imported and generated files, including images.

`make cleanebook`:	Clean just the non-image ebook files

`make readme`:		Produce a PDF version of this file

## Book production commands

Precede the make command with BOOKTYPE=$type, where $type is

`novel`			Produces the novel example

`stories`		Produces the collection example
	
Then you run one of the following:

`make book`:		Produce `out/$type.pdf`, the production print interior.

`make ebook`:	Produce `out/$type.epub`, the epub version (sans covers).

`make justebook`:	Same as `make ebook` but doesn't rebuild any images.  Good for quick testing of ebook tweaks.

`make draft`:	Produces `out/draft.pdf`, a draft version for editing.

`make lookinside`:		Produces `out/$type_999-8-7777777-66-1.zip`, the bundle for upload to amazon for the print book's look-inside feature.

`make ecovers`:	Produces front and back covers, sized to amazon

`make all`:		Everything for that book

## Special commands for individual pieces

For editing or submission purposes, it sometimes is useful to produce standalone versions of poems, flash-fiction, or stories.  The following command does so.  It only works with items in a collection.

`ITEM=$name [ANON=1] make item`:  Generate a standalone pdf of the piece (using the correct poem, flash-fiction, or story format).  It extracts the relevant info from the status file.  $name is the entry in the status.txt file.  It should exclude the prefix and suffix.  I.e., if `story_foo.md` is the file, but `foo` appears in `status.txt`, we would use `foo`.

The output is print-ready, sized at 8.5 x 11.  The format can be modified as required for submissions.

In this sample setup, the status file is `stories_status.txt`, but in general it would be `status.txt` for a collection.  It must have the `Format` field discussed below for collections.

An optional `ANON=1` can be used to produce output without the author name.  This is required by some contests. NOTE: this only affects the print output.  Indentifying info still may be included in the pdf metadata, though contests generally don't care about that.

`make cleanitems`:	Remove all item-related output (for all items, not any specific one).

## Examples

`make cleanall`

`BOOKTYPE=stories make ebook`

`BOOKTYPE=poems make draft`

`BOOKTYPE=novel make book`

`BOOKTYPE=poems make all`

`ANON=1 ITEM=green make item`

`ITEM=blue make item`

# Directories and Files

## General

`README.md`:		You're reading it.

`LICENSE.txt`:		License info for this, as well as where I got the sample images.

`.gitignore`:		I don't exclude images, but you should.

`Makefile`:			Controls the build process.  **You will need to adapt this.**

`status.txt`:		The table of chapters, stories, etc.  This tells us how to build the book(s). **This is very specific to your books.  You will need to adapt it.**

`src/`:				Contains all chapter, story, and poem source files, as well as some backmatter source files (biography, acknowledgments, etc). **You'll need to replace the entire contents with your own, of course!**

`originalloc1/`:		Proxy for the external source locations of the author's 1st book.  The blurb and cover-image files for that book are imported from there.  Normally this would NOT be part of the present git repo. **Just for examples.  You will discard this.**

`originalloc2/`:		Proxy for the external source locations of the author's 2nd book.  The blurb and cover-image files for that book are imported from there.  Normally this would NOT be part of the present git repo.  **Just for examples.  You will discard this.**

`originalloc3/`:		Proxy for the external source locations of the original cover art and frontispiece image for the current book.  Normally this would NOT be part of the present git repo.  **Just for examples.  You will discard this.**

`ReadStatus.py`:		Library of routines for parsing `status.txt` file.  **You won't need to change this.**

`Status.py`:			Script to give general info on word-counts.  **You won't need to change this.**

## Novel Print Book production

`AssembleBook.py`:		The script which assembled the chapters into a single .md file as the precursor to book and draft generation. **This generally won't require much adaptation.**

`KenLatexTemplate.book.pandoc`:	Controls the output print book format.  **You will need to adapt this quite heavily.**

`KenLatexTemplate.draft.pandoc`:	Controls the draft print format.  **This will need at least minor adaptation.  Other versions (for various manuscript or submission purposes) may be needed as well.**

## Collection Print Book production

`KenCollectionBook.tex`:	The master LaTeX file for the output print book of a compilation.  The main text is loaded from a generated file called `gen/inputlist.tex`. **This is the counterpart of `KenLatexTemplate.book.pandoc` for the novel, and requires lots of adaptation.**

`KenCollectionDraft.tex`:	The master LaTeX file for the draft print book of a compilation.  The main text is loaded from a generated file called `gen/inputlist.tex`. **This is the counterpart of `KenLatexTemplate.draft.pandoc` for the novel, and may require a little adaptation.**

`GenInputs.py`:		Produces a list of the input items for a compilation. **This generally won't require adaptation, but if extra flexibility is needed for the formatting of certain poems, it may.**

`ConvertItemsToTex.py`:	Converts the individual items from markdown to LaTeX.  Since this relies on reading `status.txt`, we run the `pandoc` command here, rather than in the `Makefile` itself (since needs knowledge of the correct list of files). **This should not require any modification.**

## Ebook production

`KenEpubStyles.css`:	Controls chapter title format and image layout in ebook. **You generally won't want to change this.**

`EbookBuild.py`:		The analog of `AssembleBook.py` for the epub version. However, in terms of specificity this is more akin to `KenLatexTemplate.book.pandoc` than `AssembleBook.py`.  **This needs heavy adaptation to your book, since it controls the layout of the ebook.**

`KenEpubTemplate.pandoc`:	Despite its name, this is very generic.  It basically replaces pandoc's auto-gen'ed title page with the title page image we extract from the print version.  **You won't need to change this.**

## Individual item production

`GetItemInfo.py`:	Utility script which extracts info about a piece from status.txt.  **This should not require any modification.**

`Makefile.indiv`:	Used as part of single-item production chain (for producing pdfs of individual pieces).  **This should not require any modification.**

`RunItemMake.py`:	Used as part of single-item production chain (for producing pdfs of individual pieces).  **This should not require any modification.**

`KenLatexTemplate.item.pandoc`:  The format specification for the individual pieces.  **This can be customized as needed.**

## Generated directories (not under version control)

`gen/`:			Most intermediate files, including some images.

`out/`:			Final output files.

`img/`:			Imported original image files, and most generated ones.

# Necessary externals

The system relies on a number of external programs.  All are free, well-maintained, and unlikely to vanish in the foreseeable future.  I've listed in `()` the version I happened to use at the time of writing.  The system shouldn't be highly sensitive to the specific version choices.

`python 3`  	(3.8.8)

`pandoc`	  	(2.1.3)

`pdflatex`	(3.14159265-2.6-1.40.20)	[part of texlive]

`pdfseparate`	(20.08.0)			[part of poppler utilities]

`convert`		(6.9.12-17)			[part of ImageMagick]

`zip`		(3.0)

`make`		(4.3)				[gnu make]

`git`		(2.29.3)			[not strictly necessary]

I also used `sigil` (1.5.1) for the minor TOC fix mentioned in the blog post (and output of some `make` commands).

# Note on images

Many of the image conversions in the sample Makefile are simple (either copies or just format changes).  In reality, you may need to tweak your images.  The `Makefile` is the place to put all transformations (crop, resize, brightness changes, etc).  The goal is to make the entire production pipeline reproducible from the original cover art.  This may take some manual tweaking at first.  I use `eog` to view images, imagemagick's `identify` command to view their info, and imagemagick's `convert` command to transform the images.  Do NOT simply use Gimp to get the result you want and save that file.  Add the CLI generation chain to the Makefile.  Trust me.  You'll thank me later.

# Writing chapters, stories, poems, and flash-fiction

There are plenty of guides to writing markdown, so I'll just mention the basic formatting I use, as well as some choices specific to my system.

## General writing rules

* All writing should be done in markdown (`.md`) files and placed in `src/`
* Hard linebreaks are ignored.  To produce a visual linebreak, use a blank line.  I.e., if you want some single-spaced lines as output, double-space them in the markdown.
* Do not use top level headers (`#`) in the chapters of a novel, since these are added automatically by the scripts.  In the pieces in a collection, they can be included but are ignored (essentially, they are comments).
* Use `*foo*` for italics and `**foo**` for bold face.  These cover 99% of my formatting needs.  Except for certain poetry, the vast majority of your .md files should be unformatted.
* You can use other markdown (lists, verbatim, etc), of course. Be sure that it looks as expected in the book, draft, and ebook outputs.
* Use `""` (ascii double-quotes) for double-quotes and `''` (ascii single-quotes) for single-quotes.  They automatically become smart.  Use backticks around something to keep it verbatim
* Vertical and horizontal white space is not controlled visually.  100 spaces is one space and 100 blank lines is 1 blank line.
* To add explicit horizontal white space (ex. indent lines in a precise pattern for poetry), use `&nbsp;` and add as many as needed.
* To add an explicit blank line, use the appropriate header-level symbol by book type below.
* Whether paragraphs are indented or not, and whether they have a blank line between them depends on the mode (novel or collection, and story/poem/flash-fiction in the latter).
* Heading levels 2+ (i.e. `##`, `###`, `####`, etc) have specific meanings based on whether a novel or collection.
* You can use html and url's (`<a href=...>` tags, etc), but check that they display as expected in the print and draft book versions.
* If using links, make sure they are pulled into the epub (so it can stand on its own).

## Novels

* For novels, paragraphs are indented (except the 1st in a chapter) and there is no blank line between paragraphs.
* `# title`:		Automatically added by AssembleBook.py.  Starts a new chapter with the title specified.
* `##`:			Manual.  Denotes a section break within a chapter.  Inserts an ornamental flourish (or `*****` in the ebook).  Use as needed.
* `### file`:	Automatically added by AssembleBook.py.   Inserts a filename line at any section break (even invisible ones).  This is ignored in the book output, but displayed in draft output to aid editing.
* `#### foo`:	Usually automatically added by AssembleBook.py, but can be manual too.  Specifies a subtitle for a chapter.  Ex. if each chapter has a date and location subtitle.  If being done for all chapters, it should be performed by AssembleBook.py using info provided in status.txt.  However, if one-off, it can be performed by manually adding such a line.  It should be preceded and followed by blank lines.  This also may be used to add a bold centered item.
* `##### foo`:	Manual. Inserts a bold-faced large centered item.  Ex. `The End`.

## Collections

* For collections, the indentation and line spacing style vary piece by piece, and depend on whether a given piece is listed as flash-fiction ('F'), a poem ('P'), or a story ('C') in the "Format" field of the status file.  If not specified, 'F' is the default.
* For poems, there is no indent, and no space between pars.
* For flash-fiction, there is no indent, but a blank line between pars.
* For stories, there is an indent, but no space bwteen pars.
* Note that linebreaks are ignored in ALL 3 modes.  Formatting a poem visually as you would like to see it is not good enough.  The lines must be double spaced, and stanza breaks must be made explicit via `###`, as described below. 
* A good way to think of poems is that a double-spaced line in markdown corresponds to a single-spaced line in the output, and a `###` corresponds to a stanza break.  The need for the latter arises because we're pretending each visual line actually is a par from the standpoint of markdown.
* `# foo`:		This is ignored.  It can be used to insert a comment or some info in the piece.  Ex. to include the actual title, so it is incorporated in the file rather than just status.txt.  Actual piece titles are inserted automatically by the scripts. We do this so that multiple pieces can be placed on the same page (which chapter-level headers don't easily allow).
* `##`:			Manual. Force a page-break if the styling requires it.
* `###`:			Manual. Force a stanza break (blank line).  Should mostly appear in poems.
* `#### foo`:		Manual. Add a bold centered line (with blank lines before and after).  Ex. a subsection header in a story or poem.
* `#####`:		Not used.  Can be employed for customization as needed.

# Adaptation to your own book

Figuring out what to adapt to your book may seem daunting.  If you're planning to use the scripts themselves (rather than just view them as proof of concept and copy pieces of their methodology), the following lists all the things you will need to adapt. 

## General

* `.gitignore`:
	- You probably will want to add png, jpg, and any other relevant image types to this so that you don't get bugged to add images to git (which you should NOT do).
	- You should start your own repo that is empty, then copy the relevant files from this sample project.  Adapt them, and then add them (sans any image files) to your git repo.
	
* `originalloc*/`:
	- Obviously, these don't apply to your project.  You will reference your own external locations, so these may be removed along with their contents.

* `Makefile`:
	- Remove the irrelevant parts (collection if producing a novel or novel if producing a collection). 
	- Adjust the title, author, and print-isbn info.
	- Adjust the advert book list (change names and add/remove as needed).
	- Set the correct locations for original source materials (advert blurbs and cover-images for the prior books, the cover art for the present book, and any interior art).
	- Once everything else is in place and working, check the correct PDF page numbers for the halftitle, copyright, title pages and set those.
	- Manually determine any image adjustments (crop, scaling, color-adjustments, etc) which need to be applied to the `front_cover.jpg`, `back_cover.jpg`.
	- Ditto for interior images, bw and small versions of cover art from prior books, etc.  I.e., make sure all images look good at the correct sizes (and in bw).

* `src/`:
	- Obviously, this should contain your own files.  Each should be written in markdown according to the specs described above.
	- In particular, make sure the `about.md` and `ack.md` entries are correct, and adjust `thankyou.html` to include your info and read as you wish.

* `ReadStatus.py`, `Status.py`:   Don't touch these.

* `KenEpubTemplate.pandoc`:   Don't touch this.

## Novel

* `status.txt`:
	- This is best adapted from our `novel_status.txt`.
	- Add your own custom fields if needed.  Note that they need to be fully populated (i.e. no blank fields).  Change `AssembleBook.py` and `EbookBuild.py` to properly interpret and use your custom fields.
	- If you are using a common prefix for all your chapters (ex. `Chapfoo.md`), adjust @PRE.
	- Adjust the @BOOK name.
	- Add entries for each file.  If the file starts a new chapter (which the 1st must), its type is 'C'.  If it starts a new visible section within a chapter, its type is 'S', and if it just appends (with no visible break) to the previous entry use 'I'.  This last allows splitting of files for organizational purposes, without any visual impact.

* `AssembleBook.py`:
	- If you want to change the chapter titles (ex. from `Chapter n` to the title in the `status.txt` file), edit the line which outputs `#`.
	- If you want chapter subtitles, add a `####`-production line which generates the correct subtitle from info in the status.txt file.
	- The relevant info can be accessed via commands in `ReadStatus.py`.
	
* `KenLatexTemplate.book.pandoc`:
	- Change the author, print/ebook isbn's, lccn, press, author, and artist.
	- Adjust title page layout if desired.
	- Adjust copyright page layout if desired.
	- Tailor the adverts to your work.
	- Rearrange and add/subtract front/back matter (ex. adverts, acks, etc) as desired. Make sure comes out correct recto (odd pages) vs verso (even pages), and make sure body of text starts on recto.
	- Add any frontispiece or other images.  Make sure the `Makefile` generates them if used.  Ditto for any advert images and blurbs.
	- Adjust the copyright-page disclaimer.  You don't want it as is.
	- Adjust the "The End" flourish to your taste.
	- Make any other formatting changes you desire (booksize, margins, header-footer layout, chapter-styling, etc).
	- Add/subtract blank pages at end to make pagecount a multiple of 4.  Ingram requires at least 2 blank pages at the end, though.
	
* `KenLatexTemplate.draft.pandoc`:
	- Change the author and title.
	- Adjust margins and line-spacing to your taste.

* `KenEpubStyles.css`:
	- If you are unhappy with the styling of the ebook you can change this, but you generally won't want to.

* `EbookBuild.py`:
	- Remove all the collection-related parts.
	- Adjust the section flourishes (the `##` entries) if you wish.
	- Adjust the "The End" flourish if you wish.
	- Adjust/customize the layout of frontmatter and backmatter as desired. These are in the main() routine at the bottom, and appear in the form of Accum* commands.

## Collection

* `status.txt`:
	- This is best adapted from `stories_status.txt`.
	- Add your own custom fields if needed.  Note that they need to be fully populated (i.e. no blank fields).  Change `GenInputs.py` and `EbookBuild.py` to properly interpret and use your custom fields.
	- The last field should be `Title`.  This is the only field which can be blank in the entries.  If not blank, it is used as the title of the piece (preserving whatever capitalization is used.  If blank, then the 1st field (name sans prefix or suffix) will be used, but with the 1st letter capitalized.
	- If you are using a common prefix for all your chapters (ex. `Chapfoo.md`), adjust @PRE
	- Adjust the @BOOK name.
	- Add entries for each file.  Type is 'C' for all.  Format is a :-delimited string.  Include 'P' for poem, 'F' for flash-fiction, 'C' for story ('F' is the default if none specified).  Include 'S' for standalone or 'D1' or 'D2' for the top/bottom half of a 2-entry page.  Note that a D1 entry always must be followed by a D2 entry.  Every line must have S, D1, or D2.  Use L:n.m to adjust the linespread just for that piece.  This is useful if you need to squeeze a piece onto a page slightly.  Small changes are not visibly noticeable.  Default linespread is 1.35.

* `KenCollectionBook.tex`:
	- Change the author, print/ebook isbn's, lccn, press, author, and artist.
	- Adjust title page layout if desired. In particular add a subtitle if desired.
	- Adjust copyright page layout if desired.
	- Tailor the adverts to your work.
	- Rearrange and add/subtract front/back matter (ex. adverts, acks, etc) as desired. Make sure comes out correct recto (odd pages) vs verso (even pages), and make sure body of text starts on recto.
	- Add any frontispiece or other images.  Make sure the Makefile generates them if used.  Ditto for any advert images and blurbs.
	- Adjust the copyright-page disclaimer.  You don't want it as is.
	- Tailor the "call to action page" to your taste (or eliminate it and the blank page following it).
	- Make any other formatting changes you desire (booksize, margins, header-footer layout, chapter-styling, etc).
	- Add/subtract blank pages at end to make pagecount a multiple of 4.  Ingram reequires at least 2 blank pages at the end, though.
	
* `KenCollectionDraft.tex`:
	- Change the author and title.
	- Adjust margins and line spacing to your taste.

* `KenEpubStyles.css`:
	- If you are unhappy with the styling of the ebook you can change this, but you generally won't want to.
	
* `EbookBuild.py`:
	- Remove all novel-specific parts.
	- Adjust/customize the layout of frontmatter and backmatter as desired. These are in the main() routine at the bottom, and appear in the form of Accum* commands.

* `GenInputs.py`:
	- If you added custom fields and wish to employ them, this most likely is where that would be done.
	
* `ConvertItemsToTex.py`:
	- It is unlikely you will want to change this.
	
## Individual item production

* `GetItemInfo.py`:  Don't touch this.

* `RunitemMake.py`:  Don't touch this. 

* `Makefile.indiv`:  Don't touch this.

* `KenLatexTemplate.item.pandoc`:
	- If you wish to customize the individual item format (for standalone pdfs of pieces), this is the place to do it.
	
