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
=encoding utf-8

=head1 NAME

B<HiRedis::Driver> - yet another interface to hiredis.

I<Version 0.01>

=head1 SYNOPSIS
    
      use HiRedis::Driver;
      
      # connecting
      my $redis = eval{HiRedis::Driver->connect('172.0.0.1',6379)};
      
    
=head1 DESCRIPTION

B<HiRedis::Driver> is a wrapper around hiredis C client.
In this implementation you can set undef value or empty string to Redis (they are transparently converted to 0E0 and 0E00 respectively).
See L<http://github.com/antirez/hiredis>

=head3 be carefull

Fatal error comes back from any of the methods if the Redis shutdown (or not run). 
Therefore, this driver is recommended for applications where Redis is a dominant logic element.

This driver tested only on developer server.
Accepted any comments about the driver.
Github L<https://github.com/mrRico/hiredis-driverxs>

Some features do not work in earlier versions Redis.
Please download the latest version from Redis L<https://github.com/antirez/redis>.

=head1 METHODS


=head2 Connection handling

=head3 auth($pass)

simple password authentication if enabled

=head3 ping()

true-false

=head3 quit()

true-false


=head2 Commands operating on all value types

=head3 exists($key)

test if a key exists
true-false

=head3 del($key)

delete a key
true-false

=head3 type($key)

return the type of the value stored at key
type-false

=head3 keys($pattern)

return all the keys matching a given pattern
arr_ref-false

=head3 randomkey()

return a random key from the key space
key-false

=head3 rename($oldname,$newname)

rename the old key in the new one, destroying the newname key if it already exists
true-false

=head3 renamenx($oldname,$newname)

rename the oldname key to newname, if the newname key does not already exist 
true-false

=head3 dbsize()

return the number of keys in the current db
integer-false

=head3 expire($key,$ttl)

set a time to live in seconds on a key
$ttl - must be integer (0 if you wont delete key now) 
true-false

=head3 expireat($key,$ttl)

set a time to live in seconds on a key
$ttl - must be integer, equal to the current or future time in unixtime
true-false

=head3 ttl($key)

get the time to live in seconds of a key
return -1 if $key have't expire 
integer-false

=head3 persist($key)

remove the expire from a key
Be carefull: in Redis in earlier versions 2.1 persist is't avaliable 
true-false

=head3 select($dbindex)

select the DB with the specified index 
true-false

=head3 move($key,$dbindex)

Move the key from the currently selected DB to the dbindex DB
true-false

=head3 flushdb()

Remove all the keys from the currently selected DB 
true-false

=head3 flushall()

Remove all the keys from all the databases 
true-false


=head2 Commands operating on string values

=head3 get($key)

return the value of the key
value key-false

=head3 set($key,$value)

set a key to a value
true-false

=head3 getset($key,$value)

set a key to a value
returning the old value of the key
old value-false

=head3 mget($key1,...,$keyN)

multi-get, return the values of the keys
arr_ref-false

=head3 setnx($key,$value)

set a key to a value if the key does not exist
true-false

=head3 setex($key,$value,$ttl)

set+expire combo command
Be carefull: don't set very big ttl, as so 1000000000. you can have a problem.
true-false

=head3 mset($key1,$value1,...,$keyN,$valueN)

set multiple keys to multiple values in a single atomic operation
true-false

=head3 msetnx($key1,$value1,...,$keyN,$valueN)

set multiple keys to multiple values in a single atomic operation if none of the keys already exist 
true-false

=head3 incr($key)

increment the integer value of key  
new integer value-false

=head3 incrby($key,$integer)

increment the integer value of key by integer  
new integer value-false

=head3 decr($key)

decrement the integer value of key  
new integer value-false

=head3 decrby($key,$integer)

decrement the integer value of key by integer  
new integer value-false

=head3 append($key,$value)

append the specified string to the string stored at key   
true-false

=head3 substr($key,$start,$end)

return a substring of a larger string   
substring-false


