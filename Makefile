MAKEFILEDIR = $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

ifeq ($(shell uname -o),Cygwin)
win_path = $(shell cygpath -ma "$(1)")
uri = $(shell echo file:///$(call win_path,$(1))  | sed -r 's/ /%20/g')
else
win_path = $(shell readlink -fm "$(1)")
uri = $(shell echo file:$(abspath $(1))  | sed -r 's/ /%20/g')
endif

# Unix style destination directory
out_base = $(shell readlink -f "$(1)" | sed -r 's/\.zip/.tmp/')

AUTOCOMMIT = false
SAXON := saxon
JAVA := java
CALABASH = $(MAKEFILEDIR)/calabash/calabash.sh
DEBUG := 1
SRCPATHS = no
CLADES =

UI_LANG = en
HEAP = 1024m
CODE := $(MAKEFILEDIR)
DEVNULL = $(call win_path,/dev/null)
LC_ALL = en_US.UTF-8
FRONTEND_PIPELINES = a9s/common/xpl/docx2jats.xpl 

OUT_BASE   = $(call out_base,$(IN_FILE))
OUT_DIR    = $(OUT_BASE)
NOTDIR     = $(notdir $(IN_FILE))
EXT        = $(subst .,,$(suffix $(NOTDIR)))
IN_FILE_COPY = $(OUT_DIR)/$(NOTDIR)
DEBUG_DIR  = $(OUT_DIR)/debug
HTMLREPORT = $(OUT_DIR)/report.xhtml
PROGRESSDIR= $(OUT_DIR)/debug/status
ACTIONLOG  = $(PROGRESSDIR)/action.log

TESTDATA_SRCDIR = https://subversion.le-tex.de/customers/ulsp/Testset/
TESTDATA_WORKDIR = $(MAKEFILEDIR)/test_$(COMPAT_STAGE)
TESTDATA_RESULTDIR = $(MAKEFILEDIR)/test_result/$(COMPAT_STAGE)

# need to be defined by default, in order to avoid cygpath warnings:
IN_FILE=nodoc

export
unexport out_base win_path uri out_replace

default: usage

check_input:
ifeq ($(IN_FILE),)
	@echo Please specifiy IN_FILE
	@exit 1
endif

mkdirs:
	-mkdir $(dir $(STYLEDOC) $(HTMLREPORT) $(JATS) $(HUB) $(HTML))

conversion: check_input
ifeq ($(suffix $(IN_FILE)),.zip)
	-rm -r $(OUT_DIR)
	mkdir -p $(DEBUG_DIR)/status
	mkdir -p $(OUT_DIR)/tmp
	if [ $(shell readlink -f $(IN_FILE)) != $(shell readlink -m $(IN_FILE_COPY)) ]; then cp $(IN_FILE) $(IN_FILE_COPY); fi
	mkdir -p $(OUT_DIR)/tmp
	unzip -d $(OUT_DIR)/tmp $(IN_FILE_COPY)
	$(MAKE) process_manifest $(IN_FILE)=$(OUT_DIR)/tmp/manifest.xml
	rm $(IN_FILE_COPY) 
	cp $(OUT_DIR)/tmp/*zip $(OUT_DIR)
else
	@echo "Please supply a zip file with manifest.xml in its root directory." | tee $(DEBUG_DIR)/status/no_zip.txt
endif


process_manifest:
	UI_LANG=$(UI_LANG) HEAP=$(HEAP) \
		$(CALABASH) -D \
		-o htmlreport=$(call win_path,$(HTMLREPORT)) \
		-o report=$(call win_path,/dev/null) \
		-i source=$(call uri,$(OUT_DIR)/tmp/manifest.xml) \
		$(call uri,$(MAKEFILEDIR)/xpl/process-manifest-transpect.xpl) \
		debug-dir-uri=$(call uri,$(DEBUG_DIR)) \
		status-dir-uri=$(call uri,$(DEBUG_DIR)/status) \
		debug=yes 


transpectdoc: $(addprefix $(MAKEFILEDIR)/,$(FRONTEND_PIPELINES))
	-mkdir $(MAKEFILEDIR)/doc/transpectdoc
	$(CALABASH) $(foreach pipe,$^,$(addprefix -i source=,$(call uri,$(pipe)))) \
		$(call uri,$(MAKEFILEDIR)/transpectdoc/xpl/transpectdoc.xpl) \
		output-base-uri=$(call uri,$(MAKEFILEDIR)/doc/transpectdoc) \
		project-name=Unionsverlag \
		debug=$(DEBUG) 	debug-dir-uri=$(call uri,$(MAKEFILEDIR)/doc/transpectdoc/debug)


progress:
	@find $(PROGRESSDIR) -name '*txt' -not -empty | xargs -r ls -1rt | xargs -d'\n' -I § sh -c 'date "+%H:%M:%S " -r § | tr -d [:cntrl:]; cat §'

render_single_testfile:
	$(MAKE) conversion IN_FILE=$(IN_FILE) TESTSET_ONLY=yes
	$(CALABASH) \
	  -i source=$(call uri,$(shell echo $(IN_FILE)| sed -r 's/\/docx\/[^\/]+$$/\//g'))/debug/hub2bits/20.clean-up.xml \
	  $(call uri,a9s/common/tei-xpl/prepare-diff.xpl) \
	  out-prefix=$(call uri,$(MAKEFILEDIR)/test_after/$(notdir $(basename $(IN_FILE))))

render_testdata:
ifeq ($(COMPAT_STAGE), before)
	rm -rf $(MAKEFILEDIR)/test_before $(MAKEFILEDIR)/test_after
	svn co $(TESTDATA_SRCDIR) $(MAKEFILEDIR)/test_before
else
	for f in $$(find $(MAKEFILEDIR)/test_before/ -name "*.idml" -o -name "*.docx"); do \
		g="$${f/test_before/test_after}"; \
		mkdir -p "$$(dirname "$$g")"; \
		cp "$$f" "$$g"; \
		$(MAKE) -f $(MAKEFILEDIR)/Makefile render_single_testfile IN_FILE="$${g}"; \
	done
endif

compare_tests:
	@-rm before_after.diff
	@echo "See file before_after.diff for differences."
	exitstatus=0; \
	for file in $(MAKEFILEDIR)/test_before/*.*ml; do \
		echo "======== diff " "$$file" "$${file/test_before/test_after}" >> before_after.diff; \
		diff -b "$$file" "$${file/test_before/test_after}" >> before_after.diff; \
		exitstatus=$$(expr $$exitstatus + $$? ) ; \
	done; \
	if [ $$exitstatus != 0 ]; then echo "DIFFERENT OUTPUT BETWEEN BEFORE AND AFTER. exit status: $$exitstatus"; fi; \
	exit $$exitstatus

accept_results:
	for f in $(MAKEFILEDIR)/test_after/*.*ml; do \
		g="$${f/test_after/test_before}"; \
		cp "$$g" "$$g"~; \
		cp -u "$$f" "$$g" && ((c++)); \
	done
	@echo "Don't forget to commit the changed reference data in test_before if svn status reports 'M'!"
	svn status $(MAKEFILEDIR)/test_before


usage:
	@echo "Usage:"
	@echo "  make docx2jats (or make conversion)"
	@echo "  make doc"



