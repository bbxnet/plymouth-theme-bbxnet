THEMENAME = bbxnet
THEMEDESC = BBXNET charging logo Plymouth theme.
VERSION = $(shell date '+%Y%m%d')

LOGOWIDTH = 128
LOGOHEIGHT = 128
LOGOALPHA = 70

PROGRESSLEN = 16

THROBBERLEN = 16

theme-dir = /usr/share/plymouth/themes/$(THEMENAME)
theme-file = $(THEMENAME).plymouth

progress-filename = progress
progress-sequence = $(shell seq -w 0 $$(( $(PROGRESSLEN) - 1 )))
progress-animation = $(addprefix $(progress-filename)-,$(addsuffix .png,$(progress-sequence)))

throbber-filename = throbber
throbber-sequence = $(shell seq -w 0 $$(( $(THROBBERLEN) - 1 )))
throbber-animation = $(addprefix $(throbber-filename)-,$(addsuffix .png,$(throbber-sequence)))

static-resources = background-tile.png box.png bullet.png entry.png lock.png

dist-filename = plymouth-theme-$(THEMENAME)
dist-files += $(addprefix $(srcdir)/, $(source-files))
dist-files += Makefile
dist-files += Attribution
dist-files += CC-BY-SA-4.0
dist-files += LICENSE
#TODO add README file
#dist-files += README.md
dist-archive = $(dist-filename).tar.gz $(dist-filename).tar.xz

release-filename = plymouth-theme-$(THEMENAME)-$(VERSION)
release-files += $(progress-animation)
release-files += $(throbber-animation)
release-files += $(static-resources)
release-files += $(theme-file)
release-files += Attribution
release-files += CC-BY-SA-4.0
release-archive = $(release-filename).tar.gz $(release-filename).tar.xz

srcdir = src

source-files += logo.svgz
source-files += theme.plymouth.in
source-files += $(addprefix resource/,$(static-resources))

OBJDIR = obj
VPATH = $(srcdir)

.PHONY: all
all: $(progress-animation) $(throbber-animation) $(static-resources) $(theme-file)

.PHONY: install
install:
	install -d -m 0755 $(DESTDIR)$(theme-dir)
	install -m 0644 $(progress-animation) $(DESTDIR)$(theme-dir)
	install -m 0644 $(throbber-animation) $(DESTDIR)$(theme-dir)
	install -m 0644 $(static-resources) $(DESTDIR)$(theme-dir)
	install -m 0644 $(theme-file) $(DESTDIR)$(theme-dir)

.PHONY: uninstall
uninstall:
	rm -f $(addprefix $(DESTDIR)$(theme-dir)/,$(progress-animation))
	rm -f $(addprefix $(DESTDIR)$(theme-dir)/,$(throbber-animation))
	rm -f $(addprefix $(DESTDIR)$(theme-dir)/,$(static-resources))
	rm -f $(DESTDIR)$(theme-dir)/$(theme-file)
	rm -rf $(DESTDIR)$(theme-dir)

.PHONY: clean
clean:
	rm -rf $(OBJDIR)
	rm -f $(progress-animation)
	rm -f $(throbber-animation)
	rm -f $(static-resources)
	rm -f $(theme-file)

.PHONY: cleanall
cleanall: clean
	rm -f $(dist-archive)
	rm -f $(release-archive)

.PHONY: dist
dist: $(dist-archive)

.PHONY: release
release: $(release-archive)

$(theme-file): theme.plymouth.in
	sed \
		-e "s/@THEMENAME@/$(THEMENAME)/" \
		-e "s/@THEMEDESC@/$(THEMEDESC)/" \
		"$<" > "$@"

$(progress-animation): $(progress-filename)-%.png: $(OBJDIR)/logo-transparent.png $(OBJDIR)/logo-monocolor-white.png
	convert "$<" \
		\( "$(OBJDIR)/logo-monocolor-white.png" -gravity south -crop "0x$$(( ((10#$* * $(LOGOHEIGHT)) / ($(PROGRESSLEN) - 1)) + 1 ))+0+0" \) \
		-gravity south -composite png32:"$@"

$(throbber-animation): $(throbber-filename)-%.png: $(OBJDIR)/logo-extent.png $(OBJDIR)/logo-extent-shade.png
	convert \( "$(OBJDIR)/logo-extent-shade.png" -blur "0x$$( if [ $* -lt $$(( $(THROBBERLEN) / 2 )) ]; then echo $$(( (10#$* * 25) / $(THROBBERLEN) )); else echo $$(( (($(THROBBERLEN) - 10#$* - 1) * 25) / $(THROBBERLEN) )); fi )" \) \
		"$<" \
		-composite png32:"$@"

$(static-resources): %: resource/%
	cp "$<" "$@"

$(OBJDIR):
	mkdir -p "$@"

$(OBJDIR)/logo.png: logo.svgz | $(OBJDIR)
	inkscape -z -e "$@" -w "$(LOGOWIDTH)" -h "$(LOGOHEIGHT)" "$<"

$(OBJDIR)/logo-extent.png: $(OBJDIR)/logo.png
	convert "$<" -background none -gravity center -extent "$$(echo '$(LOGOWIDTH) * 1.4 / 1' | bc)x$$(echo '$(LOGOHEIGHT) * 1.4 / 1' | bc)" png32:"$@"

$(OBJDIR)/logo-extent-shade.png: $(OBJDIR)/logo-monocolor-white.png
	convert "$<" -background none -gravity center -extent "$$(echo '$(LOGOWIDTH) * 1.4 / 1' | bc)x$$(echo '$(LOGOHEIGHT) * 1.4 / 1' | bc)" png32:"$@"

$(OBJDIR)/logo-transparent.png: $(OBJDIR)/logo-monocolor-gray.png
	convert "$<" -alpha on -channel a -evaluate subtract "$(LOGOALPHA)%" png32:"$@"

$(OBJDIR)/logo-monocolor-gray.png: $(OBJDIR)/logo.png
	convert "$<" -channel RGB -fx '10/16' png32:"$@"

$(OBJDIR)/logo-monocolor-white.png: $(OBJDIR)/logo.png
	convert "$<" -channel RGB -fx '16/16' png32:"$@"

$(dist-filename).tar.gz: $(dist-files)
	tar -czf "$@" --transform "s/^\./$(dist-filename)/" $(addprefix ./,$^)

$(dist-filename).tar.xz: $(dist-files)
	tar -cJf "$@" --transform "s/^\./$(dist-filename)/" $(addprefix ./,$^)

$(release-filename).tar.gz: $(release-files)
	tar -czf "$@" --transform "s/^\./$(release-filename)/" $(addprefix ./,$^)

$(release-filename).tar.xz: $(release-files)
	tar -cJf "$@" --transform "s/^\./$(release-filename)/" $(addprefix ./,$^)
