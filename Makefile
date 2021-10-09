### Book info that differs for novel and collection (Note: make sure there are no spaces after FPREFIX values)
ifeq ($(BOOKTYPE),stories)
TITLE := My Stories
BOOK := MyStories
FPREFIX := story_
else ifeq ($(BOOKTYPE),novel)
TITLE := My Novel
BOOK := MyNovel
FPREFIX := chap_
else
TITLE := ERROR
BOOK := ERROR
FPREFIX := ERROR_
endif

### Other Book Info (Note: make sure there are no spaces after the ISBN value)
AUTHOR := Steinbeck Hemingway Faulkner III
PRINTISBN := 999-8-7777777-66-1

### Our directories
BASEDIR := ./
SRCDIR := ./src/
IMGDIR := ./img/
GENDIR := ./gen/
OUTDIR := ./out/

### Relevant status file for the book
STATUS := $(BASEDIR)$(BOOKTYPE)_status.txt

### Ad blurb and image lists for backmatter.  Only OBOOKS should be changed (a list of names we'll use for reference).
OBOOKS := book1 book2
BLURBLISTTEX = $(patsubst %, $(GENDIR)%_blurb.tex, $(OBOOKS))
BLURBLISTMD = $(patsubst %, $(GENDIR)%_blurb.md, $(OBOOKS))
IMGLIST = $(patsubst %, $(IMGDIR)%.small.jpg, $(OBOOKS))
BWIMGLIST = $(patsubst %, $(IMGDIR)%.bw.jpg, $(OBOOKS))

### Ad image original source locations.  For each past book being advertised, the cover image.  foo_img where foo is from the OBOOKS list above).
book1.src_img := $(BASEDIR)originalloc1/Pterois_volitans_Manado-e_edit.jpg
book2.src_img := $(BASEDIR)originalloc2/P-51_Mustang_edit1.jpg

### Ad blurb original source locations.  For each past book being advertised, the blurb (as an .md file).  foo_blurb_src where foo is from the OBOOKS list above.
book1_blurb_src := $(BASEDIR)originalloc1/blurb1.md
book2_blurb_src := $(BASEDIR)originalloc2/blurb2.md

### Frontispiece, front, and rear cover original image locations.  Add/remove/edit as needed.   
frontis_img := $(BASEDIR)originalloc3/24512-4-gazelle-transparent-image.png
front_img := $(BASEDIR)originalloc3/Tempietto_del_Bramante_Vorderseite.jpg
back_img := $(BASEDIR)originalloc3/Soyuz_TMA-9_launch.jpg

### List of backmatter we will need to convert to tex
BMATTS := about ack
BMATTLISTMD := $(patsubst %, $(SRCDIR)%.md, $(BMATTS))
BMATTLISTTEX := $(patsubst %, $(GENDIR)%.tex, $(BMATTS))

### Page numbers in ebstuff to use for relevant pages.  This is the equal-margin version of the print book used to extract certain page images for use as frontmatter in the ebook.  Once gen/ebstuff.pdf has been created, extract the page numbers for the halftitle, title, and copyright pages (make sure to use the actual pdf page number, not the book's page number).  Add/remove/edit as needed. 
EBPAGES := copyright halftitle title
EBPAGELIST = $(patsubst %, $(GENDIR)eb_$(BOOKTYPE)_%.png, $(EBPAGES))
eb_novel_halftitle_page := 3
eb_novel_title_page := 5
eb_novel_copyright_page := 6
eb_stories_halftitle_page := 1
eb_stories_title_page := 3
eb_stories_copyright_page := 4

### Conversion flags for novel (PANFLAGS), collection (ADPANFLAGS), all ebooks (EPANFLAGS), INDPANFLAGS (individual backmatter bits)
PANFLAGS := -M title="$(TITLE)" -M author="$(AUTHOR)" --wrap=none --standalone --verbose --fail-if-warnings --strip-comments -M lang="en-GB" --top-level-division=chapter -t latex -f markdown+smart
EPANFLAGS := -M title="$(TITLE)" -M author="$(AUTHOR)" --wrap=none --standalone --verbose --fail-if-warnings --strip-comments -M lang="en-GB" --top-level-division=chapter --toc-depth=1 -t epub2 -f markdown+smart+header_attributes --metadata-file=$(GENDIR)NeededDummyMetadata.md
ADPANFLAGS := --wrap=none --strip-comments --top-level-division=chapter -t latex -f markdown+smart-auto_identifiers
INDPANFLAGS := --wrap=none --verbose --fail-if-warnings --strip-comments -M lang="en-GB" --top-level-division=chapter -t latex -f markdown+smart-auto_identifiers

