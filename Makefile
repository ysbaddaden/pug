.POSIX:
.PHONY:

CRYSTAL = crystal
CRFLAGS = --progress --release

all: bin/pug

bin/pug: src/*.cr
	$(CRYSTAL) build $(CRFLAGS) src/cli.cr -o $@
