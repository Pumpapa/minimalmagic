
TRS:
	cp src/main.bbl ./TRS.bbl
	cp src/main.idx ./TRS.idx
	cp src/main.ind ./TRS.ind
	
	./Snippets
	
	for i in \
		MinimalMagicIntro PumWalters Acknowledgements References; \
	do \
		pandoc --lua-filter pandoc.filter.lua --listings -f markdown-raw_html  "../content/$$i.md" -t latex -o "texs/$$i.tex"; \
	done
	for i in \
		Annotated-TRAM.1 BinaryNumbers ConvertingCtoTram ConvertingTramToC MemoryManagement  \
		MetaInterpreter MinimalMagic Patterns-TramFromScratch TermRewriting TRAM.1 Tram Conclusion; \
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

SE:
	cp src/main.bbl ./TRS.bbl
	cp src/main.idx ./TRS.idx
	cp src/main.ind ./TRS.ind
	
	./Snippets
	
	for i in \
		MinimalMagicIntro PumWalters Acknowledgements References; \
	do \
		pandoc --lua-filter pandoc.filter.lua --listings -f markdown-raw_html  "../content/$$i.md" -t latex -o "texs/$$i.tex"; \
	done
	for i in \
		SomeComputingHistory SE-Intro Transistors-Gates BooleanArithmeticNumbers Components Data Mechanisms BiggerThings \
		ISA-µArchitecture DataTypes LanguageProcessing Parallellism VirtualMemory Multitasking Processes SupportingStructures; \
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

TRS.epub: TRS.pdf
	rm $@; echo "" | k2pdfopt -c -fc- -dpi 150 -o $@ -x  $(basename $@).pdf; mv $@.pdf $@
SE.epub: SE.pdf
	rm $@; echo "" | k2pdfopt -c -fc- -dpi 150 -o $@ -x  $(basename $@).pdf; mv $@.pdf $@

clean:
	rm -f *.pdf *.log *.idx *.bbl *.ind *.aux *.bcf *.toc *.run.xml *.ptc *.blg *.ilg *.listing
	rm -f texs/*.tex
	rm -f *.epub *.opf *.xhtml *.svg *.xref *.ps *.ncx *.lg *.dvi *.4tc *.ct *.tmp *.css *.idv *.4ct
	rm -rf *-epub3
	rm -f LaTeXML.cache TRS.html TRS.mobi TRS.xml 

compress:
	gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$@.zip.pdf $@.pdf

test:
	sed 's/^```\([[:alpha:]][[:alpha:]]*\) {linenos=false}/``` {.\1 .nolinos}/g' ../content/TRS/ConvertingTramToC.md | grep '```'

nothing:
	# pandoc --listings --highlight-style haddock --template=~/.pandoc/templates/default.latex -f markdown -t latex -o texs/$$i.tex;  \

	# sed -e "s/→/↞/g" ../content/$@/$$i.md > $$i.xixi; \
	#``` {.prolog .nolinos}
	#```prolog {linenos=false}
	
	#sed 's#^```\\([a-zA-Z]+\\) {linenos=false}#skippy#g' ../content/TRS/ConvertingTramToC.md | grep '```'


	#sed -e 's~^```\\([a-zA-Z]+\\) \\{linenos=false\\}~``` \\{.\\\\1 .nolinos\\}~g' ../content/TRS/ConvertingTramToC.md | grep '```'
