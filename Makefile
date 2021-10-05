### Book info
TITLE := "My Novel"
AUTHOR := "Steinbeck Hemingway Faulkner III"
PRINTISBN := 999-8-7777777-66-1
# Note: make sure there are no spaces after the ISBN above!

### Our directories
BASEDIR := ./
SRCDIR := ./src/
IMGDIR := ./img/
GENDIR := ./gen/
OUTDIR := ./out/
EBDIR := ./out/eb/

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
EBPAGELIST = $(patsubst %, $(GENDIR)eb_%.png, $(EBPAGES))
eb_halftitle_page := 3
eb_title_page := 5
eb_copyright_page := 6

### Conversion flags for book and ebook
PANFLAGS := -M title=$(TITLE) -M author=$(AUTHOR) --wrap=none --standalone --verbose --fail-if-warnings --strip-comments -M lang="en-GB" --top-level-division=chapter -t latex -f markdown+smart
EPANFLAGS := -M title=$(TITLE) -M author=$(AUTHOR) --wrap=none --standalone --verbose --fail-if-warnings --strip-comments -M lang="en-GB" --top-level-division=chapter --toc-depth=1 -t epub2 -f markdown+smart+header_attributes --metadata-file=$(BASEDIR)NeededDummyMetadata.md

### Disable intrinsic rules (since we're not coding, they're useless!)
.SUFFIXES:
	$(NOECHO) $(NOOP)

### Preserve intermediate targets (for debugging, etc)
.PRECIOUS: $(GENDIR)% $(OUTDIR)% $(IMGDIR)% $(EBDIR)%
	$(NOECHO) $(NOOP)

.SECONDARY: $(GENDIR)% $(OUTDIR)% $(IMGDIR)% $(EBDIR)%
	$(NOECHO) $(NOOP)

### Declare the non-generative targets
.PHONY: all draft book ebook justebook lookinside clean cleanimages cleanebook cleanall frontispiece

SRCFILES := $(shell find ./src/ -type f -name '*.md')

### Needed for use of generic variables, but we must be very careful with names!
.SECONDEXPANSION:

### General build targets

all: draft book ebook lookinside

### Print-book related targets

draft: $(OUTDIR)draft.pdf

book: $(IMGDIR)frontispiece.png $(OUTDIR)book.pdf

$(GENDIR)book.md: $(SRCFILES) $(BASEDIR)status.txt $(BASEDIR)AssembleBook.py | $(GENDIR) 
	-rm -f $@
	python3 $(BASEDIR)AssembleBook.py --status $(BASEDIR)status.txt --book MyNovel --srcdir $(SRCDIR) --out $@

$(GENDIR)draft.tex: $(GENDIR)book.md $(GENDIR)about.tex $(GENDIR)ack.tex $(BASEDIR)KenLatexTemplate.draft.pandoc
	-rm -f $@
	pandoc $< -o $@ $(PANFLAGS) --template $(BASEDIR)KenLatexTemplate.draft.pandoc

$(GENDIR)book.tex: $(GENDIR)book.md $(GENDIR)about.tex $(GENDIR)ack.tex $(BASEDIR)KenLatexTemplate.book.pandoc
	-rm -f $@
	pandoc $< -o $@ $(PANFLAGS) --template $(BASEDIR)KenLatexTemplate.book.pandoc

$(GENDIR)ack.tex: $(SRCDIR)ack.md | $(GENDIR)
	pandoc $< -o $@

$(GENDIR)about.tex: $(SRCDIR)about.md | $(GENDIR)
	pandoc $< -o $@

$(GENDIR)%_blurb.tex: $(GENDIR)%_blurb.md
	pandoc $< -o $@

$(OUTDIR)book.pdf: $(GENDIR)book.tex $(BWIMGLIST) $(BLURBLISTTEX) $(IMGDIR)frontispiece.book.png | $(OUTDIR)
	-rm -f $@
	-rm -f $(GENDIR)book.aux
	-rm -f $(GENDIR)book.log
	-rm -f $(GENDIR)book.out
	-rm -f $(GENDIR)book.toc
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) pdflatex -output-directory $(GENDIR) $<
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) pdflatex -output-directory $(GENDIR) $<
	mv $(GENDIR)book.pdf $@

$(OUTDIR)draft.pdf: $(GENDIR)draft.tex | $(OUTDIR)
	-rm -f $@
	-rm -f $(GENDIR)draft.aux
	-rm -f $(GENDIR)draft.log
	-rm -f $(GENDIR)draft.out
	-rm -f $(GENDIR)draft.toc
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) pdflatex -output-directory $(GENDIR) $<
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) pdflatex -output-directory $(GENDIR) $<
	mv $(GENDIR)draft.pdf $@

### Ebook's intermediate print version (to extract certain page images).  

$(GENDIR)ebstuff.pdf: $(GENDIR)book.tex $(BWIMGLIST) $(BLURBLISTTEX) $(IMGDIR)frontispiece.book.png
	-rm -f $@
	-rm -f $(GENDIR)ebstuff.*
	TEXINPUTS=$(TEXINPUTS):$(SRCDIR):$(IMGDIR) kebonly="true" pdflatex -output-directory $(GENDIR) -jobname ebstuff $(GENDIR)book.tex

$(GENDIR)eb_%.pdf: $(GENDIR)ebstuff.pdf
	-rm -f $@
	pdfseparate -f $($(basename $(@F))_page) -l $($(basename $(@F))_page) $< $@

$(GENDIR)eb_%.png: $(GENDIR)eb_%.pdf
	-rm -f $@
	convert -verbose -density 1200 $< -quality 100 -flatten -resize 25% +repage $@

### Ebook

ebook: $(EBDIR)book.epub | $(EBDIR) 
	echo "WARNING:  When done, load the ebook into Sigil, and have Sigil generate the TOC (level 1 headers only!) and then save as a new file.  Otherwise Amazon will complain about links in the TOC."

justebook: cleanebook $(EBDIR)book.epub | $(EBDIR) 
	echo "WARNING:  When done, load the ebook into Sigil, and have Sigil generate the TOC (level 1 headers only!) and then save as a new file.  Otherwise Amazon will complain about links in the TOC."

$(GENDIR)ebook.md: $(SRCFILES) $(BLURBLISTMD) $(BASEDIR)EbookBuild.py $(BASEDIR)status.txt | $(GENDIR)
	-rm -f $@
	python3 $(BASEDIR)EbookBuild.py --status $(BASEDIR)status.txt --book MyNovel --srcdir $(SRCDIR) --out $@

$(EBDIR)book.epub: $(GENDIR)ebook.md $(IMGLIST) $(EBPAGELIST) $(IMGDIR)frontispiece.ebook.png $(BASEDIR)KenEpubTemplate.pandoc $(BASEDIR)KenEpubStyles.css | $(EBDIR) 
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
	-rm -rf $(EBDIR)book.epub


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

lookinside: $(ISBNFILE)

$(GENDIR)interior.pdf: $(OUTDIR)book.pdf $(GENDIR)
	cp $< $@

$(ISBNFILE): $(GENDIR)interior.pdf $(IMGDIR)front_cover.jpg $(IMGDIR)back_cover.jpg | $(OUTDIR)
	echo $(ISBNFILE)
	zip -j $@ $(GENDIR)interior.pdf $(IMGDIR)front_cover.jpg $(IMGDIR)back_cover.jpg

### NOTE: the ingram cover is something done by the cover artist using a template downloaded from Ingram (for the relevant book size, # pages, etc).  It is not something we attempt to automate.
