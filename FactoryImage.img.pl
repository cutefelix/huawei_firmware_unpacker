#!/usr/bin/perl
######################################################################
#
#   File          : FactoryImage.img.pl
#   Author(s)     : cutefelix
#   Description   : Unpack a Huawei  'FactoryImage.img' file.
#   Last Modified : Sun 17 Aug 2013
#   By            : cutefelix(c u t e f e l i x @ g m a i l . c o m)
#
######################################################################
 
use strict;
use warnings;

# Turn on print flushing.
$|++;
 
# Unsigned integers are 4 bytes.
use constant UINT_SIZE => 4;
 
# If a filename wasn't specified on the commmand line then
# assume the file to be unpacked is under current directory. 
my $FILENAME = undef;

$FILENAME = 'FactoryImage.img';
 
open(INFILE, $FILENAME) or die "Cannot open $FILENAME: $!\n";
binmode INFILE;
 
# Skip the first 92 bytes, they're blank.
#seek(INFILE, 92, 0);
 
# We'll dump the files into a folder called "output".
my $fileLoc=0;
my $BASEPATH = "output";
mkdir $BASEPATH;
mkdir "output/image";

while (!eof(INFILE))
{
	$fileLoc=&find_next_file($fileLoc);
	#printf "fileLoc=%x\n",$fileLoc;
	seek(INFILE, $fileLoc, 0);
	$fileLoc=&dump_file();
}

close INFILE;
 

# Find the next file block in the main file
sub find_next_file
{
	my ($_fileLoc) = @_;
	my $_buffer = undef;
	my $_skipped=0;

	read(INFILE, $_buffer, UINT_SIZE);
	while ($_buffer ne "\x00\x00\x00\x00" && !eof(INFILE))
	{
		read(INFILE, $_buffer, UINT_SIZE);
		$_skipped+=UINT_SIZE;
	}

	return($_fileLoc + $_skipped);
}
 
# Unpack a file block and output the payload to a file.
sub dump_file {
    my $buffer = undef;
    my $outfilename = undef;
    my $fileSeq;
    my $calculatedcrc = undef;
    my $sourcecrc = undef;
    my $fileChecksum;
 
    # Verify the identifier matches.
    read(INFILE, $buffer, UINT_SIZE); # 0x00000000
    unless ($buffer eq "\x00\x00\x00\x00") { die "Unrecognised file format. Wrong identifier.\n"; }
    read(INFILE, $buffer, UINT_SIZE); # File Name length.
    my ($nameLength) = unpack("V", $buffer);
    read(INFILE, $buffer, 4);         # File Data length
    my ($fileLength) = unpack("V", $buffer);
		read(INFILE, $outfilename, $nameLength);
    # Dump the payload.
    read(INFILE, $buffer, $fileLength);
    open(OUTFILE, ">$BASEPATH$outfilename") or die "Unable to create $outfilename: $!\n";
    binmode OUTFILE;
    print OUTFILE $buffer;
    close OUTFILE;    
    return (tell(INFILE));
}
