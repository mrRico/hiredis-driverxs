#include "Driver.h"

/*
 *   Following macros used only in this file
 */

/*
 *   INIT section macros --------------------------
 */
#define HDR_CNT_ARG_OR_UNDEF(cnt) \
    if(items != cnt+1) {XSRETURN_UNDEF;};

#define HDR_EVEN_ARG_OR_UNDEF() \
    if(items < 2 || !(items % 2)) {XSRETURN_UNDEF;};

#define HDR_ODD_ARG_OR_UNDEF() \
    if(items < 3 || (items % 2)) {XSRETURN_UNDEF;};
    
#define HDR_HAVE_ARG() \
    if(items < 2) {XSRETURN_UNDEF;};

#define HDR_HAVE_MORE_THEN_ARG(cnt) \
    if(items < cnt) {XSRETURN_UNDEF;};

#define HDR_ARG_IS_NUMBER_OR_UNDEF(arg_num) \
        if(!check_number((char*)SvPV_nolen(ST(arg_num==-1 ? (items-1) : arg_num)))) XSRETURN_UNDEF;

/*
 *   CODE section macros --------------------------
 */
#define HDR_WITH_ARG(cmd) \
            char* param[items-2]; \
            unsigned int j; \
            for (j = 0; j < items-1; j++) { \
                if (!SvOK(ST(j+1))) { \
                    param[j] = RES_UNDEF; \
                } else { \
                    char* thing = (char*)SvPV_nolen(ST(j+1)); \
                    param[j] = strlen(thing) ? thing : RES_EMPTY_STR; \
                } \
            } \
            RETVAL = c_command(obj,cmd,param,items-1);

#define HDR_WITHOUT_ARG(cmd) \
            char* param[0]; \
            RETVAL = c_command(obj,cmd,param,0);

/*
 * helper
 */
short int
check_number(char* test) {
    if(!strlen(test)) return 0;
    unsigned int j = 0;
    while(test[j] != '\0') {
        if(!isdigit(test[j])) return 0;
        j++;
    };
    return 1;
}

/*
 *   PERLXS section --------------------------------
 */
MODULE = HiRedis::Driver        PACKAGE = HiRedis::Driver       PREFIX = hdr_
PROTOTYPES: DISABLE

# constructor-connector to redis
HiRedis::Driver
hdr_connect(class, host, port=6379)
    char* class
    char* host
    int port
    PREINIT:
        PERL_UNUSED_VAR(class);
    CODE:
        {
            HiRedis__Driver obj;
            
            obj = malloc(sizeof(struct st_hdr_obj));
            
            obj->connect_info = malloc(sizeof(struct st_hdr_connect_info));
            obj->connect_info->host = host;
            obj->connect_info->port = port;

            c_reconnect(obj);

            RETVAL = obj;
        }
    OUTPUT:
        RETVAL

# Connection handling --------------------------
# quit
int
hdr_quit(HiRedis::Driver obj)
    CODE:
        {
            RETVAL = c_quit(obj);
        }
    OUTPUT:
        RETVAL

SV*
hdr_auth(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("AUTH");
        }
    OUTPUT:
        RETVAL

# ping
SV*
hdr_ping(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("PING");
        }
    OUTPUT:
        RETVAL
        
# Commands operating on all value types ----------------

SV*
hdr_exists(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("EXISTS");
        }
    OUTPUT:
        RETVAL

SV*
hdr_del(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("DEL");
        }
    OUTPUT:
        RETVAL

