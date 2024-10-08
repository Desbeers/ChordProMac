#############################################################################
## Name:        ext/grid/Makefile.PL
## Purpose:     Makefile.PL for wxGrid
## Author:      Mattia Barbon
## Modified by:
## Created:     04/12/2001
## RCS-ID:      $Id: Makefile.PL 2927 2010-06-06 08:06:10Z mbarbon $
## Copyright:   (c) 2001-2003, 2010 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use strict;
use lib '../../build';
use Wx::build::MakeMaker;

wxWriteMakefile( NAME         => 'Wx::Grid',
                 VERSION_FROM => 'lib/Wx/Grid.pm',
                 WX_CORE_LIB  => 'core base',
                 );

# local variables:
# mode: cperl
# end:
