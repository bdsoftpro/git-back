use warnings;
use strict;

use Test::More;
use Test::Warnings;

use lib "t/lib";

BEGIN {
	use_ok('Test::MockModule') or BAIL_OUT "Could not load Test::MockModule. Giving up";
}

package Test_Package;
our $VERSION=1;
sub listify {
	my ($lower, $upper) = @_;
	return ($lower .. $upper);
}
package main;

# new()
ok(Test::MockModule->can('new'), 'new()');
eval {Test::MockModule->new('Test::MockModule')};
like($@, qr/Cannot mock Test::MockModule/, '... cannot mock itself');
eval {Test::MockModule->new('12Monkeys')};
like($@, qr/Invalid package name/, ' ... croaks if package looks invalid');
eval {Test::MockModule->new()};
like($@, qr/Invalid package name/, ' ... croaks if package is undefined');

{
	{
		Test::MockModule->new('ExampleModule', no_auto => 1);
		ok(!$INC{'ExampleModule.pm'}, '... no_auto prevents module being loaded');
	}

	my $mcgi = Test::MockModule->new('ExampleModule');
	ok($INC{'ExampleModule.pm'}, '... module loaded if !$VERSION');
	ok($mcgi->isa('Test::MockModule'), '... returns a Test::MockModule object');
	my $mcgi2 = Test::MockModule->new('ExampleModule');
	is($mcgi, $mcgi2,
		"... returns existing object if there's already one for the package");

	# get_package()
	ok($mcgi->can('get_package'), 'get_package');
	is($mcgi->get_package, 'ExampleModule', '... returns the package name');

	# mock()

	ok($mcgi->can('mock'), 'mock()');
	eval {$mcgi->mock(q[p-ram])};

	like($@, qr/Invalid subroutine name: /,
		'... dies if a subroutine name is invalid');

	my $orig_param = \&ExampleModule::param;
	$mcgi->mock('param', sub {return qw(abc def)});
	my @params = ExampleModule::param();
	is_deeply(\@params, ['abc', 'def'],
		'... replaces the subroutine with a mocked sub');

	$mcgi->mock('param' => undef);
	@params = ExampleModule::param();
	is_deeply(\@params, [], '... which is an empty sub if !defined');

	$mcgi->mock(param => 'The quick brown fox jumped over the lazy dog');
	my $a2z = ExampleModule::param();
	is($a2z, 'The quick brown fox jumped over the lazy dog',
		'... or a subroutine returning the supplied value');

	my $ref = [1,2,3];
	$mcgi->mock(param => $ref);
	@params = ExampleModule::param();
	is($params[0], $ref,
		'... given a reference, install a sub that returns said reference');

	my $blessed_code = bless sub { return 'Hello World' }, 'FOO';
	$mcgi->mock(param => $blessed_code);
	@params = ExampleModule::param();
	is($params[0], 'Hello World', '... a blessed coderef is properly detected');

	$mcgi->mock(Just => 'another', Perl => 'Hacker');
	@params = (ExampleModule::Just(), ExampleModule::Perl());
	is_deeply(\@params, ['another', 'Hacker'],
		'... can mock multiple subroutines at a time');


	# original()
	ok($mcgi->can('original'), 'original()');
	is($mcgi->original('param'), $orig_param,
		'... returns the original subroutine');
	my ($warn);
	local $SIG{__WARN__} = sub {$warn = shift};
	$mcgi->original('Vars');
	like($warn, qr/ is not mocked/, "... warns if a subroutine isn't mocked");

	# unmock()
	ok($mcgi->can('unmock'), 'unmock()');
	eval {$mcgi->unmock('V@rs')};
	like($@, qr/Invalid subroutine name/,
		'... dies if the subroutine is invalid');

	$warn = '';
	$mcgi->unmock('Vars');
	like($warn, qr/ was not mocked/, "... warns if a subroutine isn't mocked");

	$mcgi->unmock('param');
	is(\&{"ExampleModule::param"}, $orig_param, '... restores the original subroutine');

	# unmock_all()
	ok($mcgi->can('unmock_all'), 'unmock_all');
	$mcgi->mock('Vars' => sub {1}, param => sub {2});
	ok(ExampleModule::Vars() == 1 && ExampleModule::param() == 2,
		'mock: can mock multiple subroutines');
	my @orig = ($mcgi->original('Vars'), $mcgi->original('param'));
	$mcgi->unmock_all();
	ok(\&ExampleModule::Vars eq $orig[0] && \&ExampleModule::param eq $orig[1],
		'... removes all mocked subroutines');

	# is_mocked()
	ok($mcgi->can('is_mocked'), 'is_mocked');
	ok(!$mcgi->is_mocked('param'), '... returns false for non-mocked sub');
	$mcgi->mock('param', sub { return 'This sub is mocked' });
	is(ExampleModule::param(), 'This sub is mocked', '... mocked params');
	ok($mcgi->is_mocked('param'), '... returns true for non-mocked sub');

	# noop()
	is(ExampleModule::cookie(), 'choc-chip', 'cookie does default behaviour');
	$mcgi->noop('cookie');
	ok($mcgi->is_mocked('cookie'), 'cookie is mocked using noop');
	$mcgi->unmock('cookie');
	$mcgi->unmock('Vars');
	$mcgi->noop('cookie', 'Vars');
	is(ExampleModule::cookie(), 1, 'now cookie does nothing');
	is(ExampleModule::Vars(), 1, 'now Vars does nothing');
}

isnt(ExampleModule::param(), 'This sub is mocked',
	'... params is unmocked when object goes out of scope');

# test inherited methods
package Test_Parent;
sub method { 1 }
package Test_Child;
@Test_Child::ISA = 'Test_Parent';
package main;

my $test_mock = Test::MockModule->new('Test_Child', no_auto => 1);
ok(Test_Child->can('method'), 'test class inherits from parent');
$test_mock->mock('method' => sub {2});
is(Test_Child->method, 2, 'mocked subclass method');
$test_mock->unmock('method');
ok(Test_Child->can('method'), 'unmocked subclass method still exists');
is(Test_Child->method, 1, 'mocked subclass method');

# test restoring non-existant functions
$test_mock->mock(ISA => sub {'basic test'});
can_ok(Test_Child => 'ISA');
is(Test_Child::ISA(), 'basic test',
	"testing a mocked sub that didn't exist before");
$test_mock->unmock('ISA');
ok(!Test_Child->can('ISA') && $Test_Child::ISA[0] eq 'Test_Parent',
	"restoring an undefined sub doesn't clear out the rest of the symbols");

# ensure mocking CORE::GLOBAL works
ok(Test::MockModule->new("CORE::GLOBAL"));

done_testing;
