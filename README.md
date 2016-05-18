Texprlcount
===========

`texprlcount` is a Perl script that uses texcount to estimate the word count for Physical Review Letters articles (or other Physical Review articles).

APS sets a limit of 3500 words for PRL articles and provides a guide for estimating the length of a paper:

https://journals.aps.org/authors/length-guide

This script uses the output of `texcount` to evaluate the word count by considering:

* Words in text
* Words in captions
* Inline equations (1 equation = 1 word)
* Displayed equation (1 equation = 12 words)

and excluding

* Bibliography
* Title and abstract
* Acknowledgements

Then, it detects the images appearing in the document and their aspect ratio, based on the output log of `pdflatex`.

Usage
------------
In order to use `texprlcount`, do the following

1. Make sure that `texcount` is installed (most TeX distributions include it)
2. Use `texprlcount` with the following syntax

        texprlcount.pl filename.tex

3. `texprlcount` looks for the `filename.log` file for extracting information on images. If the file is not present, `texprlcount` will compile the `.tex` file with `pdflatex` in a temporary folder. If your file requires special instructions for compiling, please compile it and make sure the log file is present in the file directory.

NOTE
----

`texprlcount` is offered as a tool for estimating the word count of a tex document. texprlcount may fail to produce the correct estimation for a number of reasons and should be used with caution. Apart from unknown bugs, the following are known limitations.

Current limitations
-------------------

* Currently, texprlcount doesn't work with included `.tex` files
* It can't detect single/two-column equations and tables
* It can't detect whether multiple image files in the same figure environment are placed side by side or in column (the length check tool provided by APS doesn't either, by the way). A single pdf per figure is recommended
* Some multiline equation environment may not be detected correctly (please check the number of reported equation lines)
* Embedded graphics, such as `tikz` code, are not recognized. You can overcome this problem by creating a tex file for each `tikz` image and then include the generated pdf in the main LaTeX file

