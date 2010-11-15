#include "Driver.h"

MODULE = HiRedis::Driver        PACKAGE = HiRedis::Driver       PREFIX = rdxs_
PROTOTYPES: DISABLE

# constructor-connector to redis
HiRedis::Driver
rdxs_connect(class, host, port=6379)
    char* class
    char* host
    int port
    PREINIT:
        PERL_UNUSED_VAR(class);
    CODE:
        {
            HiRedis__Driver obj;
            
            obj = malloc(sizeof(struct st_rdxs_obj));
            
            obj->connect_info = malloc(sizeof(struct st_rdxs_connect_info));
            obj->connect_info->host = host;
            obj->connect_info->port = port;

            c_reconnect(obj);

            RETVAL = obj;
        }
    OUTPUT:
        RETVAL

SV*
rdxs_ping(HiRedis::Driver obj)
    CODE:
        {
            RETVAL = c_ping(obj);
        }
    OUTPUT:
        RETVAL

int
rdxs_quit(HiRedis::Driver obj)
    CODE:
        {
            RETVAL = c_quit(obj);
        }
    OUTPUT:
        RETVAL

int
rdxs_multi(HiRedis::Driver obj)
    CODE:
        {
            RETVAL = c_multi(obj);
        }
    OUTPUT:
        RETVAL

SV*
rdxs_exec(HiRedis::Driver obj)
    CODE:
        {
            RETVAL = c_exec(obj);
        }
    OUTPUT:
        RETVAL
        
SV*
rdxs_get(HiRedis::Driver obj, char* key)
    INIT:
        obj->error = NULL;
        if (!key) {
            sprintf(obj->error,"HiRedis::Driver: undefined 'key' in 'get' expression");
            XSRETURN_UNDEF;
        }
    CODE:
        {
            SV* ret = c_get(obj,key);
            if (ret != NULL) {
                RETVAL = ret;
            } else {
                XSRETURN_UNDEF;
            };
        }
    OUTPUT:
        RETVAL

int
rdxs_set(HiRedis::Driver obj, char* key, char* value)
    INIT:
        if (!key) {XSRETURN_UNDEF;}
    CODE:
        {
            RETVAL = c_set(obj,key,value);
        }
    OUTPUT:
        RETVAL

char*
rdxs_error(HiRedis::Driver obj)
    INIT:
        if (!obj->error) {XSRETURN_UNDEF;}
    CODE:
        {
            RETVAL = obj->error;
        }
    OUTPUT:
        RETVAL
        
void
rdxs_DESTROY(HiRedis::Driver obj)
    CODE:
        {
            c_DESTROY(obj);
        }
