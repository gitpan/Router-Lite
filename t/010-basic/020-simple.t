#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Router::Lite');

ok(
  my $router = Router::Lite->new(),
  "Got router"
);

ok(
  $router->add_route(
    path  => '/foo/bar/',
    target  => "/foobar.asp",
  ),
  'Added simple route'
);
is(
  $router->match('/foo/bar/') => "/foobar.asp",
  'Matched /foo/bar/ -> /foobar.asp'
);


ok(
  $router->add_route(
    path      => '/topics/:topic',
    target    => '/my-topic.asp',
  ),
  'Added named parameter route'
);
is(
  $router->match('/topics/perl') => '/my-topic.asp?topic=perl',
  'Matched /topcis/perl -> /my-topic.asp?topic=perl'
);


ok(
  $router->add_route(
    path      => '/forum/:topic',
    target    => '/my-forum.asp?foo=bar',
    defaults  => { topic => 'yay' }
  ),
  'Added named parameter route'
);
is(
  $router->match('/forum/perl') => '/my-forum.asp?foo=bar&topic=perl',
  'Matched /forum/perl -> /my-forum.asp?foo=bar&topic=perl'
);


ok(
  $router->add_route(
    path      => '/products/{Category:.*}',
    target    => '/product.asp',
    defaults  => { Category => "All" }
  ),
  "Added route '/products/:Category'"
);


ok(
  my $route = $router->match('/products/'),
  "Matched '/products/'"
);

is(
  $route => '/product.asp?Category=All',
  '$route looks right (All)'
);
is(
  $router->match('/products/Trucks/') => '/product.asp?Category=Trucks',
  '$route looks right (Trucks) A'
);
is(
  $router->match('/products/Trucks') => '/product.asp?Category=Trucks',
  '$route looks right (Trucks) B'
);


$router->add_route(
  path    => '/zipcode/{zip:[0-9]{5,5}}/',
  target  => '/zipcode.asp'
);

is(
  $router->match('/zipcode/90210/') => '/zipcode.asp?zip=90210',
  '$route looks right (zip) A'
);
is(
  $router->match('/zipcode/') => undef,
  '$route looks right (zip) B'
);

for(1..1_000_000)
{
  # Typo is intentional:
  my $route = $router->match('/producdts/');
}

