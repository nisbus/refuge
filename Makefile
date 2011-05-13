## Copyright 2010 Benoît Chesneau
## 
## Licensed under the Apache License, Version 2.0 (the "License"); you may not
## use this file except in compliance with the License. You may obtain a copy of
## the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
## WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
## License for the specific language governing permissions and limitations under
## the License.

DESTDIR?=
DISTDIR=       rel/archive

include config.mk

all: deps compile

compile:
	@./rebar compile

deps:
	./rebar get-deps

clean:
	@./rebar clean

%.beam: %.erl
	@erlc -o deps/couch/test/etap/ $<
 
check: deps/couch/test/etap/etap.beam deps/couch/test/etap/test_util.beam deps/couch/test/etap/test_web.beam
	@ERL_FLAGS="-pa `pwd`/deps/couch/ebin `pwd`/deps/couch/test/etap" \
		prove -v deps/couch/test/etap/*.t

dist: compile
	@rm -rf rel/refuge
	@./rebar generate

distclean: clean
	@rm -rf rel/refuge
	@rm -rf rel/dev*
	@rm -f rel/couchdb.config
	@rm -rf deps
	@rm -rf rel/tmpdata
	@rm -rf config.mk

install: dist
	@echo "==> install to $(DESTDIR)$(PREFIX)"
	@mkdir -p $(DESTDIR)$(PREFIX)
	@for D in bin erts-* lib releases share; do\
		cp -R rel/refuge/$$D $(DESTDIR)$(PREFIX) ; \
	done
	@mkdir -p $(DESTDIR)$(SYSCONF_DIR)
	@cp -R rel/refuge/etc/*  $(DESTDIR)$(SYSCONF_DIR)
	@mkdir -p $(DESTDIR)$(DATADIR)
	@chown -R $(REFUGE_USER) $(DESTDIR)$(DATADIR)
	@mkdir -p $(DESTDIR)$(VIEWDIR)
	@chown $(REFUGE_USER) $(DESTDIR)$(VIEWDIR)
	@mkdir -p $(DESTDIR)$(LOGDIR)
	@touch $(DESTDIR)$(LOGDIR)/refuge.log
	@chown $(REFUGE_USER) $(DESTDIR)$(LOGDIR)/refuge.log
	@mkdir -p $(DESTDIR)$(RUNDIR)
	@chown -R $(REFUGE_USER) $(DESTDIR)$(RUNDIR)

deps-snapshot: clean
	@rm -rf refuge-deps-$(OS)-$(ARCH).tar.gz
	(cd deps && \
		tar cvzf ../refuge-deps-$(VERSION)-$(OS)-$(ARCH).tar.gz .)

archive: dist
	@rm -rf $(DISTDIR)
	@rm -f refuge-$(VERSION)-$(OS)-$(ARCH).tar.gz
	@mkdir -p $(DISTDIR)$(PREFIX)
	@cp -R rel/refuge/* $(DISTDIR)/$(PREFIX)
	@for D in bin erts-* lib releases share; do\
		cp -R rel/refuge/$$D $(DISTDIR)$(PREFIX) ; \
	done
	@mkdir -p $(DISTDIR)$(SYSCONF_DIR)/refuge
	@cp -R rel/refuge/etc/*  $(DISTDIR)$(SYSCONF_DIR)/refuge/
	@mkdir -p $(DISTDIR)$(LOGDIR)
	@mkdir -p $(DISTDIR)$(RUNDIR)
	@mkdir -p $(DISTDIR)$(DATADIR)
	@mkdir -p $(DISTDIR)$(VIEWDIR)
	@touch $(DISTDIR)$(PREFIX)/var/log/refuge.log
	@for F in LICENSE NOTICE README ; do \
		cp -f $$F $(DISTDIR)$(PREFIX) ; \
	done
	(cd $(DISTDIR) && \
		tar -cvzf ../refuge-$(VERSION)-$(OS)-$(ARCH).tar.gz .)

dev: all
	@rm -rf rel/tmpdata
	@rm -rf rel/dev
	@echo "==> Building development node (ports 15984/15986)"
	@./rebar generate target_dir=dev overlay_vars=dev.config
	@echo "\n\
Development node is built, and can be started using ./rel/dev/bin/refuge.\n" 
