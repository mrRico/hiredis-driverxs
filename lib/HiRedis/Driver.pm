package HiRedis::Driver;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('HiRedis::Driver', $VERSION);

# external interface -------------------------------

# $redis->zinterstore(traget=>'dstkey',from=>['key1',..,'keyN'],weights=>['w1',..,'wN'],aggregate=>['SUM'|'MIN'|'MAX']);
sub zinterstore {
    shift->_switch_zstore('_zinterstore',@_);
}

# $redis->zunionstore(traget=>'dstkey',from=>['key1',..,'keyN'],weights=>['w1',..,'wN'],aggregate=>['SUM'|'MIN'|'MAX']);
sub zunionstore {
    shift->_switch_zstore('_zunionstore',@_);
}

#$redis->sort(
#    key => 'key',
#    by => '*_object',
#    limit => ['start','limit'],
#    order => 'desc',
#    get => ['pattern'], # or get => 'pattern' 
#    alpha => 1,
#    store => 'key_store'
#);
# $redis->sort(key=>'foo',store=>'dede',limit=>[0,2],get=>['object_*'],by=>'weight_*')
sub sort {
    my $self = shift;
    my $param = @_ % 2 ? $_[0] : {@_};
    return undef unless (
        @_ and
        $param->{'key'}
    );
    
    my @param = ($param->{'key'});
    map {push @param, uc($_), $param->{$_}} grep {$param->{$_}} ('by','order','alpha','store');
    if ($param->{'limit'} and ref $param->{'limit'} eq 'ARRAY' and $#{$param->{'limit'}} == 1 and not grep {$_ ne int $_} @{$param->{'limit'}}) {
        push @param, 'LIMIT', @{$param->{'limit'}};
    };
    
    if ($param->{'get'}) {
        ref $param->{'get'} eq 'ARRAY' ? map {push @param, 'GET', $_} grep {$_} @{$param->{'get'}} : push @param,'GET',$param->{'get'};  
    };
    
    return $self->_sort(@param);
}

# $redis->info - returned hash reference
# $redis->info(1) - returned string from redis
sub info {
    my $ret = {};
    my $str = shift->_info();
    if (shift) {return $str};
    return undef unless $str;
    foreach (split(/[\r|\n]+/,$str)) {
    	next unless $_;
    	my($key,$val) = split(':',$_);
    	if ($key =~ /db\d+/ && $val =~ /,/) {
    		foreach (split(',',$val)) {
    			next unless ($_ and /=/);
    			my ($sub_key,$sub_val) = split(/=/,$_);
    			$ret->{$key}->{$sub_key} = $sub_val;
    		};
    	} else {
	    	$ret->{$key} = $val;
    	};
    };
    return $ret;
}

sub config_get {
    my $ret = shift->_config_get(shift);
    return undef unless $ret;
    $ret = {@$ret};
    return $ret;
}

sub hgetall {
    my $ret = shift->_hgetall(shift);
    return undef unless $ret;
    $ret = {@$ret};
    return $ret;
}

# internal interface -------------------------------
# Perl is better, when we need prepare many incoming arguments for C function

sub _switch_zstore {
    my $self = shift;
    my $switch = shift;
    my $param = @_ % 2 ? $_[0] : {@_};
    return undef unless (
        ref $param eq 'HASH' and 
        $param->{traget} and
        not ref $param->{traget} and
        $param->{from} and
        ref $param->{from} eq 'ARRAY' and
        $#{$param->{from}} > -1
    );
    
    my @param = ($param->{traget},$#{$param->{from}}+1,@{$param->{from}}); 
    
    # only int weights
    if ($param->{weights} and ref $param->{weights} eq 'ARRAY' and $#{$param->{weights}} > -1 and not grep {defined $_ and $_ ne int $_} @{$param->{weights}}) {
        my $added_weiths = $#{$param->{from}} - $#{$param->{weights}};
        if ($added_weiths > 0) {
            map {push @{$param->{weights}},1} (1..$added_weiths);
        } else {
            $#{$param->{weights}} = $#{$param->{from}};
        };
        push @param, 'WEIGHTS', @{$param->{weights}};
    };
    
    if ($param->{aggregate} and $param->{aggregate} =~ /^(sum|min|max)$/i) {
        push @param, 'AGGREGATE', uc($param->{aggregate});
    };
    
    return $self->$switch(@param);
}


1;
__END__
