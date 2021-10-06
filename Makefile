### To do:  	item stuff
###		test new permutations

### Book info
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

AUTHOR := Steinbeck Hemingway Faulkner III
PRINTISBN := 999-8-7777777-66-1
# Note: make sure there are no spaces after the ISBN and FPREFIX assignments above 

### Our directories
BASEDIR := ./
SRCDIR := ./src/
IMGDIR := ./img/
GENDIR := ./gen/
OUTDIR := ./out/
STATUS := $(BASEDIR)$(BOOKTYPE)_status.txt

### Ad blurb and image lists
OBOOKS := book1 book2
BLURBLISTTEX = $(patsubst %, $(GENDIR)%_blurb.tex, $(OBOOKS))
BLURBLISTMD = $(patsubst %, $(GENDIR)%_blurb.md, $(OBOOKS))
IMGLIST = $(patsubst %, $(IMGDIR)%.small.jpg, $(OBOOKS))
BWIMGLIST = $(patsubst %, $(IMGDIR)%.bw.jpg, $(OBOOKS))

### Ad image original source locations
book1_img := $(BASEDIR)originalloc1/Pterois_volitans_Manado-e_edit.jpg
book2_img := $(BASEDIR)originalloc2/P-51_Mustang_edit1.jpg

### Ad blurb original source locations
book1_blurb_src := $(BASEDIR)originalloc1/blurb1.md
book2_blurb_src := $(BASEDIR)originalloc2/blurb2.md

### Frontispiece, front, and rear cover original image locations
frontis_img := $(BASEDIR)originalloc3/24512-4-gazelle-transparent-image.png
front_img := $(BASEDIR)originalloc3/Tempietto_del_Bramante_Vorderseite.jpg
back_img := $(BASEDIR)originalloc3/Soyuz_TMA-9_launch.jpg

### Page numbers in ebstuff to use for relevant pages.  Once gen/ebstuff.pdf has been created, extract the page numbers for the halftitle, title, and copyright pages.  Make sure to use the pdf page number, not the book page number (since only mainmatter pages are counted toward the latter).  Add here (or remove) according to what pages in the ebook you want to be images from the print book.  We use ebstuff.pdf instead of book.pdf because ebstuff has equal margins (as opposed to the print even/odd page differences).
EBPAGES := copyright halftitle title
EBPAGELIST = $(patsubst %, $(GENDIR)eb_$(BOOKTYPE)_%.png, $(EBPAGES))
eb_novel_halftitle_page := 3
eb_novel_title_page := 5
eb_novel_copyright_page := 6
eb_stories_halftitle_page := 1
eb_stories_title_page := 3
eb_stories_copyright_page := 4

### Conversion flags for novel (PANFLAGS), collection (ADPANFLAGS), and all ebooks (EPANFLAGS)
PANFLAGS := -M title="$(TITLE)" -M author="$(AUTHOR)" --wrap=none --standalone --verbose --fail-if-warnings --strip-comments -M lang="en-GB" --top-level-division=chapter -t latex -f markdown+smart
EPANFLAGS := -M title="$(TITLE)" -M author="$(AUTHOR)" --wrap=none --standalone --verbose --fail-if-warnings --strip-comments -M lang="en-GB" --top-level-division=chapter --toc-depth=1 -t epub2 -f markdown+smart+header_attributes --metadata-file=$(GENDIR)NeededDummyMetadata.md
ADPANFLAGS := --wrap=none --strip-comments --top-level-division=chapter -t latex -f markdown+smart-auto_identifiers


### Disable intrinsic rules (since we're not coding, they're useless!)
.SUFFIXES:
	$(NOECHO) $(NOOP)

### Preserve intermediate targets (for debugging, etc)
.PRECIOUS: $(GENDIR)% $(OUTDIR)% $(IMGDIR)%
	$(NOECHO) $(NOOP)

.SECONDARY: $(GENDIR)% $(OUTDIR)% $(IMGDIR)%
	$(NOECHO) $(NOOP)

### Declare the non-generative targets
.PHONY: all draft book ebook justebook lookinside clean cleanimages cleanebook cleanall frontispiece ecovers

SRCFILES := $(shell find ./src/ -type f -name '$(FPREFIX)*.md')

### Needed for use of generic variables, but we must be very careful with names!
.SECONDEXPANSION:

### General build targets

all: draft book ebook lookinside ecovers

### Generic Print-book related targets

draft: $(OUTDIR)$(BOOKTYPE)_draft.pdf

book: $(IMGDIR)frontispiece.png $(OUTDIR)$(BOOKTYPE)_book.pdf

