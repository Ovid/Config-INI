#!/usr/bin/env perl6
# vim:ft=perl6

use v6;
use Test;

use Config::INI;

ok my Config::INI $config .= new, 'We can create Config::Tiny objects';
ok $config.can('read'), 'We should have a read() method';

ok $config.can('add_properties'), 'We should be able to add a config section';

my %properties = (
    this => 'that',
    foo  => 'bar',
);
ok $config.add_properties(:%properties), '... and we should be able to add properties';

ok $config.can('properties'), 'We should be able to fetch properties';
is_deeply $config.properties, %properties, 
    '... and they should be the correct properties';

%properties = (
    one => 'uno',
    two => 'dos',
);

ok $config.add_properties( name => 'spanish', :%properties), 
    'We should be able to add named properties';
is_deeply $config.properties('spanish'), %properties,
    '... and fetch them by name';

my $text = Q{
uno=dos
tres = quatro
[ foo bar  ] 
this=that

 one = two 
  # ignore this
   ; and this

};

ok $config.can('read_string'), 'We should have a method to read a config string';
ok $config.read_string($text), '... and it should successfully read a config string';
is_deeply $config.properties, { uno => 'dos', tres => 'quatro' },
    '... and the root properties should be correct';
is_deeply $config.properties('foo bar'), { this => 'that', one => 'two' },
    '... as should the named properties';

dies_ok { $config.read('no_such_file') },
    'We should die if we try to read a non-existent file';
ok $config.read('t/config.txt'), 'We should be able to read a file';
is_deeply $config.properties, 
    { port => "3333", host => "http://localhost/" },
    '... and root properties should be read correctly';
is_deeply $config.properties('admin'),
    { access => 'all', name => 'Administrator' },
    '... as should named properties';
dies_ok { $config.properties('none') },
    '... but it should die if we try to fetch unknown properties';

done_testing;
