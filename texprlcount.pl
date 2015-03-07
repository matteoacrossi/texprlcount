#!/usr/bin/perl
#
# This script estimates the word count of a .tex file according to the PRL
# guidelines for length, available at
# 
# https://journals.aps.org/authors/length-guide
#
# The TeXcount is used for words and equations, while the aspect ratio of
# figures is obtained from the latex .log file. If the file is not present,
# an error will be raised
#

use strict;
use POSIX;
use Math::Round;
use warnings;

if ($#ARGV < 0) {
	print "Usage: prllength.pl filename\n";
	exit;
}
my $filename = $ARGV[0];
$filename =~ s{\.[^.]+$}{};

if (!-e "$filename.tex") {
	print "The file $filename doesn't exist\n";
	exit;
}
my $totalcount = 0; # Total word count

# We use texcount for evaluating the total word count given by text, captions, 
# headers, inline equations (1 eq = 1 word) and display equation (1 eq = 16
# words)
my $texcount = `texcount $filename.tex -utf8 -sum=1,1,1,0,0,1,16`;

print "Words in text, headers and equations\n";
print "------------------------------------\n\n";

print "$texcount";
($totalcount) = $texcount =~ /Sum\scount:\s(\d+)/;

# We now address the image estimated word count. PRL length guide suggests the
# formula
#
#				      150              150 * height
# (word count) = -------------- + 20 = ------------ + 20
#                 aspect ratio             width
#
# where aspect ratio is width / height.
#
# We use the pdflatex log file for this task. In the log file, for each
# included graphics an output similar to the following appears
#
# > <filename.pdf, id=116, 199.74625pt x 108.405pt>
# > File: filename.pdf Graphic file (type pdf)
# >
# > <use filename.pdf>
# > Package pdftex.def Info: filename.pdf used on input line 313.
# > (pdftex.def)             Requested size: 221.3985pt x 120.16223pt.
#

open(my $in,"<$filename.log") || die "File $filename.log not found. Please compile the .tex file";

local $/; 	# Allows for the whole file to be read into a string (otherwise, 
			# it would be line-wise)
my $in2 = <$in>;
close $in;
my $imageswordcount = 0;

my @images;

@images = $in2 =~ /(?<=\<use )(.*?)(?=\>)/g;
my @sizes = $in2 =~ /(?<=Requested size:\s)([\d\.]+)pt\sx\s([\d\.]+)pt./g;
my @ars;
my @lengths;
for (my $i=0; $i <= $#sizes; $i= $i+2 ) {
	my $tmp =nearest(0.001, $sizes[$i] /$sizes[$i+1]);
	push(@ars,$tmp);
	push(@lengths,ceil(150 / $tmp + 20));
}

for ( @lengths ) {
    $imageswordcount += $_;
}

print "Images\n";
print "------\n";
my $ml = max_length(@images);
printf "%-${ml}s  Aspect ratio   Est. word count\n", "File name";
print "----------------------------------------------------------------\n";

for (my $i=0; $i <= $#images; $i++) {
	printf "%-${ml}s  %-13s  %s\n", $images[$i],$ars[$i],$lengths[$i];
}

$totalcount += $imageswordcount;

print "\nTotal word count for images: $imageswordcount\n\n";
print "Total word count (words + equations + images)\n$totalcount\n";

sub max_length {
    my $max = -1;
    my $max_ref;
    for (@_) {
        if (length > $max) {  # no temp variable, length() twice is faster
            $max = length;
            $max_ref = \$_;   # avoid any copying
        }
    }
    $max
}