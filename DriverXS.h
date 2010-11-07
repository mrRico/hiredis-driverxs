#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>
#include "hiredis.h"

#define RES_PING "PONG"
#define RES_OK "OK"
#define RES_QUEUE "QUEUED"

#define C_PACKAGE_DEBUG 1
#define C_PACKAGE_ERROR "HiRedis::DriverXS: %s"
#define C_MAX_TRANSACTION_CNT 500000

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

// flush transaction
#define C_SKIP_TRANSACTION() \
    obj->transaction = 0; \
	memset(obj->fn_list, 0, C_MAX_TRANSACTION_CNT);

// string reply eq
#define C_REPLY_EQ(possible_answer) (!strcasecmp(reply->str,possible_answer) || !strcasecmp(reply->str,RES_QUEUE))

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
		short int transaction;
		char* (*fn_list[C_MAX_TRANSACTION_CNT])(char*);
        RDXS_connect_info *connect_info;
} *HiRedis__DriverXS;

/*
 * describe function -------------------------------------
 */
static void _debug_type(redisReply* reply);
void c_DESTROY(HiRedis__DriverXS obj);
void c_reconnect(HiRedis__DriverXS obj);
int  c_ping(HiRedis__DriverXS obj);
int  c_quit(HiRedis__DriverXS obj);
int  c_multi(HiRedis__DriverXS obj);
int  c_exec(HiRedis__DriverXS obj);
SV*  c_get(HiRedis__DriverXS obj, char* key);
int  c_set(HiRedis__DriverXS obj, char* key, char* value);
//char* eee(char* ret);

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
c_reconnect(HiRedis__DriverXS obj) {
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
    C_SKIP_TRANSACTION();

//    (obj->fn_stack)[0] = &eee;
//    printf("TEST %s\n",(char*)((obj->fn_stack)[0])("drdr"));
}

//char*
//eee(char* ret) {
//	return ret;
//}

int
c_ping(HiRedis__DriverXS obj) {
	redisReply* reply = redisCommand(obj->c,"PING");
	C_RECONNECT_IF_ERROR(c_ping(obj));
	int ret = (reply->type == REDIS_REPLY_STATUS && C_REPLY_EQ(RES_PING)) ? 1 : 0;
	freeReplyObject(reply);
	return ret;
}

int
c_quit(HiRedis__DriverXS obj) {
	C_CONNECT_FREE();
	return 1;
}

//static int c_multi_res(HiRedis__DriverXS obj, redisReply* reply) {
//	if (
//			reply->type == REDIS_REPLY_STATUS &&
//			(
//					(obj->transaction && C_EQ(reply->str,RES_QUEUE)) ||
//					(!obj->transaction && C_EQ(reply->str,RES_OK))
//			)
//	) {
//		;
//	} else {
//
//	}
//}
int
c_multi(HiRedis__DriverXS obj) {
	redisReply* reply = redisCommand(obj->c,"MULTI");
	C_RECONNECT_IF_ERROR(c_multi(obj));
	int ret = (reply->type == REDIS_REPLY_STATUS && C_REPLY_EQ(RES_OK)) ? 1 : 0;
	if (ret) obj->transaction = 1;
	freeReplyObject(reply);
	return ret;
}

int
c_exec(HiRedis__DriverXS obj) {
	redisReply* reply = redisCommand(obj->c,"EXEC");
	C_RECONNECT_IF_ERROR(c_exec(obj));
	unsigned int j;
    if (reply->type == REDIS_REPLY_ARRAY) {
        for (j = 0; j < reply->elements; j++) {
        	_debug_type(reply->element[j]);
            printf("%u) %s\n", j, reply->element[j]->str);
        }
    } else {
    	_debug_type(reply);
//    	Current reply type is REDIS_REPLY_ERROR
//    	Reply response string: ERR EXEC without MULTI

    }

	//int ret = strcasecmp(reply->str,RES_OK) == 0 ? 1 : 0;
	freeReplyObject(reply);
	return 1;
}

SV*
c_get(HiRedis__DriverXS obj, char* key) {
	redisReply* reply = redisCommand(obj->c,"GET %s",key);
	C_RECONNECT_IF_ERROR(c_get(obj,key));
	SV* ret;
	printf("type %d\n",reply->type);
    switch(reply->type) {
    case REDIS_REPLY_ERROR:
    	printf("1\n");
    	break;
    case REDIS_REPLY_STATUS:
    	// queue
    	printf("2\n");
    	ret = newSVpvn("",0);
    	break;
    case REDIS_REPLY_INTEGER:
    	printf("3\n");
    	break;
    case REDIS_REPLY_STRING:
    	// succefull answer
    	printf("4\n");
    	ret = newSVpvn(reply->str,strlen(reply->str));
    	break;
    case REDIS_REPLY_ARRAY:
    	printf("5\n");
    	break;
    default:
    	printf("6\n");
    	// no key
    	ret = NULL;
    }


//    if(reply->type == REDIS_REPLY_STRING) {
//    	ret = newSVpvn(reply->str,strlen(reply->str));
//    } else if (reply->type == REDIS_REPLY_ERROR) {
//    	printf("Error1\n");
//    	if (obj->c->errstr != NULL) {
//    		sprintf(obj->error,"Redis::DriverXS: %s",obj->c->errstr);
//    	} else {
//    		sprintf(obj->error,"Redis::DriverXS: unknown error in 'get'");
//    	};
//    	printf("Error2\n");
//    	ret = NULL;
//    } else {
//    	obj->error = NULL;
//    	printf("Error3\n");
//    	obj->error = "Redis::DriverXS: unknown error in 'get'";
//    	printf("Error4\n");
//    	ret = NULL;
//    };
	freeReplyObject(reply);
	return ret;
}

int
c_set(HiRedis__DriverXS obj, char* key, char* value) {
	redisReply* reply = redisCommand(obj->c,"SET %s %s",key,value);
	C_RECONNECT_IF_ERROR(c_set(obj,key,value));
	int ret = strcasecmp(reply->str,RES_OK) == 0 ? 1 : 0;
	freeReplyObject(reply);
	return ret;
}

void
c_DESTROY(HiRedis__DriverXS obj) {
	free(obj->connect_info);
	obj->connect_info = NULL;
	if(obj->c != NULL) {
		C_CONNECT_FREE();
	}
	free(obj);
	obj = NULL;
}