### Disable intrinsic rules (since we're not coding, they're useless!)
.SUFFIXES:
	$(NOECHO) $(NOOP)

### Preserve intermediate targets (for debugging, etc)
.PRECIOUS: $(GENDIR)% $(OUTDIR)% $(IMGDIR)%
	$(NOECHO) $(NOOP)

.SECONDARY: $(GENDIR)% $(OUTDIR)% $(IMGDIR)%
	$(NOECHO) $(NOOP)

### Declare the non-generative targets
.PHONY: all draft book ebook lookinside clean cleanimages cleanall frontispiece ecovers cleanitems

### The list of relevant source files. Note: this ONLY works if we can determine the source files by location (ex. source iff in src/) or by prefix (ex. source iff chap_$foo.md).  It is advisable to do this.  This only is used to determine when a rebuild is necessary (i.e. for dependency purposes), so better to include too many files rather than too few.
SRCFILES := $(shell find ./src/ -type f -name '$(FPREFIX)*.md')

### Virtual target to build all novel-related or all collection-related, as the case may be
all: draft book ebook lookinside ecovers

### Common print targets
draft: $(OUTDIR)$(BOOKTYPE)_draft.pdf

book:  $(OUTDIR)$(BOOKTYPE)_book.pdf

$(OUTDIR)%.pdf: $(GENDIR)%.tex $(BWIMGLIST) $(BLURBLISTTEX) $(IMGDIR)frontispiece.book.png | $(OUTDIR)
	-rm -f $@
	-rm -f $(GENDIR)$*.aux
	-rm -f $(GENDIR)$*.log
	-rm -f $(GENDIR)$*.out
	-rm -f $(GENDIR)$*.toc
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) pdflatex -output-directory $(GENDIR) $<
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) pdflatex -output-directory $(GENDIR) $<   # Note: we need the 2nd call to pdflatex to generate the TOC
	mv $(GENDIR)$*.pdf $@

### Novel-specific print targets
$(GENDIR)novel_book.md: $(SRCFILES) $(STATUS) $(BASEDIR)AssembleBook.py | $(GENDIR) 
	-rm -f $@
	python3 $(BASEDIR)AssembleBook.py --status $(STATUS) --book $(BOOK) --srcdir $(SRCDIR) --out $@

$(GENDIR)novel_draft.tex: $(GENDIR)novel_book.md $(BMATTLISTTEX) $(BASEDIR)KenLatexTemplate.draft.pandoc
	-rm -f $@
	pandoc $< -o $@ $(PANFLAGS) --template $(BASEDIR)KenLatexTemplate.draft.pandoc

$(GENDIR)novel_book.tex: $(GENDIR)novel_book.md $(BMATTLISTTEX) $(BASEDIR)KenLatexTemplate.book.pandoc
	-rm -f $@
	pandoc $< -o $@ $(PANFLAGS) --template $(BASEDIR)KenLatexTemplate.book.pandoc

## Collection print-book targets
$(GENDIR)inputlist.tex: $(STATUS) $(BASEDIR)GenInputs.py $(BASEDIR)ConvertItemsToTex.py $(SRCFILES) | $(GENDIR)
	-rm -f $@
	python3 $(BASEDIR)GenInputs.py --status $(STATUS) --book $(BOOK) --srcdir $(GENDIR) > $(GENDIR)inputlist.tex
	python3 $(BASEDIR)ConvertItemsToTex.py --status $(STATUS) --book $(BOOK) --srcdir $(SRCDIR) --tgtdir $(GENDIR)


## Copy template files for collections so they have the right name, as will be needed for certain generic recipes.  [We need myvar1 to get the correct $title$ string in sed]
myvar1 = \$$title\$$

$(GENDIR)stories_book.tex: $(BASEDIR)KenCollectionBook.tex $(GENDIR)inputlist.tex $(BMATTLISTTEX) 
	cat $< | sed -r 's/$(myvar1)/$(TITLE)/g' > $@

$(GENDIR)stories_draft.tex: $(BASEDIR)KenCollectionDraft.tex $(GENDIR)inputlist.tex $(BMATTLISTTEX) 
	cat $< | sed -r 's/$(myvar1)/$(TITLE)/g' > $@

### Special print version with equal margins for page-image extraction for ebook.  The kebonly flag tells the .tex file to use even margins, etc.
$(GENDIR)$(BOOKTYPE)_ebstuff.pdf: $(GENDIR)$(BOOKTYPE)_book.tex $(BWIMGLIST) $(BLURBLISTTEX) $(IMGDIR)frontispiece.book.png
	-rm -f $@
	-rm -f $(GENDIR)$(BOOKTYPE)_ebstuff.*
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) kebonly="true" pdflatex -output-directory $(GENDIR) -jobname $(BOOKTYPE)_ebstuff $(GENDIR)$(BOOKTYPE)_book.tex

