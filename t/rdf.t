use strict;

use Test;

use XML::RDF;
#
# Not need but included for syntax validation purposes
#
use XML::RDF::Debug;
use XML::RDF::Objects;
use XML::RDF::Stream;
use XML::RDF::Subs;
use XML::RDF::Tree;

plan test => 2;

my($rdf) = XML::RDF->new('Style' => 'Stream');

{
    my($count) = 0;
    my($func) = sub {
	my($expat, $about, $ID, $aboutEach, $aboutEachPrefix, $bagID, @propAttr) = @_;
	$count++;
    };

    $rdf->setRDFHandlers('Description' => $func);
    $rdf->parsefile("t/samples/author.rdf");
    #
    # Stream output is not \n terminated
    #
    print "\n";
    ok($count == 9, 1, "Description handler = $count instead of 9");
}

{
    my($count) = 0;
    my($func) = sub {
	my($expat, $element, $attlist, $content) = @_;
	print "$element @$attlist\n";
	my($item);
	my($nitem) = 0;
	foreach $item (@$content) {
	    print "item $nitem";
	    if(ref($item)) {
		my($key, $value);
		while(($key, $value) = each(%$item)) {
		    if($key eq 'attlist') {
			print "\n\tkey = $key, value = @$value";
		    } else {
			print "\n\tkey = $key, value = $value";
		    }
		}
		print "\n";
		$count++;
	    } elsif(defined($item)) {
		print " : $item\n";
		$count++;
	    } else {
		print " is not defined\n";
	    }
	    $nitem++;
	}
    };
    $rdf->resetRDFHandlers();    
    $rdf->setRDFHandlers('/Bag' => $func);    
    $rdf->setRDFHandlers('/Seq' => $func);    
    $rdf->parsefile("t/samples/bag.rdf");
    print "\n";
    ok($count == 4, 1, "Bags handler = $count instead of 4");
}

# Local Variables: ***
# mode: perl ***
# End: ***
