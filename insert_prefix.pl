#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Spec::Functions;
use Cwd q/realpath/;

my $input_file;
my $marker;
my $prefix;

GetOptions (
			'file=s' 	=> \$input_file,
			'marker=s'	=> \$marker,
			'prefix=s'	=>	\$prefix
			);

# print help text if an argument is missing
print_usage() unless $input_file;
print_usage() unless $prefix;

# set default marker 'ref'
$marker = 'ref' unless $marker;

# die if input file doesn't exist
die ("file $input_file does not exist!") unless -e $input_file;

# normalise path of input file
my $canon_input_file = realpath($input_file);
my $output_file = $canon_input_file . ".new";

# open input and output
open (my $input_handle,"<",$canon_input_file) or die "Could not open $canon_input_file: $!";
open (my $output_handle,">",$output_file) or die "Could not open $output_file for writing: $!";


while (my $line = <$input_handle>)
{
	$line =~ s/^(\\$marker\s+)(.+)/$1$prefix$2/;
	print $output_handle $line;
}


close ($input_handle);
close ($output_handle);





############################
# sub routines start here  #
############################
#
# print out program usage
sub print_usage
{
	print "
\n   Usage:  perl insert_prefix.pl -file <input file> -prefix <prefix text> [-marker <marker name>]          
   
\n   Options:  
\n   -f, --file\t:\tpath to the file that should be used as input
\n   -p, --prefix\t:\tstring that should be prefixed to the value of marker
\n   -m, --marker\t:\tname of the toolbox marker that should get the prefix, defaults to 'ref'
\n\n ";

print "
\n   Example: perl insert_prefix.pl --file /home/me/source.txt --prefix abc000_ --marker ref
\n\n";

exit;
}