use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.007005
use Test::Spelling 0.12;
use Pod::Wordlist;


add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( examples lib script t xt ) );
__DATA__
Etheridge
Graham
Karen
Knop
Leon
Sinan
Test
Timmermans
Unur
Warnings
ether
fawaka
haarg
irc
lib
nanis
