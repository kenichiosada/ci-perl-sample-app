use Test::More tests => 4;
use strict;
use warnings;

# the order is important
use App;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';

route_exists [GET => '/test'], 'a route handler is defined for /test';
response_status_is ['GET' => '/test'], 200, 'response status is 200 for /test';