=head2 Commands operating on lists

=head3 rpush($key,$value)

append an element to the tail of the List value at key   
true-false

=head3 lpush($key,$value)

append an element to the head of the List value at key  
true-false

=head3 llen($key)

return the length of the List value at key 
integer-false

=head3 lrange($key,$start,$end)

return a range of elements from the List at key 
arr_ref-false

=head3 ltrim($key,$start,$end)

trim the list at key to the specified range of elements  
arr_ref-false

=head3 lindex($key,$index)

return the element at index position from the List at key  
value-false

=head3 lset($key,$index,$value)

set a new value as the element at index position of the List at key  
true-false

=head3 lrem($key,$count,$value)

remove the first-N, last-N, or all the elements matching value from the List at key  
true-false

=head3 lpop($key)

return and remove (atomically) the first element of the List at key   
value-false

=head3 rpop($key)

return and remove (atomically) the last element of the List at key   
value-false

=head3 blpop($key1,...,$keyN,$timeout)

blocking LPOP
arr_ref-false

=head3 brpop($key1,...,$keyN,$timeout)

blocking RPOP
arr_ref-false

=head3 rpoplpush($srckey,dstkey)

return and remove (atomically) the last element of the source List stored at srckey and push the same element to the destination List stored at dstkey   
value-false


=head2 Commands operating on sets

=head3 sadd($key,$member)

add the specified member to the Set value at key   
true-false

=head3 smembers($key)

return all the members of the Set value at key   
arr_ref-false

=head3 srem($key,$member)

remove the specified member from the Set value at key   
true-false

=head3 spop($key)

remove and return (pop) a random element from the Set value at key  
value-false

=head3 smove($srckey,$dstkey,$member)

move the specified member from one Set to another atomically   
true-false

=head3 scard($key)

return the number of elements (the cardinality) of the Set at key  
integer-false

=head3 sismember($key,$member)

test if the specified value is a member of the Set at key   
true-false

=head3 sinter($key1,...,$keyN)

return the intersection between the Sets stored at key1, key2, ..., keyN   
arr_ref-false

=head3 sinterstore($dstkey,$key1,...,$keyN)

compute the intersection between the Sets stored at key1, key2, ..., keyN, and store the resulting Set at dstkey    
true-false

=head3 sunion($key1,...,$keyN)

return the union between the Sets stored at key1, key2, ..., keyN   
arr_ref-false

=head3 sunionstore($dstkey,$key1,...,$keyN)

compute the union between the Sets stored at key1, key2, ..., keyN, and store the resulting Set at dstkey    
true-false

=head3 sdiff($key1,...,$keyN)

return the difference between the Set stored at key1 and all the Sets key2, ..., keyN    
arr_ref-false

=head3 sdiffstore($dstkey,$key1,...,$keyN)

compute the difference between the Set key1 and all the Sets key2, ..., keyN, and store the resulting Set at dstkey     
true-false

=head3 srandmember($key)

return a random member of the Set value at key    
value-false


=head2 Commands operating on sorted zsets (sorted sets)

=head3 zadd($key,$score,$member)

add the specified member to the Sorted Set value at key or update the score if it already exist   
true-false

=head3 zrange($key,$start,$end)

return a range of elements from the sorted set at key   
arr_ref-false

=head3 zrevrange($key,$start,$end)

return a range of elements from the sorted set at key, exactly like ZRANGE, but the sorted set is ordered in traversed in reverse order, from the greatest to the smallest score   
arr_ref-false

=head3 zrangebyscore($key,$min,$max)

return all the elements with score &gt;= min and score &lt;= max (a range query) from the sorted set   
arr_ref-false

=head3 zcount($key,$min,$max)

return the number of elements with score &gt;= min and score &lt;= max in the sorted set   
integer-false

=head3 zcard($key)

return the cardinality (number of elements) of the sorted set at key   
integer-false

=head3 zrem($key,$member)

remove the specified member from the Sorted Set value at key   
true-false

