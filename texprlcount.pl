#!/usr/bin/perl
#
# This script estimates the word count of a .tex file according to the PRL
# guidelines for length, available at
#
# https://journals.aps.org/authors/length-guide
#
# The TeXcount is used for text, tables and equations, while the aspect ratio of
# figures is obtained from the latex .log file. If the file is not present,
# an error will be raised

use strict;
use warnings;
use POSIX;
use Math::Round;
use List::MoreUtils 'first_index';
use File::Temp qw/ tempdir /;
use File::Basename;

if ($#ARGV < 0) {
	print "Usage: texprlcount.pl file.tex\n";
	exit;
}

my $filename = $ARGV[0];

(my $name, my $path, my $suffix) = fileparse($filename, ".tex");

chdir $path;

if (!-e "$name.tex") {
	die "The file $name.tex doesn't exist\n";
}

#We open the tex file and the log file
open(my $texfileh,"<$name.tex") || die "File $path/$name.tex not found.";
my $logfileh;
unless(open($logfileh,"<$name.log")) {
    print "$name.log file not found, compiling the texfile...\n";

my $tmpdir = tempdir( CLEANUP => 1 );
`pdflatex -interaction=nonstopmode -output-directory=$tmpdir $name`;
my $fail = (`echo $?` != 0);
if ($fail) {
  my $cat = `cat $tmpdir/$name.log`;
  printf($cat);
  die "LaTeX compilation failed. Check input .tex file.";
}
open($logfileh,"<$tmpdir/$name.log") || die "File $name.log not found. There were problems during the compilation.";
}


local $/; 	# Allows for the whole file to be read into a string (otherwise,
			# it would be line-wise)

my $logfile = <$logfileh>;
my $texfile = <$texfileh>;

close $logfileh;
close $texfileh;

# We strip comments from the tex file
$texfile =~ s/[^\\]%[^\n]*//g;

# We count the number of characters in the abstract
my $abstract;
($abstract) = $texfile =~ /\\begin\{abstract\}(.*?)\\end\{abstract\}/s;
$abstract =~ s/\R//g;
$abstract = length($abstract);

my $totalcount = 0; # Total word count

# We use texcount for evaluating the total word count given by text, captions,
# headers, inline equations (1 eq = 1 word) and display equation (1 eq = 16
# words)

# We create a temporary rule file to tell texcount to exclude abstract and acknowledgments from the count

open(my $tmp, '>', 'tcrules');
print $tmp "\%group abstract 0 0\n\%group acknowledgments 0 0";
close $tmp;

my $texcount = `texcount $name.tex -opt=tcrules -utf8 -sum=1,1,1,0,0,1,0`;

unlink 'tcrules';

print "\n";
print "Words in text, headers and equations\n";
print "------------------------------------\n";

print "$texcount";

($totalcount) = $texcount =~ /Sum\scount:\s(\d+)/;

print "Abstract length: $abstract characters\n\n";

# DISPLAYED MATH
################
#
# We now address displayed (multiline) equations. First, we match the environments that can contain multiline equations: align, split, eqnarray etc

my (@aligns) = $texfile =~ /\\begin\{(equation|align\*?|eqnarray|gather)\}(.*?)\\end\{\1\}/sg;

my $mathlinecount;
for (my $i = 1; $i <= $#aligns; $i = $i + 2) {
	$mathlinecount += () = $aligns[$i] =~ /\\\\/g;
	$mathlinecount++;
}
#Now we check for $$ .. $$
(@aligns) = $texfile =~ /\$\$(.*?)\$\$/sg;
foreach (@aligns) {
		$mathlinecount++;
}
#And for \[ \]
(@aligns) = $texfile =~ /\\\[(.*?)\\\]/sg;
foreach (@aligns) {
		$mathlinecount++;
}
$totalcount += 16*$mathlinecount;

print "Number of displayed math lines: $mathlinecount\n\n";

# TABLES
##########
my (@tables) = $texfile =~ /\\begin\{tabular\}(.*?)\\end\{tabular\}/sg;
my $tablecount = 0;
my $tablelinecount = 0;

foreach (@tables) {
	$tablecount++;
	$tablelinecount += () = $_ =~ /\\\\/g;
	$tablelinecount += () = $_ =~ /\\tabularnewline/g;
	$tablelinecount -= () = $_ =~ /\\hline[\s]*$/g;
	$tablelinecount -= () = $_ =~ /\\\\[\s]*$/g;
	$tablelinecount++;
}

print "Number of tables: $tablecount\n";
print "Table rows: $tablelinecount\n\n";

$totalcount += 13*$tablecount + 6.5 * $tablelinecount;

# IMAGES
##########
#
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

print "Images\n";
print "------\n";

my $imageswordcount = 0;

my @images;
my @sizes;

# Extract the names of images from the log file
@images = $logfile =~ /\<use (.*?)\>/g;

if ($#images >= 0) {
    @sizes= $logfile =~ /Requested size:\s([\d\.]+)pt\sx\s([\d\.]+)pt/g;

    my @ars;
    # for (my $i=0; $i <= $#images; $i++) {
    #     my $tmp = nearest(0.001, $sizes[2*$i] / $sizes[2*$i+1]);
    #     push(@ars,$tmp);
    # }

    # Now look in the tex file to check wether they are in a single-column or in a
    # double-column figure environment
    # Here, we assume that the order in the log file is the same as the order in the environments

    my @figenvtype = $texfile =~ /\\begin\{figure(\*?)\}/g;
    my @figenv = $texfile =~ /\\begin\{figure(.*?)\\end\{figure/gs;

    my @lengths;

    my $ml = max_length(@images);
    printf "%-${ml}s    Aspect ratio (W/H)  Est. word count   Two-column\n", "File name";
    printf "%${ml}.${ml}s-----------------------------------------------\n", "---------------------------------------------------";

    for(my $i=0; $i <= $#figenv; $i++) {
        my @img_in_env = $figenv[$i] =~ /\\includegraphics(?:\[[^\]]*\])?\{(.*?)\}/gs;
        printf "Figure %s\n", $i + 1;
        foreach my $imgname (@img_in_env) {
            my $index = first_index { /$imgname/ } @images;
            # Aspect ratio
            my $tmp = nearest(0.001, $sizes[2*$index] / $sizes[2*$index+1]);
            push(@ars,$tmp);

            if ($figenvtype[$i] eq '') { #The environment is plain \begin{figure}
                push(@lengths,ceil(150 / $tmp + 20));
            }
            elsif ($figenvtype[$i] eq '*') { # The environment is two column \begin{figure*}
                push(@lengths,ceil(300 / (0.5*$tmp) + 40));
            }
            else {
                die "Error while processing the figure environments";
            }
            printf "  %-${ml}s  %12.2f   %15d   %s\n", $images[$index],$ars[$index],$lengths[$index],$figenvtype[$i];
        }
    }

    for ( @lengths ) {
        $imageswordcount += $_;
    }

    print "\nTotal word count for images: $imageswordcount\n\n";
}
else {
    print "The file doesn't contain images.\n\n";
}

$totalcount += $imageswordcount;

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
