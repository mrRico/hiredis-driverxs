use ExtUtils::testlib; 
use lib '../lib';

use Test::More;
BEGIN { use_ok('HiRedis::Driver') };

can_ok('HiRedis::Driver', ('connect'));

# tests-block only if redis server run on this pc and on port 6379
SKIP: {
        pass('Connect '.'*' x 10);
        eval {require POSIX};
        skip "POSIX not installed", 'no_plan' if $@;
        my $pc_name = [POSIX::uname()]->[1];
        
        my $redis = eval{HiRedis::Driver->connect($pc_name,6379)};
        if ($@) {
	        skip "Can't connect to redis-server on '$pc_name', port '6379'", 2; 
        	done_testing();
        };
        
        is($redis->ping,1, 'connect');
        SKIP: {
            pass('Commands operating on all value types '.'*' x 10);
            my $test_key = '51ECD026-D181-11DF-8FBA-49560B428834_test::FOO' x 2;

            skip "key '$test_key' already exists", 'no_plan' if $redis->exists($test_key);
            is($redis->set($test_key,'foo'),1, 'set value');
            is($redis->get($test_key),'foo', 'get key');
            is($redis->type($test_key),'string', 'type key');
            is(ref $redis->keys($test_key),'ARRAY', 'list key');
            ok($redis->keys($test_key)->[0] eq $test_key, 'correct list key');
            ok(defined $redis->randomkey eq 1, 'randomkey key');
            
            my $alias = '51ECD026-D181-11DF-8FBA-49560B428834_test::BAR' x 2;
            if ($redis->exists($alias)) {
                ok($redis->renamenx($test_key,$alias) eq 0, 'renamenx key');
            } else {
                is($redis->renamenx($test_key,$alias),1, 'renamenx key - 1');
                is($redis->renamenx($test_key,$alias),undef, 'renamenx key - 2');
                is($redis->rename($alias,$test_key),1, 'rename key');
            };
            
            ok($redis->dbsize > 0,'key counter');
            is($redis->expire($test_key,1),1,'key expire');
            sleep(2);
            is($redis->exists($test_key),0,'key expire succefull');
            
            $redis->set($test_key,'foo');
            is($redis->expireat($test_key,time+1),1,'key expireat');
            sleep(2);
            is($redis->exists($test_key),0,'key expireAT succefull');
            
            pass('Commands operating on string values '.'*' x 10);
            $redis->set($test_key,'foo');
            $redis->expire($test_key,2);
            is($redis->persist($test_key),1, 'persist');
            
            is($redis->ttl($test_key),-1, 'ttl key - 1');
            $redis->expire($test_key,10);
            ok($redis->ttl($test_key) > -1, 'ttl key - 2');
            $redis->persist($test_key);
            
            is($redis->select(1),1, 'select DB 1');
            is($redis->select(0),1, 'select DB 0');
            
            is($redis->move($test_key,1),1, 'move key to DB 1');
            $redis->select(1);
            is($redis->get($test_key),'foo', 'succefull moved key');
            $redis->move($test_key,0);           
            $redis->select(0);
            
            is($redis->getset($test_key,'bar'),'foo', 'succefull getset key');
            is($redis->mget($test_key)->[0],'bar', 'succefull mget key');
            is($redis->setnx($test_key,'foo'),0, 'setnx');
            my $time = 10;
            is($redis->setex($test_key,$time,'bar'),1, 'setex');
            ok($redis->ttl($test_key) > -1, 'succefull setex');
            is($redis->mset($test_key,'foo'),1, 'mset');
            is($redis->get($test_key),'foo', 'succefull mset');
            is($redis->msetnx($test_key,'foo'),0, 'msetnx');
            is($redis->del($test_key),1,'del key');
            is($redis->msetnx($test_key,-5),1, 'succefull msetnx');
            is($redis->incr($test_key),-4, 'increment');
            is($redis->incrby($test_key,-2),-6, 'increment by');
            is($redis->decr($test_key),-7, 'decrement');
            is($redis->decrby($test_key,2),-9, 'decrement by');
            is($redis->append($test_key,2),3, 'append');
            is($redis->substr($test_key,0,-1),-92, 'substr');
            
            pass('Commands operating on lists '.'*' x 10);
            
            is($redis->lpush($test_key,'foo'), undef, 'lpush in string');
            $redis->del($test_key);
            is($redis->lpush($test_key,'foo1'),1, 'lpush');
            is($redis->rpush($test_key,'foo2'),2, 'rpush');
            is($redis->llen($test_key),2, 'llen');
            is($redis->lrange($test_key,0,1)->[1],'foo2', 'lrange');
            is($redis->ltrim($test_key,0,0),1, 'ltrim');
            is($redis->llen($test_key),1, 'ltrim succefull - 1');
            is($redis->lrange($test_key,0,1)->[0],'foo1', 'ltrim succefull - 2');
            is($redis->lindex($test_key,0),'foo1', 'lindex');
            is($redis->lset($test_key,0,'baz'),1, 'lset');
            is($redis->lindex($test_key,0),'baz', 'lset succefull');
            $redis->rpush($test_key,'foo2');
            is($redis->lrem($test_key,1,'baz'),1, 'lrem');
            is($redis->lindex($test_key,0),'foo2', 'lrem succefull');
            is($redis->lpop($test_key),'foo2', 'lpop');
            $redis->rpush($test_key,'foo2');
            is($redis->rpop($test_key),'foo2', 'rpop');            
            $redis->rpush($test_key,'foo1');
            $redis->rpush($test_key,'foo2');
            is($redis->blpop($test_key,0)->[1],'foo1', 'blpop');
            is($redis->brpop($test_key,0)->[1],'foo2', 'brpop');
            $redis->rpush($test_key,'foo3');
            is($redis->rpoplpush($test_key,$test_key),'foo3', 'rpoplpush');
            
            pass('Commands operating on sets '.'*' x 10);
            $redis->del($test_key);
            is($redis->sadd($test_key,'foo'),1, 'sadd');
            is($redis->smembers($test_key)->[0],'foo', 'smembers');
            is($redis->srem($test_key,'foo'),1, 'srem');
            is($redis->scard($test_key),0, 'scard');
            $redis->sadd($test_key,'foo');
            is($redis->spop($test_key),'foo', 'spop');
            $redis->sadd($test_key,'foo');
            is($redis->smove($test_key,$test_key,'foo'),1, 'smove');
            is($redis->scard($test_key),1, 'smove succefull');
            is($redis->sismember($test_key,'foo'),1, 'sismember');
            is($redis->srandmember($test_key),'foo', 'srandmember');

            unless ($redis->exists($alias)) {
                $redis->sadd($alias,'foo');
                $redis->sadd($alias,'bar');
                is($redis->sinter($test_key,$alias)->[0],'foo', 'sinter');
                is(scalar @{$redis->sunion($test_key,$alias)},'2', 'sunion');
                is($redis->sdiff($alias,$test_key)->[0],'bar', 'sdiff');
                $redis->del($alias);
            };
            
            pass('Commands operating on sorted zsets (sorted sets) '.'*' x 10);
            $redis->del($test_key);
            is($redis->zadd($test_key,50,'foo'),1, 'zadd - 1');
            is($redis->zadd($test_key,150,'foos'),1, 'zadd - 2');
            is(ref $redis->zrange($test_key,0,200),'ARRAY', 'zrange');
            is(
                join('',@{$redis->zrevrange($test_key,0,200)}) eq join('',reverse @{$redis->zrange($test_key,0,200)}) ? 1 : 0,
                1, 
                'zrevrange'
            );
            is($redis->zrangebyscore($test_key,20,80)->[0],'foo', 'zrangebyscore');
            is($redis->zcount($test_key,20,160),2, 'zcount');
            is($redis->zcard($test_key),2, 'zcard');
            is($redis->zrem($test_key,'fooser'),0,'zrem');
            is($redis->zincrby($test_key,20,'foo'),70,'zincrby');
            is($redis->zrank($test_key,'foo'),0,'zrank');
            is($redis->zrevrank($test_key,'foo'),1,'zrevrank');
            is($redis->zscore($test_key,'foo'),70,'zscore');
            is(
                $redis->zremrangebyscore($test_key,60,80) && $redis->zcard($test_key) == 1,
                1,
                'zremrangebyscore'
            );
            is(
                $redis->zremrangebyrank($test_key,0,10) && $redis->zcard($test_key) == 0,
                1,
                'zremrangebyrank'
            );

            $redis->zadd($test_key,50,'foo');
            $redis->zadd($test_key,150,'foos');
            $redis->expire($test_key,3600);
            is($redis->persist($test_key) && $redis->ttl($test_key) == -1,1,'persist sorted zsets');
            
            unless ($redis->exists($alias) and $redis->exists($alias.'_')) {
                $redis->zadd($alias,51,'eee');
                $redis->zadd($alias,150,'foos');
                
                is(
                    $redis->zinterstore(traget=>$alias.'_',from=>[$test_key,$alias],weights=>[2],aggregate=>'min'),
                    1,
                    'zinterstore'
                );
                is(
                    $redis->zrange($alias.'_',0,0)->[0],
                    'foos',
                    'zinterstore succefull'
                );

                is(
                    $redis->zunionstore(traget=>$alias.'_',from=>[$test_key,$alias],weights=>[2],aggregate=>'min'),
                    3,
                    'zunionstore'
                );
                is(
                    $redis->zrange($alias.'_',0,3)->[0],
                    'eee', # for foo - weights is 2
                    'zunionstore succefull'
                );
                
                $redis->del($alias);
                $redis->del($alias.'_');
            };
            
            
            pass('Commands operating on hashes '.'*' x 10);
            $redis->del($test_key);
            is($redis->hset($test_key,'www',12),1,'hset - 1');
            is($redis->hset($test_key,'www',12),0,'hset - 2');
            $redis->hset($test_key,'www1',15);
            is($redis->hget($test_key,'www'),12,'hget');
            is($redis->hmget($test_key,'www','www1')->[1],15,'hmget');
            is($redis->hmset($test_key,'www2',2,'www3',3),1,'hmset');
            is($redis->hincrby($test_key,'www3',3),6,'hincrby');
            is($redis->hexists($test_key,'www2'),1,'hexists');
            is($redis->hdel($test_key,'www2s'),0,'hdel');
            is($redis->hlen($test_key),4,'hlen');
            is(scalar (grep {$_ eq 'www'} @{$redis->hkeys($test_key)}),1,'hkeys');
            is(scalar (grep {$_ eq '6'} @{$redis->hvals($test_key)}),1,'hvals');
            is($redis->hgetall($test_key)->{'www'},12,'hgetall');
            $redis->expire($test_key,3600);
            $redis->persist($test_key);
            is($redis->hget($test_key,'www') eq '12' && $redis->ttl($test_key) == -1,1,'persist');
            
            
            
            $redis->del($test_key);
        }
        can_ok('HiRedis::Driver', ('sort')); 
        is($redis->quit,1, 'quit');
};


done_testing();


