#! perl

use strict;
use warnings;
use utf8;

package Text::Layout::PDFAPI2;

use parent 'Text::Layout';
use Carp;
use List::Util qw(max);

my $hb;
my $fc;

#### API
sub new {
    my ( $pkg, @data ) = @_;
    unless ( @data == 1 && ref($data[0]) =~ /^PDF::(API2|Builder)\b/ ) {
	croak("Usage: Text::Layout::PDFAPI2->new(\$pdf)");
    }
    my $self = $pkg->SUPER::new;
    $self->{_context} = $data[0];
    if ( !$fc || $fc->{__PDF__} ne $data[0] ) {
	# Init cache.
	$fc = { __PDF__ => $data[0] };
	Text::Layout::FontConfig->reset;
    }
    require Text::Layout::PDFAPI2::ImageElement;
    $self->register_element
      ( Text::Layout::PDFAPI2::ImageElement->new( pdf => $data[0] ), "img" )
      unless $self->get_element_handler("img");

    $self;
}

sub _pdf {
    my ( $self ) = @_;
    $self->{_context};
}

# Creates a (singleton) HarfBuzz::Shaper object.
sub _hb_init {
    return $hb if defined $hb;
    $hb = 0;
    eval {
	require HarfBuzz::Shaper;
	$hb = HarfBuzz::Shaper->new;
    };
    return $hb;
}

# Verify if a font needs shaping, and we can do that.
sub _hb_font_check {
    my ( $f ) = @_;
    return $f->{_hb_checked} if defined $f->{_hb_checked};

    if ( $f->get_shaping ) {
	my $fn = $f->to_string;
	if ( $f->{font}->can("fontfilename") ) {
	    if ( _hb_init() ) {
		# warn("Font $fn will use shaping.\n");
		return $f->{_hb_checked} = 1;
	    }
	    carp("Font $fn: Requires shaping but HarfBuzz cannot be loaded.");
	}
	else {
	    carp("Font $fn: Shaping not supported");
	}
    }
    else {
	# warn("Font ", $f->to_string, " does not need shaping.\n");
    }
    return $f->{_hb_checked} = 0;
}

