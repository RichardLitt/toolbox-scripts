#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Spec::Functions;
use Cwd q/realpath/;

my ($input_file, @insert, $before, $after);


GetOptions (
			'file=s' 	=> \$input_file,
			'insert=s' => \@insert,
			'before=s'	=> \$before,
			'after=s'	=> \$after
			);

@insert = split(/,/,join(',',@insert));

@insert = pre_chomp (@insert);

print_usage() unless $input_file;
print_usage() unless @insert > 0;

# die unless either before or after are specified
die ("Either -before or -after need to be specified\n") unless ($before xor $after);

# die if input file doesn't exist
die ("file $input_file does not exist!") unless -e $input_file;

# normalise path of input file
my $canon_input_file = realpath($input_file);
my $output_file = $canon_input_file . ".new";


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
	my @el_as_array = @$element;
	foreach my $inner_element (@el_as_array)
	{
		if ($before)
		{
			if ($inner_element =~ /^\\$before/)
			{
				foreach my $marker (@insert)
				{
					print $output_handle '\\'."$marker\n";
				} 
			}
		}
		
		print $output_handle $inner_element;
		
		if ($after)
		{
			if ($inner_element =~ /^\\$after/)
			{
				foreach my $marker (@insert)
				{
					print $output_handle '\\'."$marker\n";
				} 
			}
		}
	}
	print $output_handle "\n";
	
}


close ($input_handle);
close ($output_handle);



############################
# sub routines start here  #
############################
#

sub pre_chomp
{
	my @array = @_;
	foreach my $element (@array)
	{
	    $element =~ s/^\s+//; # remove leading whitespace    
    		$element =~ s/\s+$//; # remove trailing whitespace
	}
	return @array;
}

# print out program usage
sub print_usage
{
	print "
\n   Usage:  perl insert_empty_markers.pl -file <input file> -before <marker name> -after <marker name> -insert <list of marker names>          
   
\n   Options:  
\n   -f, --file\t:\tpath to the file that should be used as input
\n   -a, --after\t:\tempty markers should be inserted after this marker (cannot be used at the same time as -before)
\n   -b, --before\t:\tempty markers should be inserted before this marker (cannot be used at the same time as -after)
\n   -i, --insert\t:\tlist of marker names that should be inserted as empty markers (enclosed in '', separate multiple values by comma)
\n\n ";

print "
\n   Example: perl insert_empty_markers.pl --file /home/me/source.txt --after ref --insert 'my_marker1, my_marker2'
\n\n";

exit;
}
