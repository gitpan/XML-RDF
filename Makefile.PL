# This -*- perl -*- script writes the Makefile for XML-RDF
# $Header: /spare2/ecila-cvsroot/XML-RDF/Makefile.PL,v 1.1.1.1 1999/03/24 17:55:57 ecila40 Exp $

require 5.005;
use strict;

#--- Configuration section ---

use ExtUtils::MakeMaker;

print "Checking for XML-Parser......";
eval {
    require XML::Parser;
    die "" if($XML::Parser::VERSION < 2.20);
};
if ($@) {
    print " failed\n";
    print <<EOT;
$@
XML-RDF needs XML-Parser module, version >= 2.20)
EOT
    exit;
} else {
    print " ok\n";
}

WriteMakefile(
  'VERSION_FROM' => 'lib/XML/RDF.pm',
  'dist'         => {COMPRESS => 'gzip', SUFFIX => '.gz'},
  'NAME'	 => 'XML::RDF',
);