#### API
sub render {
    my ( $self, $x, $y, $text, $fp ) = @_;

    $self->{_lastx} = $x;
    $self->{_lasty} = $y;

    my @bb = $self->get_pixel_bbox;
    my $bl = $bb[0];
    my $align = $self->{_alignment} // 0;
    if ( $self->{_width} ) {
	my $w = $bb[3];
	if ( $w < $self->{_width} ) {
	    if ( $align eq "right" ) {
		$x += $self->{_width} - $w;
	    }
	    elsif ( $align eq "center" ) {
		$x += ( $self->{_width} - $w ) / 2;
	    }
	    else {
		$x += $bb[1];
	    }
	}
    }
    my $upem = 1000;		# as per PDF::API2

    my $draw_bg = sub {
	my ( $fx, $nfx, $x, $y, $w ) = @_;
	my $h = $bb[2];		# "border"
	my $d = abs($h)/25;

	# If first with background, extend a little to the left.
	if ( $fx == 0 || !$self->{_content}->[$fx-1]->{bgcolor} ) {
	    $x -= $d;
	    $w += $d;
	}
	# If last with background, extend a little to the right.
	if ( $fx == $nfx-1 || !$self->{_content}->[$fx+1]->{bgcolor} ) {
	    $w += 2*$d;
	}

	# If next is a strut, followed by same bg color,
	# have the background span the strut.
	#### TODO: Span multiple struts.
	my $delta;
	for ( my $i = $fx+1; $i < $nfx; $i++ ) {
	    if ( $self->{_content}->[$i]->{type} eq "strut" ) {
		$delta //= 0;
		$delta += $self->{_content}->[$i]->{width};
	    }
	    elsif ( defined($delta)
		 && $self->{_content}->[$i]->{bgcolor}
		 && $self->{_content}->[$i]->{bgcolor}
		    eq $self->{_content}->[$fx]->{bgcolor} ) {
		$w += $delta;
		last;
	    }
	}
	# Draw the background.
	$text->textend;
	my $gfx = $text;	# sanity
	$gfx->save;
	$gfx->fillcolor( $self->{_content}->[$fx]->{bgcolor} );
	$gfx->linewidth(0);
	$gfx->rectangle( $x, $y+$d, $x+$w, $y+$h-$d );
	$text->fill;
	$gfx->restore;
	$text->textstart;
    };

    my $nfx = @{ $self->{_content} };
    for ( my $fx = 0; $fx < $nfx; $fx++ ) {
	my $fragment = $self->{_content}->[$fx];

	if ( $fragment->{type} eq "strut" ) {
	    $x += $fragment->{width};
	}

	elsif ( my $hd = $self->get_element_handler($fragment->{type}) ) {
	    $text->textend;
	    my $ab = $hd->render($fragment, $text, $x, $y-$bl)->{abox};
	    $text->textstart;
	    $x += $ab->[2];
	}
	next unless $fragment->{type} eq "text" && length($fragment->{text});

	my $x0 = $x;
	my $y0 = $y;
	my $f = $fragment->{font};
	my $font = $f->get_font($self);
	unless ( $font ) {
	    carp("Can't happen?");
	    $f = $self->{_currentfont};
	    $font = $f->getfont($self);
	}
	$text->strokecolor( $fragment->{color} );
	$text->fillcolor( $fragment->{color} );
	$text->font( $font, $fragment->{size} || $self->{_currentsize} );

	if ( _hb_font_check($f) ) {
	    $hb->set_font( $font->fontfilename );
	    $hb->set_size( $fragment->{size} || $self->{_currentsize} );
	    $hb->set_text( $fragment->{text} );
	    $hb->set_direction( $f->{direction} ) if $f->{direction};
	    $hb->set_language( $f->{language} ) if $f->{language};
	    my $info = $hb->shaper($fp);
	    my $y = $y - $fragment->{base} - $bl;
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $w = 0;
	    $w += $_->{ax} for @$info;

	    if ( $fragment->{bgcolor} ) {
		$draw_bg->( $fx, $nfx, $x0, $y0, $w );
	    }

	    foreach my $g ( @$info ) {
		$text->translate( $x + $g->{dx}, $y - $g->{dy} );
		$text->glyph_by_CId( $g->{g} );
		$x += $g->{ax};
		$y += $g->{ay};
	    }
	}
	else {
	    printf("%.2f %.2f %.2f \"%s\" %s\n",
		   $x, $y-$fragment->{base}-$bl,
		   $font->width($fragment->{text}) * ($fragment->{size} || $self->{_currentsize}),
		   $fragment->{text},
		   join(" ", $fragment->{font}->{family},
			$fragment->{font}->{style},
			$fragment->{font}->{weight},
			$fragment->{size} || $self->{_currentsize},
			$fragment->{color},
			$fragment->{underline}||'""', $fragment->{underline_color}||'""',
			$fragment->{strikethrough}||'""', $fragment->{strikethrough_color}||'""',
		       ),
		  ) if 0;
	    my $t = $fragment->{text};
	    if ( $t ne "" ) {

		# See ChordPro issue 240.
		if ( $font->issymbol && $font->is_standard ) {
		    # This enables byte access to these symbol fonts.
		    utf8::downgrade( $t, 1 );
		}

		my $y = $y-$fragment->{base}-$bl;
		my $sz = $fragment->{size} || $self->{_currentsize};
		my $w = $font->width($t) * $sz;

		if ( $fragment->{bgcolor} ) {
		    $draw_bg->( $fx, $nfx, $x0, $y0, $w );
		}

		$text->font( $f->get_font, $sz );
		$text->translate( $x, $y );
		$text->text($t);
		$x += $w;
	    }
	}

	next unless $x > $x0;
	# While PDF::API2 delivers font metrics in 1/1000s,
	# underlinethickness and position are unscaled UPEM.
	my $dw = $font->data->{upem} // 1000;

	my @strikes;
	if ( $fragment->{underline} && $fragment->{underline} ne 'none' ) {
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $d = -( $f->{underline_position}
		       || $font->underlineposition ) * $sz/$dw;
	    my $h = ( $f->{underline_thickness}
		      || $font->underlinethickness ) * $sz/$dw;
	    my $col = $fragment->{underline_color} // $fragment->{color};
	    if ( $fragment->{underline} eq 'double' ) {
		push( @strikes, [ $d-0.125*$h, $h * 0.75, $col ],
		                [ $d+1.125*$h, $h * 0.75, $col ] );
	    }
	    else {
		push( @strikes, [ $d+$h/2, $h, $col ] );
	    }
	}

	if ( $fragment->{strikethrough} ) {
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $xh = $font->xheight / 1000;
	    my $d = -( $f->{strikeline_position}
		       ? $f->{strikeline_position} / $dw
		       : 0.6*$xh ) * $sz;
	    my $h = ( $f->{strikeline_thickness}
		      || $f->{underline_thickness}
		      || $font->underlinethickness ) * $sz/$dw;
	    my $col = $fragment->{strikethrough_color} // $fragment->{color};
	    push( @strikes, [ $d+$h/2, $h, $col ] );
	}

	if ( $fragment->{overline} && $fragment->{overline} ne 'none' ) {
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $xh = $font->xheight / 1000;
	    my $h = ( $f->{overline_thickness}
		      || $f->{underline_thickness}
		      || $font->underlinethickness ) * $sz/$dw;
	    my $d = -( $f->{overline_position}
		       ? $f->{overline_position} * $sz/$dw
		       : $xh*$sz + 2*$h );
	    my $col = $fragment->{overline_color} // $fragment->{color};
	    if ( $fragment->{overline} eq 'double' ) {
		push( @strikes, [ $d-0.125*$h, $h * 0.75, $col ],
		                [ $d+1.125*$h, $h * 0.75, $col ] );
	    }
	    else {
		push( @strikes, [ $d+$h/2, $h, $col ] );
	    }
	}
	$text->textend if @strikes;
	for ( @strikes ) {
	    my $gfx = $text;	# prevent mental insanity
	    $gfx->save;
	    $gfx->strokecolor($_->[2]);
	    $gfx->linewidth($_->[1]);
	    $gfx->move( $x0, $y0-$fragment->{base}-$bl-$_->[0] );
	    $gfx->line( $x,  $y0-$fragment->{base}-$bl-$_->[0] );
	    $gfx->stroke;
	    $gfx->restore;
	}
	$text->textstart if @strikes;

	if ( $fragment->{href} ) {
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $ann = $text->{' apipage'}->annotation;
	    $ann->url( $fragment->{href},
		     #  -border => [ 0, 0, 1 ],
		       -rect => [ $x0, $y0, #-$fragment->{base}-$bl,
		     		  $x, $y0 - $sz ]
		     );
	}
    }
}

