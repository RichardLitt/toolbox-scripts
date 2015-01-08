#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Spec::Functions;
use Cwd q/realpath/;

my $input_file;
my $old_label;
my $new_label;

GetOptions (
			'file=s' 	=> \$input_file,
			'old=s'		=> \$old_label,
			'new=s'		=> \$new_label
			);

# print help text if an argument is missing
print_usage() unless $input_file;
print_usage() unless $old_label;
print_usage() unless $new_label;


# die if input file doesn't exist
die ("file $input_file does not exist!") unless -e $input_file;

# normalise path of input file
my $canon_input_file = realpath($input_file);
my $output_file = $canon_input_file . ".new";

open (my $input_handle,"<",$canon_input_file) or die "Could not open $canon_input_file: $!";
open (my $output_handle,">",$output_file) or die "Could not open $output_file for writing: $!";


while (my $line = <$input_handle>)
{
	$line =~ s/^\\$old_label(\s+.+)/\\$new_label$1/;
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
\n   Usage:  perl change_label.pl -file <input file> -old <old label> -new <new label>          
   
\n   Options:  
\n   -f, --file\t:\tpath to the file that should be used as input
\n   -o, --old\t:\tname of the toolbox marker that should change
\n   -n, --new\t:\tstring that the marker should be changed into
\n\n ";

print "
\n   Example: perl change_label.pl --file /home/me/source.txt --old ref --new id
\n\n";

exit;
}