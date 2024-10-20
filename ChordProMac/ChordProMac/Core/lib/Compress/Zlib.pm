#line 1 "<embedded>/Compress/Zlib.pm"

package Compress::Zlib;

require 5.006 ;
require Exporter;
use Carp ;
use IO::Handle ;
use Scalar::Util qw(dualvar);

use IO::Compress::Base::Common 2.204 ;
use Compress::Raw::Zlib 2.204 ;
use IO::Compress::Gzip 2.204 ;
use IO::Uncompress::Gunzip 2.204 ;

use strict ;
use warnings ;
use bytes ;
our ($VERSION, $XS_VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

$VERSION = '2.204';
$XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
        deflateInit inflateInit

        compress uncompress

        gzopen $gzerrno
    );

push @EXPORT, @Compress::Raw::Zlib::EXPORT ;

@EXPORT_OK = qw(memGunzip memGzip zlib_version);
%EXPORT_TAGS = (
    ALL         => \@EXPORT
);

BEGIN
{
    *zlib_version = \&Compress::Raw::Zlib::zlib_version;
}

use constant FLAG_APPEND             => 1 ;
use constant FLAG_CRC                => 2 ;
use constant FLAG_ADLER              => 4 ;
use constant FLAG_CONSUME_INPUT      => 8 ;

our (@my_z_errmsg);

@my_z_errmsg = (
    "need dictionary",     # Z_NEED_DICT     2
    "stream end",          # Z_STREAM_END    1
    "",                    # Z_OK            0
    "file error",          # Z_ERRNO        (-1)
    "stream error",        # Z_STREAM_ERROR (-2)
    "data error",          # Z_DATA_ERROR   (-3)
    "insufficient memory", # Z_MEM_ERROR    (-4)
    "buffer error",        # Z_BUF_ERROR    (-5)
    "incompatible version",# Z_VERSION_ERROR(-6)
    );


sub _set_gzerr
{
    my $value = shift ;

    if ($value == 0) {
        $Compress::Zlib::gzerrno = 0 ;
    }
    elsif ($value == Z_ERRNO() || $value > 2) {
        $Compress::Zlib::gzerrno = $! ;
    }
    else {
        $Compress::Zlib::gzerrno = dualvar($value+0, $my_z_errmsg[2 - $value]);
    }

    return $value ;
}

sub _set_gzerr_undef
{
    _set_gzerr(@_);
    return undef;
}

sub _save_gzerr
{
    my $gz = shift ;
    my $test_eof = shift ;

    my $value = $gz->errorNo() || 0 ;
    my $eof = $gz->eof() ;

    if ($test_eof) {
        # gzread uses Z_STREAM_END to denote a successful end
        $value = Z_STREAM_END() if $gz->eof() && $value == 0 ;
    }

    _set_gzerr($value) ;
}

sub gzopen($$)
{
    my ($file, $mode) = @_ ;

    my $gz ;
    my %defOpts = (Level    => Z_DEFAULT_COMPRESSION(),
                   Strategy => Z_DEFAULT_STRATEGY(),
                  );

    my $writing ;
    $writing = ! ($mode =~ /r/i) ;
    $writing = ($mode =~ /[wa]/i) ;

    $defOpts{Level}    = $1               if $mode =~ /(\d)/;
    $defOpts{Strategy} = Z_FILTERED()     if $mode =~ /f/i;
    $defOpts{Strategy} = Z_HUFFMAN_ONLY() if $mode =~ /h/i;
    $defOpts{Append}   = 1                if $mode =~ /a/i;

    my $infDef = $writing ? 'deflate' : 'inflate';
    my @params = () ;

    croak "gzopen: file parameter is not a filehandle or filename"
        unless isaFilehandle $file || isaFilename $file  ||
               (ref $file && ref $file eq 'SCALAR');

    return undef unless $mode =~ /[rwa]/i ;

    _set_gzerr(0) ;

    if ($writing) {
        $gz = IO::Compress::Gzip->new($file, Minimal => 1, AutoClose => 1,
                                     %defOpts)
            or $Compress::Zlib::gzerrno = $IO::Compress::Gzip::GzipError;
    }
    else {
        $gz = IO::Uncompress::Gunzip->new($file,
                                         Transparent => 1,
                                         Append => 0,
                                         AutoClose => 1,
                                         MultiStream => 1,
                                         Strict => 0)
            or $Compress::Zlib::gzerrno = $IO::Uncompress::Gunzip::GunzipError;
    }

    return undef
        if ! defined $gz ;

    bless [$gz, $infDef], 'Compress::Zlib::gzFile';
}