#### API
sub bbox {
    my ( $self, $all ) = @_;

    my ( $bl, $x, $y, $w, $h ) = (0) x 4;
    my ( $d, $a ) = (0) x 2;
    my ( $xMin, $xMax, $yMin, $yMax );
    my $dir;
    $self->{_struts} = [];

    foreach ( @{ $self->{_content} } ) {

	0&&
	warn("IB: ",
	     join(", ",
		  map { defined($_) ? sprintf("%.2f", $_) : "<undef>" }
		  $xMin, $yMin, $xMax, $yMax ), "\n");

	if ( $_->{type} eq "strut" ) {
	    my @ab = ( 0, -($_->{desc}//0),
		       $_->{width}//0, $_->{asc}//0 );
	    my %s = %$_;
	    delete($s{type});
	    $s{_x} = $w;
	    $s{_strut} = $_;
	    push( @{ $self->{_struts} }, \%s );
	    # Add to bbox but not to inkbox.
	    $w += $ab[2];
	    $a = $ab[3] if $ab[3] > $a;
	    $d = $ab[1] if $ab[1] < $d;
	}

	elsif ( my $hd = $self->get_element_handler($_->{type}) ) {
	    my @ab = @{$hd->bbox($_)->{abox}};
	    $xMin //= $w + $ab[0] if $all;
	    $xMax = $w + $ab[2];
	    $w += $ab[2];
	    $a = $ab[3] if $ab[3] > $a;
	    $d = $ab[1] if $ab[1] < $d;
	    if ( $all ) {
		$yMin = $ab[1] if !defined($yMin) || $ab[1] < $yMin;
		$yMax = $ab[3] if !defined($yMax) || $ab[3] > $yMax;
	    }
	}

	next unless $_->{type} eq "text" && length($_->{text});

	my $f = $_->{font};
	my $font = $f->get_font($self);
	unless ( $font ) {
	    carp("Can't happen?");
	    $f = $self->{_currentfont};
	    $font = $f->getfont($self);
	}
	my $upem = 1000;	# as delivered by PDF::API2
	my $size = $_->{size};
	my $base = $_->{base};
	my $mydir = $f->{direction} || 'ltr';

	# Width and inkbox, if requested.
	if ( _hb_font_check( $f ) ) {
	    $hb->set_font( $font->fontfilename );
	    $hb->set_size($size);
	    $hb->set_language( $f->{language} ) if $f->{language};
	    $hb->set_direction( $f->{direction} ) if $f->{direction};
	    $hb->set_text( $_->{text} );
	    my $info = $hb->shaper;
	    $mydir = $hb->get_direction;
	    # warn("mydir $mydir\n");

	    if ( $all ) {
		my $ext = $hb->get_extents;
		foreach my $g ( @$info ) {
		    my $e = shift(@$ext);
		    printf STDERR ( "G  %3d  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f\n",
				    $g->{g}, $g->{ax},
				    @$e{ qw( x_bearing y_bearing width height ) } ) if 0;
		    # It is easier to work with the baseline oriented box.
		    $e->{xMin} = $e->{x_bearing};
		    $e->{yMin} = $e->{y_bearing} + $e->{height} - $base;
		    $e->{xMax} = $e->{x_bearing} + $e->{width};
		    $e->{yMax} = $e->{y_bearing} - $base;

		    $xMin //= $w + $e->{xMin} if $e->{width};
		    $yMin = $e->{yMin}
		      if !defined($yMin) || $e->{yMin} < $yMin;
		    $yMax = $e->{yMax}
		      if !defined($yMax) || $e->{yMax} > $yMax;
		    $xMax = $w + $e->{xMax};
		    $w += $g->{ax};
		}
	    }
	    else {
		foreach my $g ( @$info ) {
		    $w += $g->{ax};
		}
	    }
	}
	elsif ( $all && $font->can("extents") ) {
	    my $e = $font->extents( $_->{text}, $size );
	    printf STDERR ("(%.2f,%.2f)(%.2f,%.2f) -> ",
			   $xMin//0, $yMin//0, $xMax//0, $yMax//0 ) if $all && 0;
	    $xMax = $w + $e->{xMax} if $all;
	    $w += $e->{wx};
#	    warn("W \"", $_->{text}, "\" $w, ", $e->{width}, "\n");
	    if ( $all ) {
		$_ -= $base for $e->{yMin}, $e->{yMax};
		# Baseline oriented box.
		$xMin //= $w - $e->{wx} + $e->{xMin};
		$yMin = $e->{yMin}
		  if !defined($yMin) || $e->{yMin} < $yMin;
		$yMax = $e->{yMax}
		  if !defined($yMax) || $e->{yMax} > $yMax;
		printf STDERR ("(%.2f,%.2f)(%.2f,%.2f)\n",
			       $xMin//0, $yMin//0, $xMax//0, $yMax//0 ) if 0;
	    }
	}
	else {
	    $w += $font->width( $_->{text} ) * $size;
	}

	# We have width. Now the rest of the layoutbox.
	my ( $d0, $a0 );
	$d0 = $f->get_descender * $size / $upem - $base;
	$a0 = $f->get_ascender * $size / $upem - $base;
	# Keep track of biggest decender/ascender.
	$d = $d0 if $d0 < $d;
	$a = $a0 if $a0 > $a;

	# Direction.
	$dir //= $mydir;
	$dir = 0 unless $dir eq $mydir; # mix
    }
    $bl = $a;
    $h = $a - $d;

    my $align = $self->{_alignment};
    # warn("ALIGN: ", $align//"<unset>","\n");
    if ( $self->{_width} && $dir && $w < $self->{_width} ) {
	if ( $dir eq 'rtl' && (!$align || $align eq "left") ) {
	    $align = "right";
	    # warn("ALIGN: set to $align\n");
	}
    }
    if ( $self->{_width} && $align && $w < $self->{_width} ) {
	# warn("ALIGNING...\n");
	if ( $align eq "right" ) {
	    # warn("ALIGNING: to $align\n");
	    $x += my $d = $self->{_width} - $w;
	    $xMin += $d if defined $xMin;
	    $xMax += $d if defined $xMax;
	}
	elsif ( $align eq "center" ) {
	    # warn("ALIGNING: to $align\n");
	    $x += my $d = ( $self->{_width} - $w ) / 2;
	    $xMin += $d if defined $xMin;
	    $xMax += $d if defined $xMax;
	}
    }

    [ $bl, $x, $y-$h, $w, $h,
      defined $xMin ? ( $xMin, $yMin-$bl, $xMax-$xMin, $yMax-$yMin ) : ()];
}

#### API
sub load_font {
    my ( $self, $font, $fd ) = @_;

    if ( my $f = $fc->{$font} ) {
	# warn("Loaded font $font (cached)\n");
	$fd->{ascender}  //= $f->ascender;
	$fd->{descender} //= $f->descender;
	return $f;
    }
    my $ff;
    my $actual = Text::Layout::FontConfig->remap($font) // $font;
    if ( $actual =~ /\.[ot]tf$/ ) {
	eval {
	    $ff = $self->{_context}->ttfont( $actual,
					     -dokern => 1,
					     $fd->{nosubset}
					     ? ( -nosubset => 1 )
					     : ( -nosubset => 0 ),
					   );
	};
    }
    else {
	eval {
	    $ff = $self->{_context}->corefont( $actual, -dokern => 1 );
	};
    }

    croak( "Cannot load font: ", $actual,
	   $actual ne $font ? " (remapped from $font)" : "",
	   "\n", $@ ) unless $ff;
    # warn("Loaded font: $font\n");
    $self->{font} = $ff;
    $fd->{ascender}  //= $ff->ascender;
    $fd->{descender} //= $ff->descender;
    $fc->{$font} = $ff;
    return $ff;
}

sub xheight {
    $_[0]->data->{xheight};
}

sub bbextend {
    my ( $cur, $bb, $dx, $dy ) = @_;
    $dx //= 0;
    $dy //= 0;
    if ( defined $cur->[0] ) {
	$dx += $cur->[2];
	$dy += $cur->[3];
	$cur->[0] = $bb->[0] + $dx if $cur->[0] > $bb->[0] + $dx;
	$cur->[1] = $bb->[1] + $dy if $cur->[1] > $bb->[1] + $dy;
	$cur->[2] = $bb->[2] + $dx if $cur->[2] < $bb->[2] + $dx;
	$cur->[3] = $bb->[3] + $dy if $cur->[3] < $bb->[3] + $dy;
    }
    else {
	$cur->[0] = $bb->[0] + $dx;
	$cur->[1] = $bb->[1] + $dy;
	$cur->[2] = $bb->[2] + $dx;
	$cur->[3] = $bb->[3] + $dy;
    }
    return $cur;		# for convenience
}

################ Extensions to PDF::API2 ################

sub PDF::API2::Content::glyph_by_CId {
    my ( $self, $cid ) = @_;
    $self->add( sprintf("<%04x> Tj", $cid ) );
    $self->{' font'}->fontfile->subsetByCId($cid);
}

# HarfBuzz requires a TT/OT font. Define the fontfilename method only
# for classes that HarfBuzz can deal with.
sub PDF::API2::Resource::CIDFont::TrueType::fontfilename {
    my ( $self ) = @_;
    $self->fontfile->{' font'}->{' fname'};
}

# Add extents calculation for CIDfonts.
# Note: Origin is x=0 at the baseline.
sub PDF::API2::Resource::CIDFont::extents {
    my ( $self, $text, $size ) = @_;
    $size //= 1;
    my $e = $self->extents_cid( $self->cidsByStr($text), $size );
    return $e;
}

sub PDF::API2::Resource::CIDFont::extents_cid {
    my ( $self, $text, $size ) = @_;
    my $width = 0;
    my ( $xMin, $xMax, $yMin, $yMax, $bl );

    my $upem = $self->data->{upem};
    my $glyphs = $self->fontobj->{loca}->read->{glyphs};
    $bl = $self->ascender;
    my $lastglyph = 0;
    my $lastwidth;

    # Fun ahead! Widths are in 1000 and xMin and such in upem.
    # Scale to 1000ths.
    my $scale = 1000 / $upem;

    foreach my $n (unpack('n*', $text)) {
        $width += $lastwidth = $self->wxByCId($n);
        if ($self->{'-dokern'} and $self->haveKernPairs()) {
            if ($self->kernPairCid($lastglyph, $n)) {
                $width -= $self->kernPairCid($lastglyph, $n);
            }
        }
        $lastglyph = $n;
	my $ex = $glyphs->[$n];
	unless ( defined $ex && %$ex ) {
	    warn("Missing glyph: $n\n");
	    next;
	}
	$ex->read;

	my $e;
	# Copy while scaling.
	$e->{$_} = $ex->{$_} * $scale for qw( xMin yMin xMax yMax );

	printf STDERR ( "G  %3d  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f\n",
			$n, $lastwidth,
			@$e{ qw( xMin yMin xMax yMax ) } ) if 0;

	$xMin //= ($width - $lastwidth) + $e->{xMin};
	$yMin = $e->{yMin} if !defined($yMin) || $e->{yMin} < $yMin;
	$yMax = $e->{yMax} if !defined($yMax) || $e->{yMax} > $yMax;
	$xMax = ($width - $lastwidth) + $e->{xMax};
    }

    if ( defined $lastwidth ) {
#	$xMax += ($width - $lastwidth);
    }
    else {
	$xMin = $yMin = $xMax = $yMax = 0;
	$width = $self->missingwidth;
    }
    $_ = ($_//0)*$size/1000 for $xMin, $xMax, $yMin, $yMax, $bl;
    $_ = ($_//0)*$size/1000 for $width;

    return { x	     => $xMin,
	     y	     => $yMin,
	     width   => $xMax - $xMin,
	     height  => $yMax - $yMin,
	     # These are for convenience
	     xMin    => $xMin,
	     yMin    => $yMin,
	     xMax    => $xMax,
	     yMax    => $yMax,
	     wx	     => $width,
	     bl      => $bl,
	   };
}

################ Extensions to PDF::Builder ################

sub PDF::Builder::Content::glyph_by_CId {
    my ( $self, $cid ) = @_;
    $self->add( sprintf("<%04x> Tj", $cid ) );
    $self->{' font'}->fontfile->subsetByCId($cid);
}

# HarfBuzz requires a TT/OT font. Define the fontfilename method only
# for classes that HarfBuzz can deal with.
sub PDF::Builder::Resource::CIDFont::TrueType::fontfilename {
    my ( $self ) = @_;
    $self->fontfile->{' font'}->{' fname'};
}

################ For debugging/convenience ################

# Shows the bounding box of the last piece of text that was rendered.
sub showbb {
    my ( $self, $gfx, $x, $y, $col ) = @_;
    $x //= $self->{_lastx};
    $y //= $self->{_lasty};
    $col ||= "magenta";

    my ( $ink, $bb ) = $self->get_pixel_extents;
    my $bl = $bb->{bl};
    # Bounding box, top-left coordinates.
    printf( "Ink:    %6.2f %6.2f %6.2f %6.2f\n",
	    @$ink{qw( x y width height )} );
    printf( "Layout: %6.2f %6.2f %6.2f %6.2f  BL %.2f\n",
	    @$bb{qw( x y width height )}, $bl );

    # NOTE: Some fonts include natural spacing in the bounding box.
    # NOTE: Some fonts exclude accents on capitals from the bounding box.

    $gfx->save;
    $gfx->translate( $x, $y );

    # Show origin.
    _showloc($gfx);

    # Show baseline.
    _line( $gfx, $bb->{x}, -$bl, $bb->{width}, 0, $col );
    $gfx->restore;

    # Show layout box.
    $gfx->save;
    $gfx->linewidth( 0.25 );
    $gfx->strokecolor($col);
    $gfx->translate( $x, $y );
    for my $e ( $bb ) {
	$gfx->rect( @$e{ qw( x y width height ) } );
	$gfx->stroke;
    }
    $gfx->restore;

    # Show ink box.
    $gfx->save;
    $gfx->linewidth( 0.25 );
    $gfx->strokecolor("cyan");
    $gfx->translate( $x, $y );
    for my $e ( $ink ) {
	$gfx->rect( @$e{ qw( x y width height ) } );
	$gfx->stroke;
    }
    $gfx->restore;
}

sub _showloc {
    my ( $gfx, $x, $y, $d, $col ) = @_;
    $x ||= 0; $y ||= 0; $d ||= 50; $col ||= "blue";

    _line( $gfx, $x-$d, $y, 2*$d, 0, $col );
    _line( $gfx, $x, $y-$d, 0, 2*$d, $col );
}

sub _line {
    my ( $gfx, $x, $y, $w, $h, $col, $lw ) = @_;
    $col ||= "black";
    $lw ||= 0.5;

    $gfx->save;
    $gfx->move( $x, $y );
    $gfx->line( $x+$w, $y+$h );
    $gfx->linewidth($lw);
    $gfx->strokecolor($col);
    $gfx->stroke;
    $gfx->restore;
}

1;
