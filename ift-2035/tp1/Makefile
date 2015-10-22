all:
	gcc -Wall -Og -o tp1 main.c -g

release:
	gcc -Wall -O3 -o tp1 main.c

rapport:
	pdflatex -interaction=nonstopmode -halt-on-error Rapport/TP1.tex

format:
	$(eval TMPFILE := $(shell mktemp))
	clang-format-3.6 main.c > $(TMPFILE)
	cp $(TMPFILE) main.c
