package HiRedis::Driver;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('HiRedis::DriverXS', $VERSION);

1;
__END__