$(GENDIR)eb_$(BOOKTYPE)_%.pdf: $(GENDIR)$(BOOKTYPE)_ebstuff.pdf
	-rm -f $@
	pdfseparate -f $($(basename $(@F))_page) -l $($(basename $(@F))_page) $< $@

$(GENDIR)eb_$(BOOKTYPE)_%.png: $(GENDIR)eb_$(BOOKTYPE)_%.pdf
	-rm -f $@
	convert -verbose -density 1200 $< -quality 100 -flatten -resize 25% +repage $@

### Ebook

ebook: $(OUTDIR)$(BOOKTYPE)_book.epub
	@echo "WARNING:  When done, load the ebook into Sigil, and have Sigil generate the TOC (level 1 headers only!) and then save as a new file.  Otherwise Amazon will complain about links in the TOC."

$(GENDIR)NeededDummyMetadata.md: | $(GENDIR)
	@echo "ktitleimage: '<img src=\"gen/eb_$(BOOKTYPE)_title.png\" data-custom-style=\"imgFull\" style=\"width:100.0%;height:100.0%\" alt=\"title page\"/>'" > $@

$(GENDIR)$(BOOKTYPE)_ebook.md: $(SRCFILES) $(BLURBLISTMD) $(BASEDIR)EbookBuild.py $(STATUS) $(GENDIR)NeededDummyMetadata.md
	-rm -f $@
	python3 $(BASEDIR)EbookBuild.py --status $(STATUS) --book $(BOOK) --booktype $(BOOKTYPE) --srcdir $(SRCDIR) --out $@

$(OUTDIR)$(BOOKTYPE)_book.epub: $(GENDIR)$(BOOKTYPE)_ebook.md $(IMGLIST) $(EBPAGELIST) $(IMGDIR)frontispiece.ebook.png $(BASEDIR)KenEpubTemplate.pandoc $(BASEDIR)KenEpubStyles.css | $(OUTDIR) 
	-rm -f $@
	pandoc $< -o $@ $(EPANFLAGS) --template $(BASEDIR)KenEpubTemplate.pandoc --css $(BASEDIR)KenEpubStyles.css

### Directory build targets

%/:
	-mkdir -p $@

### Cleanup

cleanall: clean cleanimages

clean:
	-rm -rf $(OUTDIR)
	-rm -rf $(GENDIR)

cleanimages:
	-rm -rf $(IMGDIR)

### Some simple backmatter conversions
$(GENDIR)ack.tex: $(SRCDIR)ack.md | $(GENDIR)
	pandoc $(INDPANFLAGS) $< -o $@

$(GENDIR)about.tex: $(SRCDIR)about.md | $(GENDIR)
	pandoc $(INDPANFLAGS) $< -o $@

$(GENDIR)%_blurb.tex: $(GENDIR)%_blurb.md
	pandoc $(INDPANFLAGS) $< -o $@

### Needed for use of generic variables, but we must be careful with names from here on, and avoid anything which accidentally could be reexpanded.  This has to go before the first recipe which requires double-expansion.  Usually, this is the first one with $$ in it.
.SECONDEXPANSION:

### Construct ad images for book and ebook from copies of their original sources.  In the following, there's much apparent duplication, which in principle could be consolidated.  However, in practice, the duplication is needed because each image would have its own conversion formula (i.e. specific crop, resize, etc).  So we leave them in, even though those lines look the same here.
book1.small_flags := -resize 300x
book2.small_flags := -resize x480
book1.bw_flags := -resize 800x
book2.bw_flags := -resize 800x

$(IMGDIR)book%.src.jpg: $$($$(basename $$(@F))_img) | $(IMGDIR)
	cp $< $@

$(IMGDIR)book1.bw.jpg: $(IMGDIR)book1.src.jpg
	convert $< -quality 90 $(book1.bw_flags) -set colorspace Gray -separate -average $@

$(IMGDIR)book2.bw.jpg: $(IMGDIR)book2.src.jpg
	convert $< -quality 90 $(book2.bw_flags) -set colorspace Gray -separate -average $@

$(IMGDIR)book1.small.jpg: $(IMGDIR)book1.src.jpg
	convert $< $(book1.small_flags) +repage -quality 90 $@

$(IMGDIR)book2.small.jpg: $(IMGDIR)book2.src.jpg
	convert $< $(book2.small_flags) +repage -quality 90 $@

### Copy ad blurbs from source files
$(GENDIR)%_blurb.md: $$($$(basename $$(@F))_src) | $(GENDIR) 
	cp $< $@

