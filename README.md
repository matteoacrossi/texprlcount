Texprlcount
===========

`texprlcount` is a Perl script that uses texcount to estimate the word count for Physical Review Letters articles (or other Physical Review articles).

APS sets a limit of 3500 words for PRL articles and provides a guide for estimating the length of a paper:

https://journals.aps.org/authors/length-guide

This script uses the output of texcount to evaluate the word count by considering:

* words in text
* words in captions
* inline equations (1 equation = 1 word)
* displayed equation (1 equation = 12 words)

and excluding

* bibliography
* title and abstract (if .tex file is conveniently edited)
* acknowledgements (like above)

Then, it detects the images appearing in the document and their aspect ratio, based on the output log of pdflatex.

Instructions
------------
In order to use texprlcount, do the following

1. Make sure that texcount is installed (most tex distributions include it)
3. Compile the document with `pdflatex`. Do not delete the `.log` file.
4. Use texprlcount with the following syntax

        texprlcount.pl filename.tex
        

NOTE
----

texprlcount is offered as a tool for estimating the word count of a tex document. texprlcount may fail to produce the correct estimation for a number of reasons and should be used with caution.

In particular, please note the following

* Some features are still missing (see below)
* Currently, texprlcount doesn't work with included `.tex` files
* Embedded graphics, such as tikz code, are not recognized. You can overcome this problem by creating a tex file for each tikz image and then include the generated pdf in the main latex file

Missing features
----------------

* Detect single/two-column equations and tables
