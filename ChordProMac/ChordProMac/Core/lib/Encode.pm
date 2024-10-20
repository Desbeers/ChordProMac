#line 1 "<embedded>/Encode.pm"
#
# $Id: Encode.pm,v 3.19 2022/08/04 04:42:30 dankogai Exp $
#
package Encode;
use strict;
use warnings;
use constant DEBUG => !!$ENV{PERL_ENCODE_DEBUG};
our $VERSION;
BEGIN {
    $VERSION = sprintf "%d.%02d", q$Revision: 3.19 $ =~ /(\d+)/g;
    require XSLoader;
    XSLoader::load( __PACKAGE__, $VERSION );
}

use Exporter 5.57 'import';

use Carp ();
our @CARP_NOT = qw(Encode::Encoder);

# Public, encouraged API is exported by default

our @EXPORT = qw(
  decode  decode_utf8  encode  encode_utf8 str2bytes bytes2str
  encodings  find_encoding find_mime_encoding clone_encoding
);
our @FB_FLAGS = qw(
  DIE_ON_ERR WARN_ON_ERR RETURN_ON_ERR LEAVE_SRC
  PERLQQ HTMLCREF XMLCREF STOP_AT_PARTIAL
);
our @FB_CONSTS = qw(
  FB_DEFAULT FB_CROAK FB_QUIET FB_WARN
  FB_PERLQQ FB_HTMLCREF FB_XMLCREF
);
our @EXPORT_OK = (
    qw(
      _utf8_off _utf8_on define_encoding from_to is_16bit is_8bit
      is_utf8 perlio_ok resolve_alias utf8_downgrade utf8_upgrade
      ),
    @FB_FLAGS, @FB_CONSTS,
);

our %EXPORT_TAGS = (
    all          => [ @EXPORT,    @EXPORT_OK ],
    default      => [ @EXPORT ],
    fallbacks    => [ @FB_CONSTS ],
    fallback_all => [ @FB_CONSTS, @FB_FLAGS ],
);

# Documentation moved after __END__ for speed - NI-S

our $ON_EBCDIC = ( ord("A") == 193 );

use Encode::Alias ();
use Encode::MIME::Name;

use Storable;

# Make a %Encoding package variable to allow a certain amount of cheating
our %Encoding;
our %ExtModule;
require Encode::Config;
#  See
#  https://bugzilla.redhat.com/show_bug.cgi?id=435505#c2
#  to find why sig handlers inside eval{} are disabled.
eval {
    local $SIG{__DIE__};
    local $SIG{__WARN__};
    local @INC = @INC;
    pop @INC if @INC && $INC[-1] eq '.';
    require Encode::ConfigLocal;
};

sub encodings {
    my %enc;
    my $arg  = $_[1] || '';
    if ( $arg eq ":all" ) {
        %enc = ( %Encoding, %ExtModule );
    }
    else {
        %enc = %Encoding;
        for my $mod ( map { m/::/ ? $_ : "Encode::$_" } @_ ) {
            DEBUG and warn $mod;
            for my $enc ( keys %ExtModule ) {
                $ExtModule{$enc} eq $mod and $enc{$enc} = $mod;
            }
        }
    }
    return sort { lc $a cmp lc $b }
      grep      { !/^(?:Internal|Unicode|Guess)$/o } keys %enc;
}

sub perlio_ok {
    my $obj = ref( $_[0] ) ? $_[0] : find_encoding( $_[0] );
    $obj->can("perlio_ok") and return $obj->perlio_ok();
    return 0;    # safety net
}

sub define_encoding {
    my $obj  = shift;
    my $name = shift;
    $Encoding{$name} = $obj;
    my $lc = lc($name);
    define_alias( $lc => $obj ) unless $lc eq $name;
    while (@_) {
        my $alias = shift;
        define_alias( $alias, $obj );
    }
    my $class = ref($obj);
    push @Encode::CARP_NOT, $class unless grep { $_ eq $class } @Encode::CARP_NOT;
    push @Encode::Encoding::CARP_NOT, $class unless grep { $_ eq $class } @Encode::Encoding::CARP_NOT;
    return $obj;
}

