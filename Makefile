#=============================================================
# Makefile LaTeX (luaLaTeX)
#=============================================================
# Author: Angelos Drossos
# (c) 2013, GPLv3
#=============================================================

# Configuration

LATEX = pdflatex	# latex engine: pdflatex or lualatex

OUTFORMAT = pdf#	# generate pdf or dvi
OUTDIR = aux#		# directory for <DOCUMENT>.pdf or <DOCUMENT>.dvi
			# and <DOCUMENT>.aux
			# and other files created by compiling a latex document
# the '#' after the above variables is important!

# all targets (main document)
TARGETS += forschungsprojekt/paper-sensoransteuerung/fp_paper_sensoransteuerung


#=============================================================
#=== change nothing after this hint ==========================
#=============================================================

# $(1) = filename
# $(2) = info string
define echo-compiling-latex
echo "==========================================================";\
echo "  [$(2)] Compiling: $(1)";\
echo "=========================================================="
endef

#--------------------------------------------------
# pdflatex engine commands
#--------------------------------------------------

ifeq ($(strip $(LATEX)),pdflatex)
# options are only inside this if-endif allowed

# $(1): filename
define latex-base-cmd
$(LATEX) \
	-output-directory=$(OUTDIR) \
	-output-format=$(OUTFORMAT) \
	$(1)
endef

# $(1): filename
define latex-final-cmd
$(call latex-base-cmd, -interaction=errorstopmode $(1))
endef

# $(1): filename
define latex-draft-cmd
$(call latex-base-cmd, -interaction=batchmode -draftmode $(1))
endef

# $(1): filename
define latex-draft-recorder-cmd
$(call latex-draft-cmd, -recorder $(1))
endef

# PDFLaTeX logs:

PTRN_OUT_CHANGED = \
	$(strip Package rerunfilecheck Warning: File .+\.out.+ has changed.*)
PTRN_OUT_NOT_CHANGED = \
	$(strip Package rerunfilecheck Info: File .+\.out.+ has not changed.*)

PTRN_LABEL_CHANGED = \
	$(strip LaTeX Warning: Label\(s\) may have changed\. Rerun to get cross-references right\.)

PTRN_BIBLATEX_WARNING = $(strip .*Please rerun LaTeX\.)

LATEX_RERUN_CHECK = \
	$(strip ($(PTRN_OUT_CHANGED))|($(PTRN_LABEL_CHANGED))|($(PTRN_BIBLATEX_WARNING)) )

endif

#--------------------------------------------------
# lualatex engine commands
#--------------------------------------------------

ifeq ($(strip $(LATEX)),lualatex)
# options are only inside this if-endif allowed

# $(1): filename
define latex-base-cmd
$(LATEX) \
	--output-directory=$(OUTDIR) \
	--output-format=$(OUTFORMAT) \
	$(1)
endef

# $(1): filename
define latex-final-cmd
$(call latex-base-cmd, --interaction=batchmode $(1))
endef

# $(1): filename
define latex-draft-cmd
$(call latex-base-cmd, --interaction=batchmode --draftmode $(1))
endef

# $(1): filename
define latex-draft-recorder-cmd
$(call latex-draft-cmd, --recorder $(1))
endef


# LuaLaTeX logs:

PTRN_OUT_CHANGED = \
	$(strip Package rerunfilecheck Warning: File .+\.out.+ has changed.*)
PTRN_OUT_NOT_CHANGED = \
	$(strip Package rerunfilecheck Info: File .+\.out.+ has not changed.*)

PTRN_LABEL_CHANGED = \
	$(strip LaTeX Warning: Label\(s\) may have changed\. Rerun to get cross-references right\.)

PTRN_BIBLATEX_WARNING = $(strip .*Please rerun LaTeX\.)

LATEX_RERUN_CHECK = \
	$(strip ($(PTRN_OUT_CHANGED))|($(PTRN_LABEL_CHANGED))|($(PTRN_BIBLATEX_WARNING)) )

endif

#--------------------------------------------------
# useful functions
#--------------------------------------------------

TEXLOG_GREP = egrep

# extract relative path of a file
define extract-rel-path
$(foreach file,$(1),$(dir $(file))$(notdir $(file)))
endef

# creates the directory/path $(1), if it doesn't exist
define create-output-dir
-mkdir -p $(1)
endef

define logfile
$(foreach file,$(1),$(OUTDIR)/$(file).log)
endef

#--------------------------------------------------
# useful variables
#--------------------------------------------------

# Extract directories and create output variables
TARGETS_FILE   := $(call extract-rel-path,$(TARGETS))
TARGETS_OUT    := $(foreach document,$(TARGETS_FILE),$(OUTDIR)/$(document).$(OUTFORMAT))
TARGETS_AUX    := $(foreach document,$(TARGETS_FILE),$(OUTDIR)/$(document).aux)
TARGETS_LOG    := $(foreach document,$(TARGETS_FILE),$(OUTDIR)/$(document).log)
TARGETS_DEPEND := $(foreach document,$(TARGETS_FILE),$(OUTDIR)/$(document).depend)

