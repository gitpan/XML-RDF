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
# $Header: /spare2/ecila-cvsroot/XML-RDF/lib/XML/RDF/Tree.pm,v 1.1.1.1 1999/03/24 17:55:57 ecila40 Exp $
#
package XML::RDF::Tree;

use strict;

use XML::Parser;

sub Init { XML::Parser::Tree::Init(@_); }
sub Start { XML::Parser::Tree::Start(@_); }
sub End { XML::Parser::Tree::End(@_); }
sub Char { XML::Parser::Tree::Char(@_); }
sub Final { XML::Parser::Tree::Final(@_); }

1;
# Local Variables: ***
# mode: perl ***
# End: ***
