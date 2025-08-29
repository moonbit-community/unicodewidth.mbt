all: info
	moon build
.PHONY: all

info: tables.mbt
	moon info
.PHONY: info

test: all
	moon test
.PHONY: test

tables.mbt:
	cd scripts && ./unicode.py
	moonfmt -w tables.mbt

clean:
	moon clean
	rm -rf .mooncakes/
.PHONY: clean

clean-all: clean
	rm *.mbti
	rm tables.mbt
.PHONY: clean-all