#--------------------------------------------------
# Check and run latex in a loop (if necessary)
#--------------------------------------------------

# $(1) = logfile
define check-latex-rerun
$(TEXLOG_GREP) -c -e "$(LATEX_RERUN_CHECK)" $(1)
endef

# $(1) = logfile
define check-latex-rerun-print
$(TEXLOG_GREP) -e "$(LATEX_RERUN_CHECK)" $(1)
endef

# $(1) = texfile
# $(2) = logfile
define latex-draft-loop
	while [[ `$(call check-latex-rerun,$(2))` -ne 0 ]]; \
	do \
		$(call latex-draft-cmd,$(1)); \
	done
endef

# $(1) = texfile
# $(2) = logfile
define latex-final-loop
	while [[ `$(call check-latex-rerun,$(2))` -ne 0 ]]; \
	do \
		$(call echo-compiling-latex,$$<,"final -loop-"); \
		$(call latex-final-cmd,$(1)); \
	done
endef


#--------------------------------------------------
# BibLaTeX + Biber -- Bibliography tool
#--------------------------------------------------

# BibLaTeX

BIBER = biber
BIBER_OPT = --output_safechars --output_directory $(OUTDIR)
BIBER_BIBLATEX_WARNING = Please \(re\)run Biber# TODO | Works with biblatex

ifneq ($(strip $(BIBER)),)

define biber-cmd
$(BIBER) $(BIBER_OPT) $(1)
endef

else

define biber-cmd
echo "BIBER IS DEACTIVATED."
endef

endif

CHECK_BIBER = $(TEXLOG_GREP) '($(BIBER_BIBLATEX_WARNING))'

# %(1): path to document without extension
define run-biber-if-necessary
egrep '($(BIBER_BIBLATEX_WARNING))' $(call logfile,$(1));\
if [ $$? -eq 0 ];\
then \
	echo "==> BibLaTeX/Biber was used."; \
	$(call biber-cmd,$(1)); \
else \
	echo "==> BibLaTeX/Biber was NOT used."; \
fi
endef

#--------------------------------------------------
# check document structure
#--------------------------------------------------

# $(1): latex file
define search-for-documentclass
egrep '^\\documentclass' $(1)
endef

# check if the latex-command '\documentclass' can be found in file $(1)
# if true, this file is a main document, else throw an error
define check-main-document
egrep '^\\documentclass' $(1);\
if [ $$? -eq 0 ];\
then \
	echo "==> Documentclass was found in: $(1)"; \
else \
	echo "!!! Error: No '\documentclass' found in: $(1)"; \
	false; \
fi
endef

#--------------------------------------------------
# depencies
#--------------------------------------------------

# sed command: delete empty line
SED_DEL_EMPTY_LINE = /^\s*$$/d

# sed command: delete comments
SED_DEL_COMMENTS = s/%.*$$//g

# sed replace command
#    $(2): DEB BEGIN
#    $(3): DEB END
#    $(4): DEB SUFFIX
define replace-found
s/.*$(1)\(.*\)$(2).*/\1$(3) /gp
endef

# generic depency extractor
#    $(1): filename
#    $(2): DEPEND BEGIN,  e.g. \input{
#    $(3): DEPEND END,    e.g. }
#    $(4): DEPEND SUFFIX, e.g. .tex
define generic-dep
$(shell sed -n '$(SED_DEL_EMPTY_LINE); $(SED_DEL_COMMENTS); $(call replace-found,$(2),$(3),$(4))' $(1))
endef

# \input{file} --> file.tex
define dep-input
$(call extract-rel-path,$(call generic-dep,$(1),\input{,},.tex))
endef

# \include{file} --> file.tex
define dep-include
$(call extract-rel-path,$(call generic-dep,$(1),\include{,},.tex))
endef

# get all depencies for given latex document
#    $(1): filename
define get-main-document-depends
$(sort $(call dep-input,$(1)) $(call dep-include,$(1)))
endef
#$(foreach dep,$(DEPS_TEX),$(call extract-rel-path,$(call get-depends,$(1),$(dep),.tex)))

# create depencies (use makefile's include command)

NODEP_RULES = show clean distclean

ifneq ($(filter-out $(NODEP_RULES),$(MAKECMDGOALS)),)
TARGETS_DEPEND_EXIST = $(wildcard $(TARGETS_DEPEND))
ifneq ($(TARGETS_DEPEND_EXIST),)
-include $(TARGETS_DEPEND_EXIST)
endif
endif


#--------------------------------------------------
# compile latex --> called in eval
#--------------------------------------------------

# $(1): the directory of the main document file (tex-file), e.g.: src/ or ./
define compile_latex_draft

# get depency list for tex-file
$(OUTDIR)/$(1)%.depend: $(1)%.tex
	@echo "Create depend file for: $$<"
	@$$(call create-output-dir,$$(@D))
	@echo "$(1)$$*.tex: $$(addprefix $(1),$$(call get-main-document-depends,$(1)$$*.tex))"
	@echo "$(1)$$*.tex: $$(addprefix $(1),$$(call get-main-document-depends,$(1)$$*.tex))" > $$@