### Generate frontispiece. 
frontispiece: $(IMGDIR)frontispiece.book.png $(IMGDIR)frontispiece.ebook.png

$(IMGDIR)frontispiece.png: $(frontis_img) | $(IMGDIR)
	cp $< $@

$(IMGDIR)frontispiece.book.png: $(IMGDIR)frontispiece.png
	convert $< -colorspace gray $@

$(IMGDIR)frontispiece.ebook.png: $(IMGDIR)frontispiece.png
	convert $< -colorspace gray $@

### Generate front and back covers for ebook.  Amazon likes 2560x1600 as its image size. 
ecovers: $(OUTDIR)front_cover.jpg $(OUTDIR)back_cover.jpg

$(OUTDIR)%_cover.jpg: $(IMGDIR)%_cover.jpg | $(OUTDIR)
	cp $< $@

$(IMGDIR)front_cover_original.jpg:  $(front_img) | $(IMGDIR)
	cp $< $@

$(IMGDIR)back_cover_original.jpg:  $(back_img) | $(IMGDIR)
	cp $< $@

$(IMGDIR)front_cover.jpg: $(IMGDIR)front_cover_original.jpg
	convert $< -resize x2560 -crop 1600x2560+200+0 +repage -quality 90 $@

$(IMGDIR)back_cover.jpg: $(IMGDIR)back_cover_original.jpg
	convert $< -resize x2560 -crop 1600x2560+50+0 +repage -quality 90 $@


### Generate look-inside bundle for upload to amazon.  This is for the print version; the KDP version is generated by them automaticall (or not, as the case may be, since they aren't very good at it).  Basically, once the Ingram print edition is out, available to Amazon as part of the Ingram catalog, and Amazon correctly links it to your KDP version, you can set up a special seller profile (they have instructions to do so), and then upload a zip file.  The name of the zip file is important.  Although we name it with a novel_ or stories_ prefix, Amazon requires $(PRINTISBN).zip as the name.  It must contain a front cover image, back cover image, and pdf of the interior of the book, all names precisely as specified here.
ISBNFILE := $(OUTDIR)$(BOOKTYPE)_$(PRINTISBN).zip

lookinside: $(ISBNFILE)

$(GENDIR)interior.pdf: $(OUTDIR)$(BOOKTYPE)_book.pdf | $(GENDIR)
	cp $< $@

$(ISBNFILE): $(GENDIR)interior.pdf $(IMGDIR)front_cover.jpg $(IMGDIR)back_cover.jpg | $(OUTDIR)
	echo $(ISBNFILE)
	zip -j $@ $(GENDIR)interior.pdf $(IMGDIR)front_cover.jpg $(IMGDIR)back_cover.jpg

### NOTE: the ingram cover is something usually done by the cover artist using a template downloaded from Ingram (for the relevant book size, # pages, etc).  It is not something we attempt to automate.

### Generate a README pdf
readme: $(GENDIR)README.pdf

$(GENDIR)README.pdf: $(GENDIR)README.tex
	pdflatex --output-directory $(GENDIR) $(GENDIR)README.tex

$(GENDIR)README.tex: $(BASEDIR)README.md | $(GENDIR)
	pandoc --standalone -o $@ $<

### Create pdf of an individual item in a collection (for submission or editing purposes).  NOTE: make sure no spaces after ITEMPREFIX defs below.  NOTE: we cannot detect changes to the specific source file, so must make sure to rebuild after each one!
### ITEM=$entryname [ANON=1] make item
ifeq ($(ANON),1)
ITEMPREFIX := anon_
ITEMANON := --anon
else
ITEMPREFIX := self_
ITEMANON := 
endif

cleanitems:
	-rm -f $(OUTDIR)self_*.pdf
	-rm -f $(OUTDIR)anon_*.pdf
	-rm -f $(GENDIR)self_*
	-rm -f $(GENDIR)anon_*

item: $(BASEDIR)RunItemMake.py $(BASEDIR)Makefile.indiv $(BASEDIR)KenLatexTemplate.item.pandoc | $(OUTDIR)
	python3 $(BASEDIR)RunItemMake.py --status ./stories_status.txt --author "$(AUTHOR)" --book "MyStories" --item $(ITEM) $(ITEMANON)

allitems: cleanitems $(BASEDIR)RunItemMake.py $(BASEDIR)Makefile.indiv $(BASEDIR)KenLatexTemplate.item.pandoc | $(OUTDIR)
	python3 $(BASEDIR)RunItemMake.py --status ./stories_status.txt --author "$(AUTHOR)" --book "MyStories" --all $(ITEMANON)

