#!/bin/bash
pdflatex Manual.tex
makeindex Manual.idx -s StyleInd.ist
biber Manual.aux
pdflatex Manual.tex x 2