$(OUTDIR)/$(1)%.aux: $(1)%.tex $(OUTDIR)/$(1)%.depend always
	@$$(call echo-compiling-latex,$$<,"draft")
	@$$(call create-output-dir,$$(@D))
	@$$(call check-main-document,$(1)$$*.tex)
	@$$(call latex-draft-cmd,$(1)$$*)
	@$$(call run-biber-if-necessary,$(1)$$*)

$(OUTDIR)/$(1)%.$(OUTFORMAT): $(1)%.tex $(OUTDIR)/$(1)%.aux always
	@$$(call echo-compiling-latex,$$<,"final")
	@$$(call latex-final-cmd,$(1)$$*)
	@$$(call latex-final-loop,$(1)$$*,$(OUTDIR)/$(1)$$*.log)

$(OUTDIR)/$(1)%.log: always
	@echo "Check '$(1)$$*' log files:"
	@$$(call check-latex-rerun-print,$$@)

always: ;
.PHONY: always

endef

#--------------------------------------------------
# make [all]
#--------------------------------------------------

all: build
.PHONY: all

#--------------------------------------------------
# make show
#--------------------------------------------------

show:
	@echo "LaTeX Engine:   $(LATEX)"
	@echo "OutFormat:      $(OUTFORMAT)"
	@echo "OutDIR:         $(OUTDIR)"
	@echo "Targets_File:   $(TARGETS_FILE)"
	@echo "Targets_Out:    $(TARGETS_OUT)"
	@echo "Targets_Aux:    $(TARGETS_AUX)"
	@echo "Targets_Log:    $(call logfile,$(TARGETS_FILE))"
	@echo "Targets_Depend: $(TARGETS_AUX:.aux=.depend)"
	@echo "Targets_DIRs:   $(sort $(dir $(TARGETS)))"
	@echo ""
	@echo "Targets_TMPs:"
	@echo "$(TARGETS_TMP)"
	@echo ""
	@echo "SubTargets_TMPs:"
	@echo "$(SUBTARGETS_TMP)"
	@echo ""
	@echo "Biber Command:  $(CHECK_BIBER) $(call logfile, document)"
.PHONY: show

#--------------------------------------------------
# make depend
#--------------------------------------------------

depend: $(TARGETS_DEPEND)
.PHONY: depend

log: $(TARGETS_LOG)
.PHONY: log

#--------------------------------------------------
# file specific rules
#--------------------------------------------------

# create pattern rules for every target-directory
#$(foreach directory,$(sort $(dir $(TARGETS))),$(info $(call compile_latex_draft,$(directory)))) #DEBUG
$(foreach directory,$(sort $(dir $(TARGETS))),$(eval $(call compile_latex_draft,$(directory))))


#--------------------------------------------------
# make build / draft
#--------------------------------------------------

build: $(TARGETS_OUT)
.PHONY: build

draft: $(TARGETS_AUX)
.PHONY: draft

#--------------------------------------------------
# make clean / compact
#--------------------------------------------------

TMP_SUFFIXES += .depend # makefile's depend file
TMP_SUFFIXES += .aux # latex main output file
TMP_SUFFIXES += .log .out # latex main output files
TMP_SUFFIXES += .fls # recorder file
TMP_SUFFIXES += .idx .ilg .ind .lof
TMP_SUFFIXES += .lol .lot .nav
TMP_SUFFIXES += .snm .toc .vrb
TMP_SUFFIXES += .bcf .run.xml .blg .bbl    # biber tmp files
TARGETS_TMP  += $(foreach suff,$(TMP_SUFFIXES), $(TARGETS_AUX:.aux=$(suff)))

# tmp files for depencies like \inluce{file}
#SUBTARGETS_FILE = $(foreach document,$(TARGETS_FILE:=.tex), $(call get-main-document-depends,$(document)))
#SUBTARGETS_TMP  = $(foreach suff, $(TMP_SUFFIXES), $(addprefix $(OUTDIR)/,$(SUBTARGETS_FILE:.tex=$(suff))))

clean:
	@-rm -f $(TARGETS_TMP) $(SUBTARGETS_TMP)
	@-if test -d $(OUTDIR); then rmdir --ignore-fail-on-non-empty $(OUTDIR); fi
.PHONY: clean

distclean: clean
	@-rm -f $(TARGETS_OUT)
	@-if test -d $(OUTDIR); then rmdir $(OUTDIR); fi
.PHONY: distclean

#--------------------------------------------------
# make run
#--------------------------------------------------

ifndef PDFVIEWER
PDFVIEWER = evince
endif

#run: $(TARGETS_AUX:.aux=.pdf)
run:
	$(foreach document,$(TARGETS_AUX:.aux=.pdf),$(PDFVIEWER) $(document) > /dev/null 2> /dev/null &)
.PHONY: run
