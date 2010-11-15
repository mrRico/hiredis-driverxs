#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>
#include "hiredis.h"

#define RES_PING "PONG"
#define RES_OK "OK"
#define RES_QUEUE "QUEUED"
#define RES_MULTI_ERROR "ERR EXEC without MULTI"

#define C_PACKAGE_DEBUG 1
#define C_PACKAGE_ERROR "HiRedis::Driver: %s"

/*
 * macro definition -------------------------------------
 */

// reconnecting by default if connect has problem
// after reconnect obj->c->errstr is NULL, therefore we can added this into packages methods
#define C_RECONNECT_IF_ERROR(command) \
		if (obj->c->errstr) { \
			c_reconnect(obj); \
			return command; \
		}; \
		if (C_PACKAGE_DEBUG) _debug_type(reply);

// croak macros
#define C_CROAK() croak(C_PACKAGE_ERROR,obj->error)

// connect free
#define C_CONNECT_FREE() \
	redisFree(obj->c); \
	obj->c = NULL;

/*
 * type definition --------------------------------------
 */
typedef struct st_rdxs_connect_info {
    char *host;
    unsigned int port;
} RDXS_connect_info;

typedef struct st_rdxs_obj {
		redisContext* c;
		char* error;
        RDXS_connect_info *connect_info;
} *HiRedis__Driver;

/*
 * describe function -------------------------------------
 */
static void _debug_type(redisReply* reply);
void c_DESTROY(HiRedis__Driver obj);
void c_reconnect(HiRedis__Driver obj);
SV*  c_ping(HiRedis__Driver obj);
int  c_quit(HiRedis__Driver obj);
int  c_multi(HiRedis__Driver obj);
SV*  c_exec(HiRedis__Driver obj);
SV*  c_get(HiRedis__Driver obj, char* key);
int  c_set(HiRedis__Driver obj, char* key, char* value);

/*
 * function definition ------------------------------------
 */
static void
_debug_type(redisReply* reply) {
	printf("Current reply type is ");
    switch(reply->type) {
    case REDIS_REPLY_ERROR:
    	printf("REDIS_REPLY_ERROR\n");
    	break;
    case REDIS_REPLY_STATUS:
    	printf("REDIS_REPLY_STATUS\n");
    	break;
    case REDIS_REPLY_INTEGER:
    	printf("REDIS_REPLY_INTEGER\n");
    	break;
    case REDIS_REPLY_STRING:
    	printf("REDIS_REPLY_STRING\n");
    	break;
    case REDIS_REPLY_ARRAY:
    	printf("REDIS_REPLY_ARRAY\n");
    	break;
    default:
    	printf("DEFAULT\n");
    };
    printf("Reply response string: %s\n",reply->str);
}

void
c_reconnect(HiRedis__Driver obj) {
	obj->error = NULL;
	if (!obj->connect_info->host) {
		obj->error = "'host' not defined, when call connect";
		C_CROAK();
	};
	obj->c = redisConnect(obj->connect_info->host, obj->connect_info->port);
    if (obj->c->err != 0) {
    	obj->error = obj->c->errstr;
    	C_CONNECT_FREE();
    	C_CROAK();
    };
}

SV*
c_response(redisReply* reply) {
	SV* ret;
	AV* ret_array;
	unsigned int j;

    switch(reply->type) {
    case REDIS_REPLY_STATUS:
		if (!strcasecmp(reply->str,RES_PING)) {
			ret = newSViv(1);
			break;
		} else if (!strcasecmp(reply->str,RES_QUEUE)) {
			ret = newSViv(1);
			break;
		} else if (!strcasecmp(reply->str,RES_OK)) {
			ret = newSViv(1);
			break;
		}
    case REDIS_REPLY_ERROR:
    	if (!strcasecmp(reply->str,RES_MULTI_ERROR)) {
    		ret = newSV(0);
    		break;
    	}
    case REDIS_REPLY_INTEGER:
    	ret = newSViv(reply->integer);
    	break;
    case REDIS_REPLY_STRING:
    	ret = newSVpvn(reply->str,strlen(reply->str));
    	break;
    case REDIS_REPLY_ARRAY:
    	ret_array = newAV();
        for (j = 0; j < reply->elements; j++) {
        	av_push(ret_array,c_response(reply->element[j]));
        }
        ret = newRV_inc((SV*)ret_array);
        break;
    default:
    	ret = newSViv(0);
    }

	return ret;
}


SV*
c_ping(HiRedis__Driver obj) {
	redisReply* reply = redisCommand(obj->c,"PING");
	C_RECONNECT_IF_ERROR(c_ping(obj));

	SV* ret = c_response(reply);

	freeReplyObject(reply);
	return ret;
}

int
c_quit(HiRedis__Driver obj) {
	C_CONNECT_FREE();
	return 1;
}

int
c_multi(HiRedis__Driver obj) {
	redisReply* reply = redisCommand(obj->c,"MULTI");
	C_RECONNECT_IF_ERROR(c_multi(obj));
	int ret = (reply->type == REDIS_REPLY_STATUS && C_REPLY_EQ(RES_OK)) ? 1 : 0;
	freeReplyObject(reply);
	return ret;
}

SV*
c_exec(HiRedis__Driver obj) {
	redisReply* reply = redisCommand(obj->c,"EXEC");
	C_RECONNECT_IF_ERROR(c_exec(obj));

	SV* ret = c_response(reply);

	freeReplyObject(reply);
	return ret;
}

SV*
c_get(HiRedis__Driver obj, char* key) {
	redisReply* reply = redisCommand(obj->c,"GET %s",key);
	C_RECONNECT_IF_ERROR(c_get(obj,key));
	SV* ret = c_response(reply);
	freeReplyObject(reply);
	return ret;
}

int
c_set(HiRedis__Driver obj, char* key, char* value) {
	redisReply* reply = redisCommand(obj->c,"SET %s %s",key,value);
	C_RECONNECT_IF_ERROR(c_set(obj,key,value));
	int ret = strcasecmp(reply->str,RES_OK) == 0 ? 1 : 0;
	freeReplyObject(reply);
	return ret;
}

void
c_DESTROY(HiRedis__Driver obj) {
	free(obj->connect_info);
	obj->connect_info = NULL;
	if(obj->c != NULL) {
		C_CONNECT_FREE();
	}
	free(obj);
	obj = NULL;
}
