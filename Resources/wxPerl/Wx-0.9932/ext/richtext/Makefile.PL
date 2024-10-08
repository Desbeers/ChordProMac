#############################################################################
## Name:        ext/richtext/Makefile.PL
## Purpose:     Makefile.PL for wxRichTextCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     05/11/2006
## RCS-ID:      $Id: Makefile.PL 3532 2015-03-11 01:27:54Z mdootson $
## Copyright:   (c) 2006, 2010 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use strict;

use Config;
use lib '../../build';
use Wx::build::MakeMaker;

wxWriteMakefile( NAME         => 'Wx::RichText',
                 VERSION_FROM => 'lib/Wx/RichText.pm',
                 REQUIRE_WX   => 2.007000,
                 WX_CORE_LIB  => 'richtext html xml core base',
                 );
