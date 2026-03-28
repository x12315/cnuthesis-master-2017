# Makefile for ThuThesis

# Compiling method: latexmk/xelatex/pdflatex
METHOD = latexmk
# Set opts for latexmk if you use it
LATEXMKOPTS = -xelatex
# Basename of thesis
THESISMAIN = main
# Basename of shuji
SHUJIMAIN = shuji

PACKAGE=thuthesis
SOURCES=$(PACKAGE).ins $(PACKAGE).dtx
THESISCONTENTS=$(THESISMAIN).tex data/*.tex $(FIGURES)
# NOTE: update this to reflect your local file types.
FIGURES=$(wildcard figures/*.eps figures/*.pdf)
BIBFILE=ref/*.bib
SHUJICONTENTS=$(SHUJIMAIN).tex
CLSFILES=dtx-style.sty $(PACKAGE).cls $(PACKAGE).cfg
HAVE_DTX_SOURCES=$(and $(wildcard $(PACKAGE).ins),$(wildcard $(PACKAGE).dtx))

# make deletion work on Windows
ifdef SystemRoot
	RM = del /Q
	OPEN = start
else
	RM = rm -f
	OPEN = open
endif

.PHONY: all clean distclean dist thesis viewthesis shuji viewshuji doc viewdoc cls check FORCE_MAKE

ifeq ($(strip $(HAVE_DTX_SOURCES)),)
all: thesis
else
all: doc thesis shuji
endif

ifeq ($(strip $(HAVE_DTX_SOURCES)),)
cls:
	@echo "Pre-generated class/style files detected, skip class generation."
else
cls: $(CLSFILES)

$(CLSFILES): $(SOURCES)
	latex $(PACKAGE).ins
endif

viewdoc: doc
	$(OPEN) $(PACKAGE).pdf

ifeq ($(strip $(HAVE_DTX_SOURCES)),)
doc:
	@echo "Skip doc build: missing $(PACKAGE).ins/.dtx sources."
else
doc: $(PACKAGE).pdf
endif

viewthesis: thesis
	$(OPEN) $(THESISMAIN).pdf

thesis: $(THESISMAIN).pdf

viewshuji: shuji
	$(OPEN) $(SHUJIMAIN).pdf

ifeq ($(strip $(HAVE_DTX_SOURCES)),)
shuji:
	@echo "Skip shuji build: missing source files."
else
shuji: $(SHUJIMAIN).pdf
endif

ifeq ($(METHOD),latexmk)

$(PACKAGE).pdf: cls FORCE_MAKE
	$(METHOD) $(LATEXMKOPTS) $(PACKAGE).dtx

$(THESISMAIN).pdf: cls FORCE_MAKE
	$(METHOD) $(LATEXMKOPTS) $(THESISMAIN)

$(SHUJIMAIN).pdf: cls FORCE_MAKE
	$(METHOD) $(LATEXMKOPTS) $(SHUJIMAIN)

else ifneq (,$(filter $(METHOD),xelatex pdflatex))

$(PACKAGE).pdf: cls
	$(METHOD) $(PACKAGE).dtx
	makeindex -s gind.ist -o $(PACKAGE).ind $(PACKAGE).idx
	makeindex -s gglo.ist -o $(PACKAGE).gls $(PACKAGE).glo
	$(METHOD) $(PACKAGE).dtx
	$(METHOD) $(PACKAGE).dtx

$(THESISMAIN).pdf: cls $(THESISCONTENTS) $(THESISMAIN).bbl
	$(METHOD) $(THESISMAIN)
	$(METHOD) $(THESISMAIN)

$(THESISMAIN).bbl: $(BIBFILE)
	$(METHOD) $(THESISMAIN)
	-bibtex $(THESISMAIN)
	$(RM) $(THESISMAIN).pdf

$(SHUJIMAIN).pdf: cls $(SHUJICONTENTS)
	$(METHOD) $(SHUJIMAIN)

else
$(error Unknown METHOD: $(METHOD))

endif

clean:
	latexmk -c $(PACKAGE).dtx $(THESISMAIN) $(SHUJIMAIN)
	-@$(RM) *~

cleanall: clean
	-@$(RM) $(PACKAGE).pdf $(THESISMAIN).pdf $(SHUJIMAIN).pdf

distclean: cleanall
	-@$(RM) $(CLSFILES)
	-@$(RM) -r dist

check: FORCE_MAKE
	ag 'Tsinghua University Thesis Template|\\def\\version|"version":' thuthesis.dtx package.json

dist: all
	@if [ -z "$(version)" ]; then \
		echo "Usage: make dist version=[x.y.z | ctan]"; \
	else \
		gulp build --version=$(version); \
	fi
