#line 1 "<embedded>/PAR/SetupTemp.pm"
package PAR::SetupTemp;
$PAR::SetupTemp::VERSION = '1.002';

use 5.008009;
use strict;
use warnings;

use Fcntl ':mode';

use PAR::SetupProgname;

#line 31

# for PAR internal use only!
our $PARTemp;

# name of the canary file
our $Canary = "_CANARY_.txt";
# how much to "date back" the canary file (in seconds)
our $CanaryDateBack = 24 * 3600;        # 1 day

# The C version of this code appears in myldr/mktmpdir.c
# This code also lives in PAR::Packer's par.pl as _set_par_temp!
sub set_par_temp_env {
    PAR::SetupProgname::set_progname()
      unless defined $PAR::SetupProgname::Progname;

    if (defined $ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/) {
        $PARTemp = $1;
        return;
    }

    my $stmpdir = _get_par_user_tempdir();
    die "unable to create cache directory" unless $stmpdir;

    require File::Spec;
      if (!$ENV{PAR_CLEAN} and my $mtime = (stat($PAR::SetupProgname::Progname))[9]) {
          require Digest::SHA;
          my $ctx = Digest::SHA->new(1);

          if ($ctx and open(my $fh, "<$PAR::SetupProgname::Progname")) {
              binmode($fh);
              $ctx->addfile($fh);
              close($fh);
          }

          $stmpdir = File::Spec->catdir(
              $stmpdir,
              "cache-" . ( $ctx ? $ctx->hexdigest : $mtime )
          );
      }
      else {
          $ENV{PAR_CLEAN} = 1;
          $stmpdir = File::Spec->catdir($stmpdir, "temp-$$");
      }

      $ENV{PAR_TEMP} = $stmpdir;
    mkdir $stmpdir, 0700;

    $PARTemp = $1 if defined $ENV{PAR_TEMP} and $ENV{PAR_TEMP} =~ /(.+)/;
}

# Find any digester
# Used in PAR::Repository::Client!
sub _get_digester {
  my $ctx = eval { require Digest::SHA; Digest::SHA->new(1) }
         || eval { require Digest::SHA1; Digest::SHA1->new }
         || eval { require Digest::MD5; Digest::MD5->new };
  return $ctx;
}

# find the per-user temporary directory (eg /tmp/par-$USER)
# Used in PAR::Repository::Client!
sub _get_par_user_tempdir {
  my $username = _find_username();
  my $temp_path;
  foreach my $path (
    (map $ENV{$_}, qw( PAR_TMPDIR TMPDIR TEMPDIR TEMP TMP )),
      qw( C:\\TEMP /tmp . )
  ) {
    next unless defined $path and -d $path and -w $path;
    # create a temp directory that is unique per user
    # NOTE: $username may be in an unspecified charset/encoding;
    # use a name that hopefully works for all of them;
    # also avoid problems with platform-specific meta characters in the name
    $temp_path = File::Spec->catdir($path, "par-".unpack("H*", $username));
    ($temp_path) = $temp_path =~ /^(.*)$/s;
    unless (mkdir($temp_path, 0700) || $!{EEXIST}) {
      warn "creation of private subdirectory $temp_path failed (errno=$!)"; 
      return;
    }

    unless ($^O eq 'MSWin32') {
        my @st;
        unless (@st = lstat($temp_path)) {
          warn "stat of private subdirectory $temp_path failed (errno=$!)";
          return;
        }
        if (!S_ISDIR($st[2])
            || $st[4] != $<
            || ($st[2] & 0777) != 0700 ) {
          warn "private subdirectory $temp_path is unsafe (please remove it and retry your operation)";
          return;
        }
    }

    last;
  }
  return $temp_path;
}

# tries hard to find out the name of the current user
sub _find_username {
  my $username;
  my $pwuid;
  # does not work everywhere:
  eval {($pwuid) = getpwuid($>) if defined $>;};

  if ( defined(&Win32::LoginName) ) {
    $username = &Win32::LoginName;
  }
  elsif (defined $pwuid) {
    $username = $pwuid;
  }
  else {
    $username = $ENV{USERNAME} || $ENV{USER} || 'SYSTEM';
  }

  return $username;
}

1;

__END__

#line 185