=head3 zincrby($key,$increment,$member)

if the member already exists increment its score by increment, otherwise add the member setting increment as score  
new score-false

=head3 zrank($key,$member)

return the rank (or index) or member in the sorted set at key, with scores being ordered from low to high   
index-false

=head3 zrevrank($key,$member)

Return the rank (or index) or member in the sorted set at key, with scores being ordered from high to low    
index-false

=head3 zscore($key,$element)

return the score associated with the specified element of the sorted set at key    
score-false

=head3 zremrangebyscore($key,$min,$max)

remove all the elements with rank &gt;= min and rank &lt;= max from the sorted set    
true-false

=head3 zremrangebyrank($key,$min,$max)

Remove all the elements with score &gt;= min and score &lt;= max from the sorted set    
true-false

=head3 zunionstore,zinterstore
        
    $redis->zinterstore(
        traget=>'dstkey',
        from=>['key1',..,'keyN'],
        weights=>['w1',..,'wN'],
        aggregate=>['SUM'|'MIN'|'MAX']
    );
    
perform a union or intersection over a number of sorted sets with optional weight and aggregate    
true-false


=head2 Commands operating on hashes

=head3 hset($key,$field,$value)

set the hash field to the specified value. Creates the hash if needed.   
true-false

=head3 hget($key,$field)

retrieve the value of the specified hash field.   
value-false

=head3 hmget($key,$field1,...,$fieldN)

get the hash values associated to the specified fields.   
list values-false

=head3 hmset($key,$field1,$value1,...,$fieldN,$valueN)

Set the hash fields to their respective values   
true-false

=head3 hincrby($key,$field,$integer)

increment the integer value of the hash at key on field with integer.   
new integer value-false

=head3 hexists($key,$field)

test for existence of a specified field in a hash   
true-false

=head3 hdel($key,$field)

remove the specified field from a hash   
true-false

=head3 hlen($key)

return the number of items in a hash   
integer-false

=head3 hkeys($key)

return all the fields in a hash   
arr_ref-false

=head3 hvals($key)

return all the values in a hash 
arr_ref-false

=head3 hgetall($key)

return all the fields and associated values in a hash 
hashref-false


=head2 Sorting

=head3 sort
    
    $redis->sort(
	    key => 'key',
	    by => '*_object',
	    limit => ['start','limit'],
	    order => 'desc',
	    get => ['pattern'], # or get => 'pattern' 
	    alpha => 1,
	    store => 'key_store'
	);    
    
sort a Set or a List accordingly to the specified parameters 
true-false


=head2 Transactions

=head3 multi()

begin transaction 
true-false

=head3 discard()

skip transaction 
true-false

=head3 exec()

execute transaction 
true-false

=head3 watch($key)

true-false

=head3 unwatch()

true-false


=head2 Persistence control commands

=head3 shutdown()

synchronously save the DB on disk, then shutdown the server
true-false

=head3 save()

synchronously save the DB on disk
true-false

=head3 bgsave()

asynchronously save the DB on disk 
true-false

=head3 lastsave()

return the UNIX time stamp of the last successfully saving of the dataset on disk
integer-false

=head3 bgrewriteaof()

rewrite the append only file in background when it gets too big 
true-false


=head2 Remote server control commands

=head3 info()

Provide information and statistics about the server  
hashref-false

=head3 config_get()

Provide config information about the server  
hashref-false

=head3 config_set($param,$new_value)

Change config information  
true-false


=head2 Publish-Subscribe

=head3 subscribe($channel1,...,$channelN)

=head3 unsubscribe($channel1,...,$channelN)

=head3 psubscribe($pattern)

=head3 punsubscribe($pattern)

=head3 publish($channel,$message)


=head1 SEE ALSO

The Redis command reference can be found here: L<http://code.google.com/p/redis/wiki/CommandReference>

=head1 AUTHOR

Ivan Sivirinov <catamoose at yandex.ru>

=cut