sub Compress::Zlib::gzFile::gzread
{
    my $self = shift ;

    return _set_gzerr(Z_STREAM_ERROR())
        if $self->[1] ne 'inflate';

    my $len = defined $_[1] ? $_[1] : 4096 ;

    my $gz = $self->[0] ;
    if ($self->gzeof() || $len == 0) {
        # Zap the output buffer to match ver 1 behaviour.
        $_[0] = "" ;
        _save_gzerr($gz, 1);
        return 0 ;
    }

    my $status = $gz->read($_[0], $len) ;
    _save_gzerr($gz, 1);
    return $status ;
}

sub Compress::Zlib::gzFile::gzreadline
{
    my $self = shift ;

    my $gz = $self->[0] ;
    {
        # Maintain backward compatibility with 1.x behaviour
        # It didn't support $/, so this can't either.
        local $/ = "\n" ;
        $_[0] = $gz->getline() ;
    }
    _save_gzerr($gz, 1);
    return defined $_[0] ? length $_[0] : 0 ;
}

sub Compress::Zlib::gzFile::gzwrite
{
    my $self = shift ;
    my $gz = $self->[0] ;

    return _set_gzerr(Z_STREAM_ERROR())
        if $self->[1] ne 'deflate';

    $] >= 5.008 and (utf8::downgrade($_[0], 1)
        or croak "Wide character in gzwrite");

    my $status = $gz->write($_[0]) ;
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gztell
{
    my $self = shift ;
    my $gz = $self->[0] ;
    my $status = $gz->tell() ;
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzseek
{
    my $self   = shift ;
    my $offset = shift ;
    my $whence = shift ;

    my $gz = $self->[0] ;
    my $status ;
    eval { local $SIG{__DIE__}; $status = $gz->seek($offset, $whence) ; };
    if ($@)
    {
        my $error = $@;
        $error =~ s/^.*: /gzseek: /;
        $error =~ s/ at .* line \d+\s*$//;
        croak $error;
    }
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzflush
{
    my $self = shift ;
    my $f    = shift ;

    my $gz = $self->[0] ;
    my $status = $gz->flush($f) ;
    my $err = _save_gzerr($gz);
    return $status ? 0 : $err;
}

sub Compress::Zlib::gzFile::gzclose
{
    my $self = shift ;
    my $gz = $self->[0] ;

    my $status = $gz->close() ;
    my $err = _save_gzerr($gz);
    return $status ? 0 : $err;
}

sub Compress::Zlib::gzFile::gzeof
{
    my $self = shift ;
    my $gz = $self->[0] ;

    return 0
        if $self->[1] ne 'inflate';

    my $status = $gz->eof() ;
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzsetparams
{
    my $self = shift ;
    croak "Usage: Compress::Zlib::gzFile::gzsetparams(file, level, strategy)"
        unless @_ eq 2 ;

    my $gz = $self->[0] ;
    my $level = shift ;
    my $strategy = shift;

    return _set_gzerr(Z_STREAM_ERROR())
        if $self->[1] ne 'deflate';

    my $status = *$gz->{Compress}->deflateParams(-Level   => $level,
                                                -Strategy => $strategy);
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzerror
{
    my $self = shift ;
    my $gz = $self->[0] ;

    return $Compress::Zlib::gzerrno ;
}


sub compress($;$)
{
    my ($x, $output, $err, $in) =('', '', '', '') ;

    if (ref $_[0] ) {
        $in = $_[0] ;
        croak "not a scalar reference" unless ref $in eq 'SCALAR' ;
    }
    else {
        $in = \$_[0] ;
    }

    $] >= 5.008 and (utf8::downgrade($$in, 1)
        or croak "Wide character in compress");

    my $level = (@_ == 2 ? $_[1] : Z_DEFAULT_COMPRESSION() );

    $x = Compress::Raw::Zlib::_deflateInit(FLAG_APPEND,
                                           $level,
                                           Z_DEFLATED,
                                           MAX_WBITS,
                                           MAX_MEM_LEVEL,
                                           Z_DEFAULT_STRATEGY,
                                           4096,
                                           '')
            or return undef ;

    $err = $x->deflate($in, $output) ;
    return undef unless $err == Z_OK() ;

    $err = $x->flush($output) ;
    return undef unless $err == Z_OK() ;

    return $output ;
}

sub uncompress($)
{
    my ($output, $in) =('', '') ;

    if (ref $_[0] ) {
        $in = $_[0] ;
        croak "not a scalar reference" unless ref $in eq 'SCALAR' ;
    }
    else {
        $in = \$_[0] ;
    }

    $] >= 5.008 and (utf8::downgrade($$in, 1)
        or croak "Wide character in uncompress");

    my ($obj, $status) = Compress::Raw::Zlib::_inflateInit(0,
                                MAX_WBITS, 4096, "") ;

    $status == Z_OK
        or return undef;

    $obj->inflate($in, $output) == Z_STREAM_END
        or return undef;

    return $output;
}

sub deflateInit(@)
{
    my ($got) = ParseParameters(0,
                {
                'bufsize'       => [IO::Compress::Base::Common::Parse_unsigned, 4096],
                'level'         => [IO::Compress::Base::Common::Parse_signed,   Z_DEFAULT_COMPRESSION()],
                'method'        => [IO::Compress::Base::Common::Parse_unsigned, Z_DEFLATED()],
                'windowbits'    => [IO::Compress::Base::Common::Parse_signed,   MAX_WBITS()],
                'memlevel'      => [IO::Compress::Base::Common::Parse_unsigned, MAX_MEM_LEVEL()],
                'strategy'      => [IO::Compress::Base::Common::Parse_unsigned, Z_DEFAULT_STRATEGY()],
                'dictionary'    => [IO::Compress::Base::Common::Parse_any,      ""],
                }, @_ ) ;

    croak "Compress::Zlib::deflateInit: Bufsize must be >= 1, you specified " .
            $got->getValue('bufsize')
        unless $got->getValue('bufsize') >= 1;

    my $obj ;

    my $status = 0 ;
    ($obj, $status) =
      Compress::Raw::Zlib::_deflateInit(0,
                $got->getValue('level'),
                $got->getValue('method'),
                $got->getValue('windowbits'),
                $got->getValue('memlevel'),
                $got->getValue('strategy'),
                $got->getValue('bufsize'),
                $got->getValue('dictionary')) ;

    my $x = ($status == Z_OK() ? bless $obj, "Zlib::OldDeflate"  : undef) ;
    return wantarray ? ($x, $status) : $x ;
}

sub inflateInit(@)
{
    my ($got) = ParseParameters(0,
                {
                'bufsize'       => [IO::Compress::Base::Common::Parse_unsigned, 4096],
                'windowbits'    => [IO::Compress::Base::Common::Parse_signed,   MAX_WBITS()],
                'dictionary'    => [IO::Compress::Base::Common::Parse_any,      ""],
                }, @_) ;


    croak "Compress::Zlib::inflateInit: Bufsize must be >= 1, you specified " .
            $got->getValue('bufsize')
        unless $got->getValue('bufsize') >= 1;

    my $status = 0 ;
    my $obj ;
    ($obj, $status) = Compress::Raw::Zlib::_inflateInit(FLAG_CONSUME_INPUT,
                                $got->getValue('windowbits'),
                                $got->getValue('bufsize'),
                                $got->getValue('dictionary')) ;

    my $x = ($status == Z_OK() ? bless $obj, "Zlib::OldInflate"  : undef) ;

    wantarray ? ($x, $status) : $x ;
}

package Zlib::OldDeflate ;

our (@ISA);
@ISA = qw(Compress::Raw::Zlib::deflateStream);


sub deflate
{
    my $self = shift ;
    my $output ;

    my $status = $self->SUPER::deflate($_[0], $output) ;
    wantarray ? ($output, $status) : $output ;
}

sub flush
{
    my $self = shift ;
    my $output ;
    my $flag = shift || Compress::Zlib::Z_FINISH();
    my $status = $self->SUPER::flush($output, $flag) ;

    wantarray ? ($output, $status) : $output ;
}

package Zlib::OldInflate ;

our (@ISA);
@ISA = qw(Compress::Raw::Zlib::inflateStream);

sub inflate
{
    my $self = shift ;
    my $output ;
    my $status = $self->SUPER::inflate($_[0], $output) ;
    wantarray ? ($output, $status) : $output ;
}

package Compress::Zlib ;

use IO::Compress::Gzip::Constants 2.204 ;

sub memGzip($)
{
    _set_gzerr(0);
    my $x = Compress::Raw::Zlib::_deflateInit(FLAG_APPEND|FLAG_CRC,
                                           Z_BEST_COMPRESSION,
                                           Z_DEFLATED,
                                           -MAX_WBITS(),
                                           MAX_MEM_LEVEL,
                                           Z_DEFAULT_STRATEGY,
                                           4096,
                                           '')
            or return undef ;

    # if the deflation buffer isn't a reference, make it one
    my $string = (ref $_[0] ? $_[0] : \$_[0]) ;

    $] >= 5.008 and (utf8::downgrade($$string, 1)
        or croak "Wide character in memGzip");

    my $out;
    my $status ;

    $x->deflate($string, $out) == Z_OK
        or return undef ;

    $x->flush($out) == Z_OK
        or return undef ;

    return IO::Compress::Gzip::Constants::GZIP_MINIMUM_HEADER .
           $out .
           pack("V V", $x->crc32(), $x->total_in());
}


sub _removeGzipHeader($)
{
    my $string = shift ;

    return Z_DATA_ERROR()
        if length($$string) < GZIP_MIN_HEADER_SIZE ;

    my ($magic1, $magic2, $method, $flags, $time, $xflags, $oscode) =
        unpack ('CCCCVCC', $$string);

    return Z_DATA_ERROR()
        unless $magic1 == GZIP_ID1 and $magic2 == GZIP_ID2 and
           $method == Z_DEFLATED() and !($flags & GZIP_FLG_RESERVED) ;
    substr($$string, 0, GZIP_MIN_HEADER_SIZE) = '' ;

    # skip extra field
    if ($flags & GZIP_FLG_FEXTRA)
    {
        return Z_DATA_ERROR()
            if length($$string) < GZIP_FEXTRA_HEADER_SIZE ;

        my ($extra_len) = unpack ('v', $$string);
        $extra_len += GZIP_FEXTRA_HEADER_SIZE;
        return Z_DATA_ERROR()
            if length($$string) < $extra_len ;

        substr($$string, 0, $extra_len) = '';
    }

    # skip orig name
    if ($flags & GZIP_FLG_FNAME)
    {
        my $name_end = index ($$string, GZIP_NULL_BYTE);
        return Z_DATA_ERROR()
           if $name_end == -1 ;
        substr($$string, 0, $name_end + 1) =  '';
    }

    # skip comment
    if ($flags & GZIP_FLG_FCOMMENT)
    {
        my $comment_end = index ($$string, GZIP_NULL_BYTE);
        return Z_DATA_ERROR()
            if $comment_end == -1 ;
        substr($$string, 0, $comment_end + 1) = '';
    }

    # skip header crc
    if ($flags & GZIP_FLG_FHCRC)
    {
        return Z_DATA_ERROR()
            if length ($$string) < GZIP_FHCRC_SIZE ;
        substr($$string, 0, GZIP_FHCRC_SIZE) = '';
    }

    return Z_OK();
}

sub _ret_gun_error
{
    $Compress::Zlib::gzerrno = $IO::Uncompress::Gunzip::GunzipError;
    return undef;
}


sub memGunzip($)
{
    # if the buffer isn't a reference, make it one
    my $string = (ref $_[0] ? $_[0] : \$_[0]);

    $] >= 5.008 and (utf8::downgrade($$string, 1)
        or croak "Wide character in memGunzip");

    _set_gzerr(0);

    my $status = _removeGzipHeader($string) ;
    $status == Z_OK()
        or return _set_gzerr_undef($status);

    my $bufsize = length $$string > 4096 ? length $$string : 4096 ;
    my $x = Compress::Raw::Zlib::_inflateInit(FLAG_CRC | FLAG_CONSUME_INPUT,
                                -MAX_WBITS(), $bufsize, '')
              or return _ret_gun_error();

    my $output = '' ;
    $status = $x->inflate($string, $output);

    if ( $status == Z_OK() )
    {
        _set_gzerr(Z_DATA_ERROR());
        return undef;
    }

    return _ret_gun_error()
        if ($status != Z_STREAM_END());

    if (length $$string >= 8)
    {
        my ($crc, $len) = unpack ("VV", substr($$string, 0, 8));
        substr($$string, 0, 8) = '';
        return _set_gzerr_undef(Z_DATA_ERROR())
            unless $len == length($output) and
                   $crc == Compress::Raw::Zlib::crc32($output);
    }
    else
    {
        $$string = '';
    }

    return $output;
}

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__


#line 1516