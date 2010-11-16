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
    
#define HDR_HAVE_ARG() \
    if(items < 2) {XSRETURN_UNDEF;};

#define HDR_ARG_IS_NUMBER_OR_UNDEF(arg_num) \
        if(!check_number((char*)SvPV_nolen(ST(arg_num)))) XSRETURN_UNDEF;

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
        {
            HDR_ARG_IS_NUMBER_OR_UNDEF(2);
        };
        {
            HDR_ARG_IS_NUMBER_OR_UNDEF(3);
        };
    CODE:
        {
            HDR_WITH_ARG("SUBSTR");
        }
    OUTPUT:
        RETVAL

# Commands operating on lists --------------------------










# multi
SV*
hdr_multi(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("MULTI");
        }
    OUTPUT:
        RETVAL

# exec
SV*
hdr_exec(HiRedis::Driver obj)
    CODE:
        {
            HDR_WITHOUT_ARG("EXEC");
        }
    OUTPUT:
        RETVAL


void
hdr_DESTROY(HiRedis::Driver obj)
    CODE:
        {
            c_DESTROY(obj);
        }