SV*
hdr_type(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("TYPE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_keys(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("KEYS");
        }
    OUTPUT:
        RETVAL

SV*
hdr_randomkey(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("RANDOMKEY");
        }
    OUTPUT:
        RETVAL

SV*
hdr_rename(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("RENAME");
        }
    OUTPUT:
        RETVAL

SV*
hdr_renamenx(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("RENAMENX");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr_dbsize(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("DBSIZE");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr_expire(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("EXPIRE");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr_expireat(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("EXPIREAT");
        }
    OUTPUT:
        RETVAL

SV*
hdr_ttl(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("TTL");
        }
    OUTPUT:
        RETVAL        
        
SV*
hdr_persist(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("PERSIST");
        }
    OUTPUT:
        RETVAL

SV*
hdr_select(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
        HDR_ARG_IS_NUMBER_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("SELECT");
        }
    OUTPUT:
        RETVAL

SV*
hdr_move(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("MOVE");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr_flushdb(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("FLUSHDB");
        }
    OUTPUT:
        RETVAL        

SV*
hdr_flushall(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("FLUSHALL");
        }
    OUTPUT:
        RETVAL 


# Commands operating on string values --------------------------

SV*
hdr_get(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("GET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_set(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("SET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_getset(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("GETSET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_mget(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_ARG();
    CODE:
        {
            HDR_WITH_ARG("MGET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_setnx(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("SETNX");
        }
    OUTPUT:
        RETVAL

SV*
hdr_setex(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("SETEX");
        }
    OUTPUT:
        RETVAL        
        
SV*
hdr_mset(HiRedis::Driver obj, ...)
    INIT:
        HDR_EVEN_ARG_OR_UNDEF();
    CODE:
        {
            HDR_WITH_ARG("MSET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_msetnx(HiRedis::Driver obj, ...)
    INIT:
        HDR_EVEN_ARG_OR_UNDEF();
    CODE:
        {
            HDR_WITH_ARG("MSETNX");
        }
    OUTPUT:
        RETVAL

SV*
hdr_incr(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("INCR");
        }
    OUTPUT:
        RETVAL

SV*
hdr_incrby(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("INCRBY");
        }
    OUTPUT:
        RETVAL

SV*
hdr_decr(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("DECR");
        }
    OUTPUT:
        RETVAL

SV*
hdr_decrby(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("DECRBY");
        }
    OUTPUT:
        RETVAL

SV*
hdr_append(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("APPEND");
        }
    OUTPUT:
        RETVAL

SV*
hdr_substr(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("SUBSTR");
        }
    OUTPUT:
        RETVAL

# Commands operating on lists --------------------------

SV*
hdr_rpush(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("RPUSH");
        }
    OUTPUT:
        RETVAL

SV*
hdr_lpush(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("LPUSH");
        }
    OUTPUT:
        RETVAL

SV*
hdr_llen(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("LLEN");
        }
    OUTPUT:
        RETVAL

SV*
hdr_lrange(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("LRANGE");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr_ltrim(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("LTRIM");
        }
    OUTPUT:
        RETVAL

SV*
hdr_lindex(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("LINDEX");
        }
    OUTPUT:
        RETVAL

SV*
hdr_lset(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("LSET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_lrem(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("LREM");
        }
    OUTPUT:
        RETVAL

SV*
hdr_lpop(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("LPOP");
        }
    OUTPUT:
        RETVAL

SV*
hdr_rpop(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("RPOP");
        }
    OUTPUT:
        RETVAL

SV*
hdr_blpop(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(-1);
    CODE:
        {
            HDR_WITH_ARG("BLPOP");
        }
    OUTPUT:
        RETVAL

SV*
hdr_brpop(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(-1);
    CODE:
        {
            HDR_WITH_ARG("BRPOP");
        }
    OUTPUT:
        RETVAL

SV*
hdr_rpoplpush(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("RPOPLPUSH");
        }
    OUTPUT:
        RETVAL


# Commands operating on sets -----------------

SV*
hdr_sadd(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("SADD");
        }
    OUTPUT:
        RETVAL

SV*
hdr_smembers(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("SMEMBERS");
        }
    OUTPUT:
        RETVAL

SV*
hdr_srem(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("SREM");
        }
    OUTPUT:
        RETVAL

SV*
hdr_spop(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("SPOP");
        }
    OUTPUT:
        RETVAL

SV*
hdr_smove(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("SMOVE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_scard(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("SCARD");
        }
    OUTPUT:
        RETVAL

SV*
hdr_sismember(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("SISMEMBER");
        }
    OUTPUT:
        RETVAL

SV*
hdr_sinter(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_ARG();
    CODE:
        {
            HDR_WITH_ARG("SINTER");
        }
    OUTPUT:
        RETVAL

SV*
hdr_sinterstore(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(2);
    CODE:
        {
            HDR_WITH_ARG("SINTERSTORE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_sunion(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_ARG();
    CODE:
        {
            HDR_WITH_ARG("SUNION");
        }
    OUTPUT:
        RETVAL

SV*
hdr_sunionstore(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(2);
    CODE:
        {
            HDR_WITH_ARG("SUNIONSTORE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_sdiff(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_ARG();
    CODE:
        {
            HDR_WITH_ARG("SDIFF");
        }
    OUTPUT:
        RETVAL

SV*
hdr_sdiffstore(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(2);
    CODE:
        {
            HDR_WITH_ARG("SDIFFSTORE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_srandmember(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("SRANDMEMBER");
        }
    OUTPUT:
        RETVAL

# Commands operating on sorted zsets (sorted sets) ----------------

SV*
hdr_zadd(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("ZADD");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zrange(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("ZRANGE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zrevrange(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("ZREVRANGE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zrangebyscore(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("ZRANGEBYSCORE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zcount(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("ZCOUNT");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zcard(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("ZCARD");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zrem(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("ZREM");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zincrby(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("ZINCRBY");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zrank(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("ZRANK");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zrevrank(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("ZREVRANK");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zscore(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("ZSCORE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zremrangebyscore(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("ZREMRANGEBYSCORE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_zremrangebyrank(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("ZREMRANGEBYRANK");
        }
    OUTPUT:
        RETVAL

SV*
hdr__zunionstore(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(3);
    CODE:
        {
            HDR_WITH_ARG("ZUNIONSTORE");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr__zinterstore(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(3);
    CODE:
        {
            HDR_WITH_ARG("ZINTERSTORE");
        }
    OUTPUT:
        RETVAL        

# Commands operating on hashes ----------------------------

SV*
hdr_hset(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("HSET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_hget(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("HGET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_hmget(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(2);
    CODE:
        {
            HDR_WITH_ARG("HMGET");
        }
    OUTPUT:
        RETVAL

SV*
hdr_hmset(HiRedis::Driver obj, ...)
    INIT:
        HDR_ODD_ARG_OR_UNDEF();
    CODE:
        {
            HDR_WITH_ARG("HMSET");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr_hincrby(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(3);
        HDR_ARG_IS_NUMBER_OR_UNDEF(3);
    CODE:
        {
            HDR_WITH_ARG("HINCRBY");
        }
    OUTPUT:
        RETVAL

SV*
hdr_hexists(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("HEXISTS");
        }
    OUTPUT:
        RETVAL

SV*
hdr_hdel(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("HDEL");
        }
    OUTPUT:
        RETVAL

SV*
hdr_hlen(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("HLEN");
        }
    OUTPUT:
        RETVAL

SV*
hdr_hkeys(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("HKEYS");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr_hvals(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("HVALS");
        }
    OUTPUT:
        RETVAL
        
SV*
hdr_hgetall(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("HGETALL");
        }
    OUTPUT:
        RETVAL        
        
# Sorting -----------------------------------

SV*
hdr__sort(HiRedis::Driver obj, ...)
    INIT:
        HDR_HAVE_MORE_THEN_ARG(1);
    CODE:
        {
            HDR_WITH_ARG("SORT");
        }
    OUTPUT:
        RETVAL

# Transactions ------------------------------------------

SV*
hdr_multi(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("MULTI");
        }
    OUTPUT:
        RETVAL

SV*
hdr_discard(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("DISCARD");
        }
    OUTPUT:
        RETVAL

SV*
hdr_exec(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("EXEC");
        }
    OUTPUT:
        RETVAL

SV*
hdr_watch(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("WATCH");
        }
    OUTPUT:
        RETVAL

SV*
hdr_unwatch(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("UNWATCH");
        }
    OUTPUT:
        RETVAL

# Persistence control commands --------------------------

int
hdr_shutdown(HiRedis::Driver obj)
    CODE:
        {
            RETVAL = c_shutdown(obj);
        }
    OUTPUT:
        RETVAL

SV*
hdr_save(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("SAVE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_bgsave(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("BGSAVE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_lastsave(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("LASTSAVE");
        }
    OUTPUT:
        RETVAL

SV*
hdr_bgrewriteaof(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("BGREWRITEAOF");
        }
    OUTPUT:
        RETVAL

# Remote server control commands ----------------------------

SV*
hdr__info(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("INFO");
        }
    OUTPUT:
        RETVAL

SV*
hdr__config_get(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(1);
    CODE:
        {
            HDR_WITH_ARG("CONFIG GET");
        }
    OUTPUT:
        RETVAL 

SV*
hdr_config_set(HiRedis::Driver obj, ...)
    INIT:
        HDR_CNT_ARG_OR_UNDEF(2);
    CODE:
        {
            HDR_WITH_ARG("CONFIG SET");
        }
    OUTPUT:
        RETVAL


void
hdr_DESTROY(HiRedis::Driver obj)
    CODE:
        {
            c_DESTROY(obj);
        }
