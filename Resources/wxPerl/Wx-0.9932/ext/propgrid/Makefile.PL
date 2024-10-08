#############################################################################
## Name:        ext/propgrid/Makefile.PL
## Purpose:     Makefile.PL for wxPropertyGrid
## Author:      Mark Dootson
## Modified by:
## Created:     01/03/2012
## SVN-ID:      $Id: Makefile.PL 3176 2012-03-08 03:26:08Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use strict;

use Config;
use lib '../../build';
use Wx::build::MakeMaker;

wxWriteMakefile( NAME         => 'Wx::PropertyGrid',
                 VERSION_FROM => 'lib/Wx/PropertyGrid.pm',
                 REQUIRE_WX   => 2.009003,
                 WX_CORE_LIB  => 'propgrid core base',
                 REQUIRE_WX_LIB  => 'propgrid',
                 NO_WX_PLATFORMS => [ ],
               );