$(OUTDIR)%.pdf: $(GENDIR)%.tex $(BWIMGLIST) $(BLURBLISTTEX) $(IMGDIR)frontispiece.book.png | $(OUTDIR)
	-rm -f $@
	-rm -f $(GENDIR)$*.aux
	-rm -f $(GENDIR)$*.log
	-rm -f $(GENDIR)$*.out
	-rm -f $(GENDIR)$*.toc
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) pdflatex -output-directory $(GENDIR) $<
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) pdflatex -output-directory $(GENDIR) $<   # Note: we need the 2nd call to pdflatex to generate the TOC
	mv $(GENDIR)$*.pdf $@

## Novel print-book targets
$(GENDIR)novel_book.md: $(SRCFILES) $(STATUS) $(BASEDIR)AssembleBook.py | $(GENDIR) 
	-rm -f $@
	python3 $(BASEDIR)AssembleBook.py --status $(STATUS) --book $(BOOK) --srcdir $(SRCDIR) --out $@

$(GENDIR)novel_draft.tex: $(GENDIR)novel_book.md $(GENDIR)about.tex $(GENDIR)ack.tex $(BASEDIR)KenLatexTemplate.draft.pandoc
	-rm -f $@
	pandoc $< -o $@ $(PANFLAGS) --template $(BASEDIR)KenLatexTemplate.draft.pandoc

$(GENDIR)novel_book.tex: $(GENDIR)novel_book.md $(GENDIR)about.tex $(GENDIR)ack.tex $(BASEDIR)KenLatexTemplate.book.pandoc
	-rm -f $@
	pandoc $< -o $@ $(PANFLAGS) --template $(BASEDIR)KenLatexTemplate.book.pandoc

## Collection print-book targets
$(GENDIR)inputlist.tex: $(STATUS) $(BASEDIR)GenInputs.py $(BASEDIR)ConvertItemsToTex.py $(SRCFILES) | $(GENDIR)
	-rm -f $@
	python3 $(BASEDIR)GenInputs.py --status $(STATUS) --book $(BOOK) --srcdir $(GENDIR) > $(GENDIR)inputlist.tex
	python3 $(BASEDIR)ConvertItemsToTex.py --status $(STATUS) --book $(BOOK) --srcdir $(SRCDIR) --tgtdir $(GENDIR)

#myvar1 = \$$body\$$
myvar2 = \$$title\$$
#myvar3 = \\input inputlist\.tex

## Pull in template files for collections so they have the right name.
$(GENDIR)stories_book.tex: $(BASEDIR)KenCollectionBook.tex $(GENDIR)inputlist.tex $(GENDIR)about.tex $(GENDIR)ack.tex 
	cat $< | sed -r 's/$(myvar2)/$(TITLE)/g' > $@
#	cat $< | sed -r 's/$(myvar1)/$(myvar3)/' | sed -r 's/$(myvar2)/$(TITLE)/g' > $@

$(GENDIR)stories_draft.tex: $(BASEDIR)/KenCollectionDraft.tex $(GENDIR)inputlist.tex $(GENDIR)about.tex $(GENDIR)ack.tex 
	cat $< | sed -r 's/$(myvar2)/$(TITLE)/g' > $@

### Ebook's intermediate print version (to extract certain page images).  

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

ebook: $(OUTDIR)$(BOOKTYPE)_book.epub | $(OUTDIR) 
	echo "WARNING:  When done, load the ebook into Sigil, and have Sigil generate the TOC (level 1 headers only!) and then save as a new file.  Otherwise Amazon will complain about links in the TOC."

justebook: cleanebook $(OUTDIR)$(BOOKTYPE)_book.epub | $(OUTDIR)
	echo "WARNING:  When done, load the ebook into Sigil, and have Sigil generate the TOC (level 1 headers only!) and then save as a new file.  Otherwise Amazon will complain about links in the TOC."

$(GENDIR)NeededDummyMetadata.md: | $(GENDIR)
	echo "ktitleimage: '<img src=\"gen/eb_$(BOOKTYPE)_title.png\" data-custom-style=\"imgFull\" style=\"width:100.0%;height:100.0%\" alt=\"title page\"/>'" > $@

$(GENDIR)$(BOOKTYPE)_ebook.md: $(SRCFILES) $(BLURBLISTMD) $(BASEDIR)EbookBuild.py $(STATUS) $(GENDIR)NeededDummyMetadata.md | $(GENDIR)
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

cleanebook:
	-rm -rf $(GENDIR)ebook.md
	-rm -rf $(OUTDIR)book.epub

