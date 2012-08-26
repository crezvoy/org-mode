#----------------------------------------------------------------------
# This file is used for maintenance of org on the server.
#----------------------------------------------------------------------
.PHONY:	helpserver \
	release rel-dirty rel-up cleanrel \
	elpa elpa-dirty elpa-up \
	doc-up \
	upload-release upload-elpa upload-doc upload \
	tagwarn version.mk

help helpall helpserver::
	$(info )
	$(info Maintenance)
	$(info ===========)
	$(info release               - clean up and create TAR/ZIP release archives)
	$(info elpa                  - clean up and create ELPA TAR archive)
	$(info upload                - clean up and populate server directories)
helpserver::
	@echo ""

#----------------------------------------------------------------------

ORGCOMM  = README request-assign-future.txt lisp/ doc/
ORGFULL  = $(ORGCOMM) Makefile default.mk targets.mk version.mk \
		      etc/ contrib/ utils/
ORGFULL := $(ORGFULL:%/=%/*)
ORGELPA  = $(ORGCOMM) etc/styles/ org-pkg.el
ORGELPA := $(ORGELPA:%/=%/*)

release:	ORG_MAKE_DOC=info pdf card # do not make HTML documentation
release:	cleanall doc rel-dirty
rel-dirty rel-up:	ORGDIR=org-$(GITVERSION:release_%=%)
rel-dirty rel-up:	ORGDIST=-dist
rel-dirty:	 autoloads version.mk
	-@$(RM) $(ORGDIR) $(ORGRTAR) $(ORGRZIP)
	ln -s . $(ORGDIR)
	tar -zcf $(ORGDIR).tar.gz $(foreach dist, $(ORGFULL), $(ORGDIR)/$(dist))
	zip -r9  $(ORGDIR).zip    $(foreach dist, $(ORGFULL), $(ORGDIR)/$(dist))
	-@$(RM) $(ORGDIR)
	$(if $(filter-out $(ORGVERSION), $(GITVERSION)), \
	    @$(MAKE) tagwarn)
	@echo ORGVERSION=$(ORGVERSION) GITVERSION=$(GITVERSION)$(ORGDIST)
rel-up:	rel-dirty
	$(CP) $(ORGDIR).tar.gz $(ORGDIR).zip $(SERVROOT)/

PKG_TAG = $(shell date +%Y%m%d)
PKG_DOC = "Outline-based notes management and organizer"
PKG_REQ = "nil"

elpa:		ORG_MAKE_DOC=info pdf card # do not make HTML documentation
elpa:		cleanall doc elpa-dirty
elpa-dirty elpa-up:	ORGDIR=org-$(PKG_TAG)
elpa-dirty elpa-up:	ORGDIST=-elpa
elpa-dirty:	autoloads version.mk
	-@$(RM) $(ORGDIR) $(ORGTAR) $(ORGZIP)
	ln -s . $(ORGDIR)
	echo "(define-package \"org\" \"$(PKG_TAG)\" \"$(PKG_DOC)\" $(PKG_REQ))" >org-pkg.el
	tar --exclude=Makefile --transform='s:\(lisp\|doc\)/::' -cf $(ORGDIR).tar \
	  $(foreach dist, $(ORGELPA), $(ORGDIR)/$(dist))
	-@$(RM) $(ORGDIR) org-pkg.el
	$(if $(filter-out $(ORGVERSION), $(GITVERSION)), \
	    @$(MAKE) tagwarn)
	@echo ORGVERSION=$(ORGVERSION) GITVERSION=$(GITVERSION)$(ORGDIST)
elpa-up:	elpa-dirty
	$(CP) $(ORGDIR).tar $(SERVROOT)/pkg/daily/

tagwarn:
	$(info  ======================================================)
	$(info  =                                                    =)
	$(info  = A release should only be made from a revision that =)
	$(info  = has an annotated tag!                              =)
	$(info  =                                                    =)
	$(info  ======================================================)
	@echo ""

version.mk:
	@echo "ORGVERSION	?= $(ORGVERSION)"            > $@
	@echo "GITVERSION	?= $(GITVERSION)$(ORGDIST)" >> $@

cleanall clean:	cleanrel
cleanrel:
	-$(RM) org-*.zip org-*.tar* version.mk

doc-up:
	$(MAKE) -C doc html manual guide
	$(CP) doc/org.html $(SERVROOT)
	$(CP) doc/manual/* $(SERVROOT)/manual
	$(CP) doc/guide/*  $(SERVROOT)/guide

upload upload-elpa upload-release upload-doc:	ORG_MAKE_DOC=info pdf card
upload:	cleanall doc elpa-up rel-up doc-up
upload-elpa:	cleanall doc elpa-up
upload-release:	cleanall doc rel-up
upload-doc:	cleanall doc doc-up
