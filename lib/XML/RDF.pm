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
# $Header: /spare2/ecila-cvsroot/XML-RDF/lib/XML/RDF.pm,v 1.1.1.1 1999/03/24 17:55:57 ecila40 Exp $
#
package XML::RDF;

use strict;
use vars qw($VERSION @ISA);

use XML::Parser;

@ISA = qw(XML::Parser);

$VERSION = "0.01";
sub Version { $VERSION; }

sub new {
    my($class, %args) = @_;

    $args{Non_Expat_Options}->{'RDFHandlers'} = 1;

    my($self) = XML::Parser::new(@_);
    
    $self->{'Namespaces'} = 1;
    my($rdf) = $self->{'RDF'} = {};
    $rdf->{'Handlers'} = $args{'RDFHandlers'} ||= {};

    return $self;
}

sub parse {
    my($self) = @_;

    #
    # Clean context
    #
    my($rdf) = $self->{'RDF'};
    $rdf->{'namespaces'} = [];
    $rdf->{'containerstack'} = [];
    my($key);
    foreach $key (qw(containeritem containers)) {
	delete($rdf->{$key}) if(exists($rdf->{$key}));
    }
    
    XML::Parser::parse(@_);
}

sub setRDFHandlers {
    my($self, %handlers) = @_;

    my($handlers) = $self->{'RDF'}->{'Handlers'};
    my($name, $func);
    while(($name, $func) = each(%handlers)) {
	if(!defined($func)) {
	    delete($handlers->{$name}) if(exists($handlers->{$name}));
	} else {
	    $handlers->{$name} = $func;
	}
    }
}

sub resetRDFHandlers {
    my($self) = @_;

    $self->{'RDF'}->{'Handlers'} = {};
}

__END__

=head1 NAME

XML::RDF - A perl module for parsing XML RDF documents

=head1 SYNOPSIS

  use XML::RDF;

  $p = XML::RDF->new('RDFHandlers' => { 
                     'Description' => \&description_start,
                     '/Description' => \&description_end,
                     'Bag' => \&bag_start,
                     '/Bag' => \&bag_end,
                     },
		     'Style' => 'Stream',
                    );
  $p->parsefile('file.rdf');

=head1 DESCRIPTION

This module is a subclass of XML::Parser class. The basic functions provided
by XML::Parser are not modified. A few handlers have been added to provide
easier access to RDF specificities.

When creating an XML::RDF object the C<Namespaces> option is automatically 
set.

=head1 METHODS

=over 4

=item setRDFHandlers(TYPE, HANDLER, [, TYPE, HANDLER [...]])

This method registers handlers for various parser events. It overrides 
previous handlers registered through RDFHandlers option. If C<HANDLERS>
is set to C<undef> the corresponding handler is removed.
See a description of the handler types in
L<"HANDLERS">.

=item resetRDFHandlers()

This method removes all the handlers registered through RDFHandlers option
or the setRDFHandlers method.

=back

=head1 HANDLERS

The most complex handlers are related to containers. The idea is that
XML::RDF will collect the elements from the container, store them in a list
and provide them to the handler registered for the end tag of the container
(/Bag, /Seq or /Alt). When the elements of the container are simple as in:

  <Bag>
   <li resource="http://www.foo.org/"/>
   <li resource="http://www.bar.org/"/>
  </Bag>

it's enough to register a handler for C</Bag> to get the list of elements.
However, if the container looks like this:

  <Bag>
   <li> <Description resource="http://www.foo.org/"/> </li>
   <li> <Description resource="http://www.bar.org/"/> </li>
  </Bag>

you must provide the C<ContainerItem> handler that will be called for every
recognized XML construct within each <li>. This handler is expected to 
collect data that will built the item list.

When the /Bag, /Seq or /Alt handlers are called, their C<Content> argument
has the following structure, if <li> tags were used:

   [ 
     {
       'attlist' => [ Attr, Val ... ],  # Attribute list from <li> tag.
       'char' => 'abcde...',            # Text between <li></li> if no
                                        # ContainerItem handler.
       ...                              # whatever was added by ContainerItem.
     }
     ...
   ]

or the following structure if C<_[0-9]+> attributes were used:

   [
     'abcde...',                        # value of _0
     undef,                             # _1 was not specified
     'abcde...',                        # value of _2
     ...
   ]

=head2 Description	(Expat, about, ID, aboutEach, aboutEachPrefix, bagID [, Attr, Val [,...]])

This event is generated when the <Description> tag is recognized.

=head2 /Description     (Expat)

This event is generated when the </Description> tag is recognized.

=head2 Bag              (Expat, Element [, Attr, Val [,...]])

This event is generated when the <Bag> tag is recognized. If the 
attributes contain C<_[0-9]+> style names, they are removed from 
the list given in argument.
The C<Element> argument is provided so that it's possible to register
only one function for the Bag, Alt and Seq Handlers.

=head2 Alt              (Expat, Element [, Attr, Val [,...]])

This event is generated when the <Alt> tag is recognized. If the 
attributes contain C<_[0-9]+> style names, they are removed from 
the list given in argument.
The C<Element> argument is provided so that it's possible to register
only one function for the Bag, Alt and Seq Handlers.

=head2 Seq              (Expat, Element [, Attr, Val [,...]])

This event is generated when the <Seq> tag is recognized. If the 
attributes contain C<_[0-9]+> style names, they are removed from 
the list given in argument.
The C<Element> argument is provided so that it's possible to register
only one function for the Bag, Alt and Seq Handlers.

=head2 ContainerItem    (ItemHash, Event, Expat [...])

This event is generated whenever a Start, End, Char or Proc event occur
and that the context is a <li> within a container. The C<ItemHash> is
a reference to a hash table that the ContainerItem is expected to fill.
The C<attlist> member of this hash table is reserved. The C<Event> 
arguement is either Start, End, Char or Proc. The remaining arguments are
the arguments given to the corresponding event.

If no ContainerItem is registered a default action is associated to 
the Char event. It appends the String argument to the C<char> member
of the ItemHash table.

=head2 /Bag              (Expat, Element, Attlist, Content)

This event is generated when the </Bag> tag is recognized. See above
for a description of the C<Content> argument. 
C<Attlist> is a reference to an array containing the attributes found
in the <li> tag.
The C<Element> argument is provided so that it's possible to register
only one function for the /Bag, /Alt and /Seq Handlers.

=head2 /Alt              (Expat, Element, Attlist, Content)

This event is generated when the </Alt> tag is recognized. See above
for a description of the C<Content> argument.
C<Attlist> is a reference to an array containing the attributes found
in the <li> tag.
The C<Element> argument is provided so that it's possible to register
only one function for the /Bag, /Alt and /Seq Handlers.

=head2 /Seq              (Expat, Element, Attlist, Content)

This event is generated when the </Seq> tag is recognized. See above
for a description of the C<Content> argument.
C<Attlist> is a reference to an array containing the attributes found
in the <li> tag.
The C<Element> argument is provided so that it's possible to register
only one function for the /Bag, /Alt and /Seq Handlers.

=head1 BUGS

This is an early alpha version. It does not provide complete RDF support
and is not fully tested. Contributions and critics are wellcome.

The latest version may be found on http://www.senga.org/. 

=head1 AUTHOR

Loic Dachary <F<loic@senga.org>> who was forced to contribute this module
but is C<very> willing to surrender :-)

=cut

1;
# Local Variables: ***
# mode: perl ***
# End: ***
