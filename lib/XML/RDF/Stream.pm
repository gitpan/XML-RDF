#
#   Copyright (C) 1997, 1998, 1999
#   	Free Software Foundation, Inc.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /spare2/ecila-cvsroot/XML-RDF/lib/XML/RDF/Stream.pm,v 1.1.1.1 1999/03/24 17:55:57 ecila40 Exp $
#
package XML::RDF::Stream;

use strict;
use Carp;

use XML::Parser;

sub Init { 
    XML::Parser::Stream::Init(@_);
}

sub Start { 
    my($expat, $element, @attlist) = @_;

    my($rdf) = $expat->{'RDF'};
    my($namespaces) = $rdf->{'namespaces'};
    if($element eq 'RDF') {
	unshift(@$namespaces, $expat->namespace($element));
    } elsif(@$namespaces && $expat->namespace($element) eq $$namespaces[0]) {
	my($containerstack) = $rdf->{'containerstack'};
	my($handlers) = $rdf->{'Handlers'};
	if($element eq 'Description') {
	    if(defined($handlers->{'Description'})) {
		my(@tmp) = @attlist;
		my(%args);
		if(@tmp > 0) {
		    if($tmp[0] =~ /^(about|ID|aboutEach|aboutEachPrefix)$/o) {
			my($key) = shift(@tmp);
			my($value) = shift(@tmp);
			$args{$key} = $value;
		    }
		}
		if(@tmp > 0) {
		    if($tmp[0] eq 'bagID') {
			my($key) = shift(@tmp);
			my($value) = shift(@tmp);
			$args{$key} = $value;
		    }
		}
		my($func) = $handlers->{'Description'};
		&$func($expat, 
		       $args{'about'},
		       $args{'ID'},
		       $args{'aboutEach'},
		       $args{'aboutEachPrefix'},
		       $args{'bagID'},
		       @tmp
		       );
	    }
	} elsif($element eq 'Bag' ||
		$element eq 'Alt' ||
		$element eq 'Seq') {
	    #
	    # Do not collect data if no handler defined to handle it
	    #
	    if(defined($handlers->{"/$element"})) {
		my($id) = $rdf->{'containerid'}++;
		unshift(@$containerstack, $id);
		my($content) = [];
		my(@tmp) = @attlist;
		@attlist = ();
		#
		# Collect memberAttr and remove them from attlist
		#
		while(@tmp) {
		    my($attribute) = shift(@tmp);
		    if($attribute =~ /^_(\d+)$/o && @tmp) {
			my($index) = $1;
			my($value) = shift(@tmp);
			$$content[$index] = $value;
		    } else {
			push(@attlist, $attribute);
		    }
		}
		
		$rdf->{'containers'}->{$id} = [ $element, \@attlist, $content ];
		if(exists($handlers->{$element})) {
		    my($func) = $handlers->{$element};
		    &$func($expat, $element, @attlist) if(defined($func));
		}
	    }
	} elsif($element eq 'li') {
	    if(@$containerstack) {
		my($what, $sequence) = ($1, $2);
		my($container) = $rdf->{'containers'}->{$$containerstack[0]};
		my($element, $attlist, $content) = @$container;
		my($item) = !defined(@attlist) || scalar(@attlist) == 0 ? {} : {
		    'attlist' => \@attlist,
		};
		push(@$content, $item);
		$rdf->{'containeritem'} = $item;
	    }
	} else {
	    if(exists($handlers->{$element})) {
		my($func) = $handlers->{$element};
		&$func($expat, $element, @attlist) if(defined($func));
	    }
	}
    }

    ContainerCollect('Start', @_);
    XML::Parser::Stream::Start(@_);
}

sub End { 
    my($expat, $element) = @_;

    my($rdf) = $expat->{'RDF'};
    my($namespaces) = $rdf->{'namespaces'};
    if($element eq 'RDF') {
	shift(@$namespaces);
    } elsif(@$namespaces && $expat->namespace($element) eq $$namespaces[0]) {
	my($handlers) = $rdf->{'Handlers'};
	if($element eq 'Description') {
	    my($func) = $handlers->{'/Description'};
	    &$func($expat) if(defined($func));
	} elsif($element eq 'Bag' ||
		$element eq 'Seq' ||
		$element eq 'Alt') {
	    my($func) = $handlers->{"/$element"};
	    if(defined($func)) {
		my($containers) = $rdf->{'containers'};
		my($id) = shift(@{$rdf->{'containerstack'}});
		&$func($expat, @{$containers->{$id}});
		delete($containers->{$id});
	    }
	} elsif($element eq 'li') {
	    delete($rdf->{'containeritem'}) if(exists($rdf->{'containeritem'}));
	}
    } 

    ContainerCollect('End', @_);
    XML::Parser::Stream::End(@_);
}

sub Char {
    my($expat) = @_;
    ContainerCollect('Char', @_);
    XML::Parser::Stream::Char(@_);
}

sub Proc { 
    my($expat) = @_;
    ContainerCollect('Proc', @_);
    XML::Parser::Stream::Proc(@_);
}

sub Final { 
    my($expat) = @_;
    XML::Parser::Stream::Final(@_);
}

#
# Local functions
#

sub doText { XML::Parser::Stream::doText(@_); }

sub ContainerCollect {
    my($context, $expat) = @_;

    my($rdf) = $expat->{'RDF'};
    if($rdf->{'containeritem'}) {
	my($handlers) = $rdf->{'Handlers'};
	my($func) = $handlers->{'ContainerItem'};
	if(defined($func)) {
	    &$func($rdf->{'containeritem'}, @_);
	} elsif($context eq 'Char') {
	    #
	    # Default behaviour for data is to accumulate
	    #
	    $rdf->{'containeritem'}->{'char'} ||= '';
	    $rdf->{'containeritem'}->{'char'} .= $_[2];
	}
    }
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
