package File::Size;
 
use 5.006;
use warnings;
use strict;
use File::Find;
use Cwd;
use Number::Bytes::Human qw( format_bytes );
no warnings 'File::Find';
our $VERSION = '0.06';
 

 
my $followsymlinks = 0;
my $blocksize = 0;
my $size = 0;
 
sub new {
        my $class = shift;      
        my %options = @_;
        my $self = \%options;
        bless( $self, $class );
        return $self;
}
 
sub DESTROY {
        my $self = shift;
        undef( $self );
}
 
sub setdir {
        my $self = shift;
        $$self{ 'dir' } = shift || return $$self{ 'dir' };
        return $self;
}
 
sub setblocksize {
        my $self = shift;
        $$self{ 'blocksize' } = shift || return $$self{ 'blocksize' };
        return $self;
}
 
sub setfollowsymlinks {
        my $self = shift;
        $$self{ 'followsymlinks' } = shift || return $$self{ 'followsymlinks' };
        return $self;
}
 
sub sethumanreadable {
        my $self = shift;
        $$self{ 'humanreadable' } = shift || return $$self{ 'humanreadable' };
        return $self;
}
 
sub getsize {
        my $self = shift;
        my %options;
        if ( $$self{ 'followsymlinks' } ) {
                %options = (
                        wanted          => \&_findcb,
                        follow          => 1,        # follow symlinks
                        follow_skip => 2     # skip duplicate links, but don't die doing it
                );
        } else {
                %options = (
                        wanted          => \&_findcb
                );
        }
        my $dir = $$self{ 'dir' } || getcwd();
        my $blocksize = $$self{ 'blocksize' } || 1;
        $size = 0; # reset the size counter
        find( \%options, $dir );
        return $$self{ 'humanreadable' } ? format_bytes( $size ) : sprintf( '%d', $size / $blocksize );
}
 
sub _findcb {
        $size += -s $File::Find::name || 0;
}
 
1;
