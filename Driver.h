#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>
#include "hiredis.h"

#define RES_STATUS_PING "PONG"
#define RES_STATUS_QUEUE "QUEUED"
#define RES_STATUS_OK "OK"

#define RES_MULTI_ERROR "ERR EXEC without MULTI"

#define RES_UNDEF "0E0"
#define RES_EMPTY_STR "0E00"

#define C_PACKAGE_DEBUG 0
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

// connect free
#define C_CONNECT_FREE() \
	redisFree(obj->c); \
	obj->c = NULL;

/*
 * type definition --------------------------------------
 */
typedef struct st_hdr_connect_info {
    char *host;
    unsigned int port;
} RDXS_connect_info;

typedef struct st_hdr_obj {
		redisContext* c;
        RDXS_connect_info *connect_info;
} *HiRedis__Driver;

/*
 * describe function -------------------------------------
 */
static void _debug_type(redisReply* reply);
SV*  c_response(redisReply* reply);
void c_reconnect(HiRedis__Driver obj);
int  c_quit(HiRedis__Driver obj);
short int c_shutdown(HiRedis__Driver obj);
SV*  c_command(HiRedis__Driver obj, char* cmd, char* param[], int len);
void c_DESTROY(HiRedis__Driver obj);

/*
 * function definition ------------------------------------
 */

/*
 * debug helper
 */
static void
_debug_type(redisReply* reply) {
	printf("*********\n");
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
    printf("*********\n");
}

/*
 * response processor
 */
SV*
c_response(redisReply* reply) {
	SV* ret;
	AV* ret_array;
	unsigned int j;

    switch(reply->type) {
    case REDIS_REPLY_STATUS:
		if (!strcasecmp(reply->str,RES_STATUS_PING)) {
			ret = newSViv(1);
		} else if (!strcasecmp(reply->str,RES_STATUS_QUEUE)) {
			ret = newSViv(1);
		} else if (!strcasecmp(reply->str,RES_STATUS_OK)) {
			ret = newSViv(1);
		} else {
			ret = newSVpvn(reply->str,strlen(reply->str));
		}
		break;
    case REDIS_REPLY_ERROR:
    	if (!strcasecmp(reply->str,RES_MULTI_ERROR)) {
    		// non fatal error
    		ret = newSV(0);
    	} else {
    		// ERR wrong number of arguments for 'set' command
    		// unkown error
    		croak("Unknown REDIS_REPLY_ERROR case. Hiredis reply: %s",reply->str);
    	}
    	break;
    case REDIS_REPLY_INTEGER:
    	ret = newSViv(reply->integer);
    	break;
    case REDIS_REPLY_STRING:
    	if (!strcasecmp(reply->str,RES_UNDEF)) {
    		ret = newSV(0);
    	} else if (!strcasecmp(reply->str,RES_EMPTY_STR)) {
    		ret = newSVpvn("",strlen(""));
    	} else {
			ret = newSVpvn(reply->str,strlen(reply->str));
    	}
    	break;
    case REDIS_REPLY_ARRAY:
    	ret_array = newAV();
        for (j = 0; j < reply->elements; j++) {
        	av_push(ret_array,c_response(reply->element[j]));
        }
        ret = newRV_noinc((SV*)ret_array);
        break;
    default:
    	ret = newSV(0);
    }

	return ret;
}

/*
 * reconnect
 */
void
c_reconnect(HiRedis__Driver obj) {
	if (!obj->connect_info->host) {
		croak(C_PACKAGE_ERROR,"'host' not defined, when call connect");
	};
	obj->c = redisConnect(obj->connect_info->host, obj->connect_info->port);
    if (obj->c->err != 0) {
    	char* error = obj->c->errstr;
    	C_CONNECT_FREE();
    	croak(C_PACKAGE_ERROR,error);
    };
}

/*
 * quit
 */
int
c_quit(HiRedis__Driver obj) {
	if (obj->c == NULL) return 1;
	C_CONNECT_FREE();
	return 1;
}

/*
 * shutdown
 */
short int
c_shutdown(HiRedis__Driver obj) {
	if (obj->c == NULL) return 0;
	redisReply* reply = redisCommand(obj->c,"SHUTDOWN");
	if(reply != NULL) freeReplyObject(reply);
	C_CONNECT_FREE();
	return 1;
}

/*
 * Main command-function for hiredis interface
 * 1. Create format string, like so "SET %s %s"
 * 2. Call hiredis and getting redisReply pointer
 * 3. If redis return error of connection, reconnect
 * 4. Create return scalar value
 */
SV*
c_command(HiRedis__Driver obj, char* cmd, char* param[], int len) {
	// 1. Create format string, like so "SET %s %s"
	int siz = strlen(cmd)+strlen(" %s")*len;
	char format[siz];
	memset(format, 0, sizeof(format));
	strcat(format,cmd);
	unsigned int j;
	for (j = 0; j < len; j++) {
	  	strcat(format," %s");
	};
	// debug printf format and argument
	if (C_PACKAGE_DEBUG) {
		printf("*********\n");
		printf("%s\n",(char*)format);
		unsigned int j;
        for (j = 0; j < len; j++) {
        	printf("%d) %s\n",j,param[j]);
        };
        printf("*********\n");
	}
	// 2. Call hiredis and getting redisReply pointer
	redisReply* reply = redisvCommand(obj->c,(char*)format,(va_list)param);
	// 3. If redis return error of connection, reconnect
	if (obj->c->errstr) {
		c_reconnect(obj);
		return c_command(obj,cmd,param,len);
	};
	// print some debug info if C_PACKAGE_DEBUG is true
	if (C_PACKAGE_DEBUG) _debug_type(reply);
	// 4. Create return scalar value
    SV* ret = c_response(reply);
    freeReplyObject(reply);
    return ret;
}

/*
 * destroy with disconnect
 */
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