### Some backmatter conversions
$(GENDIR)ack.tex: $(SRCDIR)ack.md | $(GENDIR)
	pandoc $< -o $@

$(GENDIR)about.tex: $(SRCDIR)about.md | $(GENDIR)
	pandoc $< -o $@

$(GENDIR)%_blurb.tex: $(GENDIR)%_blurb.md
	pandoc $< -o $@

### Construct ad images for book and ebook from copies of their original sources.  Order matters here, so place specific overrides first.
book1.small_flags := -resize 300x
book2.small_flags := -resize x480
book1.bw_flags := -resize 800x
book2.bw_flags := -resize 800x

$(IMGDIR)book%.jpg: $$($$(basename $$(@F))_img) | $(IMGDIR)
	cp $< $@

$(IMGDIR)book1.bw.jpg: $(IMGDIR)book1.jpg
	convert $< -quality 90 $(book1.bw_flags) -set colorspace Gray -separate -average $@

$(IMGDIR)book2.bw.jpg: $(IMGDIR)book2.jpg
	convert $< -quality 90 $(book2.bw_flags) -set colorspace Gray -separate -average $@

$(IMGDIR)book1.small.jpg: $(IMGDIR)book1.jpg
	convert $< $(book1.small_flags) +repage -quality 90 $@

$(IMGDIR)book2.small.jpg: $(IMGDIR)book2.jpg
	convert $< $(book2.small_flags) +repage -quality 90 $@

### Copy ad blurbs from source files
$(GENDIR)%_blurb.md: $$($$(basename $$(@F))_src) | $(GENDIR) 
	cp $< $@

### Generate frontispiece
frontispiece: $(IMGDIR)frontispiece.book.png $(IMGDIR)frontispiece.ebook.png

$(IMGDIR)frontispiece.png: $(frontis_img) | $(IMGDIR)
	cp $< $@

$(IMGDIR)frontispiece.book.png: $(IMGDIR)frontispiece.png
	convert $< -colorspace gray $@

$(IMGDIR)frontispiece.ebook.png: $(IMGDIR)frontispiece.png
	convert $< -colorspace gray $@

### Generate front and back covers for ebook.  Amazon likes 2560x1600 as its image size. 
ecovers: $(IMGDIR)front_cover.jpg $(IMGDIR)back_cover.jpg

$(IMGDIR)front_cover_original.jpg:  $(front_img) | $(IMGDIR)
	cp $< $@

$(IMGDIR)back_cover_original.jpg:  $(back_img) | $(IMGDIR)
	cp $< $@

$(IMGDIR)front_cover.jpg: $(IMGDIR)front_cover_original.jpg
	convert $< -resize x2560 -crop 1600x2560+200+0 +repage -quality 90 $@

$(IMGDIR)back_cover.jpg: $(IMGDIR)back_cover_original.jpg
	convert $< -resize x2560 -crop 1600x2560+50+0 +repage -quality 90 $@


### Generate look-inside bundle for upload to amazon (print version, since KDP is generated --- or not, as the case may be --- automatically).  Basically, once the Ingram print edition is out, and Amazon is correctly linked it to your KDP version, you set up a seller profile (they have instructions to do so), and then upload a zip file (names for the ISBN of the print book) containing a front cover image, back cover image, and pdf of the interior of the book. 
ISBNFILE := $(OUTDIR)$(PRINTISBN).zip

lookinside: $(BOOKTYPE)_$(ISBNFILE)

$(GENDIR)$(BOOKTYPE)_interior.pdf: $(OUTDIR)$(BOOKTYPE)_book.pdf $(GENDIR)
	cp $< $@

$(BOOKTYPE)_$(ISBNFILE): $(GENDIR)$(BOOKTYPE)_interior.pdf $(IMGDIR)front_cover.jpg $(IMGDIR)back_cover.jpg | $(OUTDIR)
	zip -j $@ $(GENDIR)$(BOOKTYPE)_interior.pdf $(IMGDIR)front_cover.jpg $(IMGDIR)back_cover.jpg

### NOTE: the ingram cover is something done by the cover artist using a template downloaded from Ingram (for the relevant book size, # pages, etc).  It is not something we attempt to automate.

### Generate a README pdf.
readme: $(GENDIR)README.pdf

$(GENDIR)README.pdf: $(GENDIR)README.tex
	pdflatex --output-directory $(GENDIR) $(GENDIR)README.tex

$(GENDIR)README.tex: $(BASEDIR)README.md | $(GENDIR)
	pandoc --standalone -o $@ $<

