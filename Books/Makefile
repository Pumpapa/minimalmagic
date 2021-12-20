
TRS:
	cp src/main.bbl ./TRS.bbl
	cp src/main.idx ./TRS.idx
	cp src/main.ind ./TRS.ind
	
	./Snippets
	
	for i in \
		MinimalMagicIntro PumWalters References; \
	do \
		pandoc --lua-filter pandoc.filter.lua --listings -f markdown-raw_html  "../content/$$i.md" -t latex -o "texs/$$i.tex"; \
	done
	for i in \
		Annotated-TRAM.1 BinaryNumbers ConvertingCtoTram ConvertingTramToC MemoryManagement  \
		MetaInterpreter MinimalMagic Patterns-TramFromScratch TermRewriting TRAM.1 Tram Acknowledgements; \
	do \
		sed 's/^```\([[:alpha:]][[:alpha:]]*\) {linenos=false}/``` {.\1 .nolinos}/g' ../content/$@/$$i.md | \
		pandoc --lua-filter pandoc.filter.lua --listings -f markdown-raw_html -t latex -o texs/$$i.tex;  \
	done
	
	pdflatex $@
	makeindex $@.idx -s src/StyleInd.ist
	biber $@
	pdflatex $@
	pdflatex $@
	pdflatex $@
clean:
	rm -f *.pdf *.log *.idx *.bbl *.ind *.aux *.bcf *.toc *.run.xml *.ptc *.blg *.ilg *.listing
	rm -f texs/*.tex

test:
	sed 's/^```\([[:alpha:]][[:alpha:]]*\) {linenos=false}/``` {.\1 .nolinos}/g' ../content/TRS/ConvertingTramToC.md | grep '```'

nothing:
	# pandoc --listings --highlight-style haddock --template=~/.pandoc/templates/default.latex -f markdown -t latex -o texs/$$i.tex;  \

	# sed -e "s/→/↞/g" ../content/$@/$$i.md > $$i.xixi; \
	#``` {.prolog .nolinos}
	#```prolog {linenos=false}
	
	#sed 's#^```\\([a-zA-Z]+\\) {linenos=false}#skippy#g' ../content/TRS/ConvertingTramToC.md | grep '```'


	#sed -e 's~^```\\([a-zA-Z]+\\) \\{linenos=false\\}~``` \\{.\\\\1 .nolinos\\}~g' ../content/TRS/ConvertingTramToC.md | grep '```'
