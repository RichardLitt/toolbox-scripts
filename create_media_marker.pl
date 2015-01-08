#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use File::Spec::Functions;
use Cwd q/realpath/;

my $input_file;
my $media_file;
my $marker;

GetOptions (
			'file=s' 	=> \$input_file,
			'media=s'	=> \$media_file,
			'marker=s'	=> \$marker
			);


# print help text if an argument is missing
print_usage() unless $input_file;
print_usage() unless $media_file;

# set default marker 'aud'
$marker = 'aud' unless $marker;

# die if input file doesn't exist
die ("file $input_file does not exist!") unless -e $input_file;

# normalise path of input file
my $canon_input_file = realpath($input_file);
my $output_file = $canon_input_file . ".new";

# open input and output
open (my $input_handle,"<",$canon_input_file) or die "Could not open $canon_input_file: $!";
open (my $output_handle,">",$output_file) or die "Could not open $output_file for writing: $!";

my @array_of_items;
my @item;

# collect file contents into an array of arrays
while (my $line = <$input_handle>)
{
	if ($line !~ /^\s$/)
	{
		push @item, $line;
	}
	else
	{	
		push @array_of_items, [ @item ];
		@item = ();
	}
}

# write contents with added changes back into output file
foreach my $element (@array_of_items)
{
	my $elan_begin;
	my $elan_end;
	my @el_as_array = @$element;
	next if $#el_as_array < 0;
	foreach my $inner_element (@el_as_array)
	{
		if ($inner_element =~ /^\\ELANBegin\s+(\S+)|^\\EUDICOt0\s+(\S+)/)
		{
			$elan_begin = $1;
		}
		if ($inner_element =~ /^\\ELANEnd\s+(\S+)|^\\EUDICOt1\s+(\S+)/)
		{
			$elan_end = $1;
		}
		
		print $output_handle $inner_element;
	
	}
	if ($el_as_array[0] =~ /^\\ref/)
	{
		print $output_handle '\\'. "$marker $media_file $elan_begin $elan_end\n";
	}
	print $output_handle "\n";
	
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
\n   Usage:  perl create_media_marker.pl -file <input file> -media <media file name> [-marker <marker name>]          
   
\n   Options:  
\n   -f, --file\t:\tpath to the file that should be used as input
\n   --media\t:\tname of the media file that should be added
\n   --marker\t:\tname of the toolbox marker that should be added, defaults to 'aud'
\n\n ";

print "
\n   Example: perl create_media_marker.pl --file /home/me/source.txt --media=foobar.wav --marker aud
\n\n";

exit;
}
