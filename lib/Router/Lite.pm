
package Router::Lite;

use strict;
use warnings 'all';
use Carp 'confess';

our $VERSION = '0.001_01';

sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    cache   => { },
    routes  => [ ],
    %args
  }, $class;
  
  $s->init();
  
  return $s;
}# end new()

sub init { }


sub add_route
{
  my ($s, %args) = @_;
  
  # Validate the args:
  foreach my $el (qw( path ))
  {
    confess "Required param '$el' was not provided"
      unless defined($args{$el}) && length($args{$el});
    confess "$el: '$args{$el}' is already in use"
      if grep { $_->{$el} eq $args{$el} } @{$s->{routes}};
  }# end foreach()
  
  $args{defaults} ||= { };
  
  # Fixup our pattern:
  ($args{regexp}, $args{captures}) = $s->_patternize( $args{path} );
  
  push @{$s->{routes}}, \%args;
  
  return 1;
}# end add_route()


sub _patternize
{
  my ($s, $pattern) = @_;
  
  # Parse the string, which can include any combination of the following:
  # /literal/:name/{zipcode:{[0-9]{5,5}}}/*/:*restOfPath
  my @captures = ( );
  my $regexp = do {
    $pattern =~ s!
      \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
      :([A-Za-z0-9_]+)              | # /blog/:year
      (\*)                          | # /blog/*/*
      ([^{:*]+)                       # normal string
    !
      if( $1 )
      {
        my ($name, $pattern) = split /:/, $1;
        push @captures, $name;
        $pattern ? "($pattern)" : "([^/]+)";
      }
      elsif( $2 )
      {
        push @captures, $2;
        "([^/]+)";
      }
      elsif( $3 )
      {
        push @captures, '__splat__';
        "(.+)";
      }
      elsif( $4 )
      {
        quotemeta($4);
      }# end if()
    !esxg;
    qr{^$pattern$};
  };

  return ( $regexp, \@captures );
}# end _patternize()


sub match
{
  my ($s, $uri) = @_;
  
  ($uri) = split /\?/, $uri;
  
  return $s->{cache}->{$uri}
    if exists( $s->{cache}->{$uri} );
  
  foreach my $route ( @{$s->{routes}} )
  {
    if( my @captured = ($uri =~ $route->{regexp}) )
    {
      my $params = join '&', map {
        my $value = @captured ? shift(@captured) : $route->{defaults}->{$_};
        $value =~ s/\/$//;
        $value = $route->{defaults}->{$_} unless length($value);
        urlencode($_) . '=' . urlencode($value)
      } @{$route->{captures}};
      
      if( $route->{target} =~ m/\?/ )
      {
        return $s->{cache}->{$uri} = $route->{target} . ($params ? "&$params" : "" );
      }
      else
      {
        return $s->{cache}->{$uri} = $route->{target} . ($params ? "?$params" : "" );
      }# end if()
    }# end if()
  }# end foreach()
  
  return $s->{cache}->{$uri} = undef;
}# end match()


sub urlencode
{
  my $toencode = shift;
  no warnings 'uninitialized';
  $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
  $toencode;
}# end urlencode()


1;# return true:

=pod

=head1 NAME

Router::Lite - Lightweight router for the web.

=head1 SYNOPSIS

  use Router::Lite;
  
  my $router = Router::Lite->new();
  
  # A simple route:
  $router->add_route(
    path    => '/foo/bar/',
    target  => "/foobar.asp",
  );
  $router->match('/foo/bar/');  # /foobar.asp
  
  # A route with named parameters:
  $router->add_route(
    path      => '/topics/:topic',
    target    => '/my-topic.asp'
  );
  $router->match('/topics/perl');   # /my-topic.asp?topic=perl
  
  # A slightly more advanced route:
  $router->add_route(
    path      => '/products/{Category:.*}',
    target    => '/product.asp',
    defaults  => { Category => "All" }
  );
  $router->match('/products/');     # /product.asp?Category=All
  $router->match('/products/Foo');  # /product.asp?Category=Foo
  $router->match('/products/Foo/'); # /product.asp?Category=Foo
  
  # Try another route:
  $router->add_route(
    path    => '/zipcode/{zip:[0-9]{5,5}}/',
    target  => '/zipcode.asp'
  );
  $router->match('/zipcode/90210/');  # /zipcode.asp?zip=90210
  $router->match('/zipcode/');        # undef

=head1 DESCRIPTION

C<Router::Lite> is intended for use within a non-B<strictly>-MVC web application
such as a normal mod_perl application or L<ASP4> web application.

C<Router::Lite> provides route caching - so the expensive work of connecting a
uri to a route is only done once.

C<Router::Lite> has no other prerequisites besides L<Carp> and L<Test::More> 
which you probably already have.

B<NOTE:> C<Router::Lite> is still under heavy active development.  The grammar
for the router paths is subject to change and I<might> change to be more in-line with
the route syntax used by ASP.Net version 4.  Use caution with this module for now.

=head1 PUBLIC METHODS

=head2 add_route( route => $str, [ defaults => \%hashref ] )

Adds the given "route" to the routing table.  Routes must be unique - so you can't
have 2 routes that both look like C</foo/:bar> for example.  An exception will
be thrown if an attempt is made to add a route that already exists.

Returns true on success.

=head2 match( $uri )

Returns the 'routed' uri with the intersection of parameters from C<$uri> and the
defaults (if any).

Returns C<undef> if no matching route is found.

=head1 ACKNOWLEDGEMENTS

Part of the routing logic is borrowed from L<Router::Simple> by 
Matsuno Tokuhiro L<http://search.cpan.org/~tokuhirom/>.  This is probably temporary
as this method does not fit all of the use cases I require.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the
same terms as any version of Perl itself.

=cut

