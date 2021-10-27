# see License.txt for copyright and terms of use

DIR := trend-prof
VERSION := 2006.06.02

.SUFFIXES:

# **** no default target
.PHONY: default_target
default_target:; @echo "You must give an explicit target to make -f Dist.mk"

# **** make a distribution
.PHONY: dist
dist: distclean
	svn export http://trend-prof.tigris.org/svn/trend-prof/trunk $(DIR)
	mv $(DIR) $(DIR)-$(VERSION)
	tar cvzf $(DIR)-$(VERSION).tar.gz $(DIR)-$(VERSION)
	chmod 444 $(DIR)-$(VERSION).tar.gz
	md5sum $(DIR)-$(VERSION).tar.gz

# **** clean the distribution
.PHONY: distclean
distclean:
	rm -rf $(DIR) $(DIR)-*
	rm -f *.tar.gz