sub getEncoding {
    my ( $class, $name, $skip_external ) = @_;

    defined($name) or return;

    $name =~ s/\s+//g; # https://rt.cpan.org/Ticket/Display.html?id=65796

    ref($name) && $name->can('renew') and return $name;
    exists $Encoding{$name} and return $Encoding{$name};
    my $lc = lc $name;
    exists $Encoding{$lc} and return $Encoding{$lc};

    my $oc = $class->find_alias($name);
    defined($oc) and return $oc;
    $lc ne $name and $oc = $class->find_alias($lc);
    defined($oc) and return $oc;

    unless ($skip_external) {
        if ( my $mod = $ExtModule{$name} || $ExtModule{$lc} ) {
            $mod =~ s,::,/,g;
            $mod .= '.pm';
            eval { require $mod; };
            exists $Encoding{$name} and return $Encoding{$name};
        }
    }
    return;
}

# HACK: These two functions must be defined in Encode and because of
# cyclic dependency between Encode and Encode::Alias, Exporter does not work
sub find_alias {
    goto &Encode::Alias::find_alias;
}
sub define_alias {
    goto &Encode::Alias::define_alias;
}

sub find_encoding($;$) {
    my ( $name, $skip_external ) = @_;
    return __PACKAGE__->getEncoding( $name, $skip_external );
}

sub find_mime_encoding($;$) {
    my ( $mime_name, $skip_external ) = @_;
    my $name = Encode::MIME::Name::get_encode_name( $mime_name );
    return find_encoding( $name, $skip_external );
}

sub resolve_alias($) {
    my $obj = find_encoding(shift);
    defined $obj and return $obj->name;
    return;
}

sub clone_encoding($) {
    my $obj = find_encoding(shift);
    ref $obj or return;
    return Storable::dclone($obj);
}

onBOOT;

if ($ON_EBCDIC) {
    package Encode::UTF_EBCDIC;
    use parent 'Encode::Encoding';
    my $obj = bless { Name => "UTF_EBCDIC" } => "Encode::UTF_EBCDIC";
    Encode::define_encoding($obj, 'Unicode');
    sub decode {
        my ( undef, $str, $chk ) = @_;
        my $res = '';
        for ( my $i = 0 ; $i < length($str) ; $i++ ) {
            $res .=
              chr(
                utf8::unicode_to_native( ord( substr( $str, $i, 1 ) ) )
              );
        }
        $_[1] = '' if $chk;
        return $res;
    }
    sub encode {
        my ( undef, $str, $chk ) = @_;
        my $res = '';
        for ( my $i = 0 ; $i < length($str) ; $i++ ) {
            $res .=
              chr(
                utf8::native_to_unicode( ord( substr( $str, $i, 1 ) ) )
              );
        }
        $_[1] = '' if $chk;
        return $res;
    }
}

{
    # https://rt.cpan.org/Public/Bug/Display.html?id=103253
    package Encode::XS;
    use parent 'Encode::Encoding';
}

{
    package Encode::utf8;
    use parent 'Encode::Encoding';
    my %obj = (
        'utf8'         => { Name => 'utf8' },
        'utf-8-strict' => { Name => 'utf-8-strict', strict_utf8 => 1 }
    );
    for ( keys %obj ) {
        bless $obj{$_} => __PACKAGE__;
        Encode::define_encoding( $obj{$_} => $_ );
    }
    sub cat_decode {
        # ($obj, $dst, $src, $pos, $trm, $chk)
        # currently ignores $chk
        my ( undef, undef, undef, $pos, $trm ) = @_;
        my ( $rdst, $rsrc, $rpos ) = \@_[ 1, 2, 3 ];
        use bytes;
        if ( ( my $npos = index( $$rsrc, $trm, $pos ) ) >= 0 ) {
            $$rdst .=
              substr( $$rsrc, $pos, $npos - $pos + length($trm) );
            $$rpos = $npos + length($trm);
            return 1;
        }
        $$rdst .= substr( $$rsrc, $pos );
        $$rpos = length($$rsrc);
        return '';
    }
}

1;

__END__

#line 977
