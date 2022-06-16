/*

    original code from https://github.com/philcrump/longmynd/web/web.c, modified for winterhill use by ZR6TG

*/
#include "../main.h"
#include "../errors.h"
#include "web.h"
#include "json.h"

#include <libwebsockets.h>
#include <stdio.h> // Debug
#include <errno.h> // sleep_ms - EINTR

#define HTDOCS_DIR "./web/htdocs/"

#define WEBSOCKET_OUTPUT_LENGTH 16384 // characters
typedef struct {
    uint8_t buffer[LWS_PRE+WEBSOCKET_OUTPUT_LENGTH];
    uint32_t length;
    uint32_t sequence_id;
    pthread_mutex_t mutex;
    bool new; // Not locked by mutex
} websocket_output_t;

websocket_output_t ws_monitor_output = {
    .length = WEBSOCKET_OUTPUT_LENGTH,
    .sequence_id = 1,
    .mutex = PTHREAD_MUTEX_INITIALIZER,
    .new = false
};

typedef struct websocket_user_session_t websocket_user_session_t;

struct websocket_user_session_t {
    struct lws *wsi;
    websocket_user_session_t *websocket_user_session_list;
    uint32_t last_sequence_id;
};

typedef struct {
    struct lws_context *context;
    struct lws_vhost *vhost;
    const struct lws_protocols *protocol;
    websocket_user_session_t *websocket_user_session_list;
} websocket_vhost_session_t;

enum protocol_ids {
    HTTP = 0,
    WS_MONITOR = 1,
    WS_CONTROL = 2,
    _TERMINATOR = 99
};

/* -------------------------------------------------------------------------------------------------- */
uint64_t timestamp_ms(void) {
/* -------------------------------------------------------------------------------------------------- */
/* Returns current value of a realtime timer in milliseconds                                         */
/* return: realtime timer in milliseconds                                                            */
/* -------------------------------------------------------------------------------------------------- */
    struct timespec tp;

    if(clock_gettime(CLOCK_REALTIME, &tp) != 0)
    {
        return 0;
    }

    return (uint64_t) tp.tv_sec * 1000 + tp.tv_nsec / 1000000;
}

/* -------------------------------------------------------------------------------------------------- */
void sleep_ms(uint32_t _duration)
/* -------------------------------------------------------------------------------------------------- */
/* Pauses the current thread for a given duration in milliseconds                                     */
/*                                                                                                    */
/* -------------------------------------------------------------------------------------------------- */
{
    struct timespec req, rem;
    req.tv_sec = _duration / 1000;
    req.tv_nsec = (_duration - (req.tv_sec*1000))*1000*1000;

    while(nanosleep(&req, &rem) == EINTR)
    {
        req = rem;
    }
}

int callback_ws(struct lws *wsi, enum lws_callback_reasons reason, void *user, void *in, size_t len)
{
    int32_t n;
    websocket_user_session_t *user_session = (websocket_user_session_t *)user;

    websocket_vhost_session_t *vhost_session =
            (websocket_vhost_session_t *)
            lws_protocol_vh_priv_get(lws_get_vhost(wsi),
                    lws_get_protocol(wsi));

    switch (reason)
    {
        case LWS_CALLBACK_PROTOCOL_INIT:
            vhost_session = lws_protocol_vh_priv_zalloc(lws_get_vhost(wsi),
                    lws_get_protocol(wsi),
                    sizeof(websocket_vhost_session_t));
            vhost_session->context = lws_get_context(wsi);
            vhost_session->protocol = lws_get_protocol(wsi);
            vhost_session->vhost = lws_get_vhost(wsi);
            break;

        case LWS_CALLBACK_ESTABLISHED:
            /* add ourselves to the list of live pss held in the vhd */
            lws_ll_fwd_insert(
                user_session,
                websocket_user_session_list,
                vhost_session->websocket_user_session_list
            );
            user_session->wsi = wsi;
            //user_session->last = vhost_session->current;
            break;

        case LWS_CALLBACK_CLOSED:
            /* remove our closing pss from the list of live pss */
            lws_ll_fwd_remove(
                websocket_user_session_t,
                websocket_user_session_list,
                user_session,
                vhost_session->websocket_user_session_list
            );
            break;


        case LWS_CALLBACK_SERVER_WRITEABLE:
            /* Write output data, if data exists */
            /* Look up protocol */
            if(vhost_session->protocol->id == WS_MONITOR)
            {
                pthread_mutex_lock(&ws_monitor_output.mutex);
                if(ws_monitor_output.length != 0 && user_session->last_sequence_id != ws_monitor_output.sequence_id)
                {
                    n = lws_write(wsi, (unsigned char*)&ws_monitor_output.buffer[LWS_PRE], ws_monitor_output.length, LWS_WRITE_TEXT);
                    if (!n)
                    {
                        pthread_mutex_unlock(&ws_monitor_output.mutex);
                        lwsl_err("ERROR %d writing to socket\n", n);
                        return -1;
                    }
                    user_session->last_sequence_id = ws_monitor_output.sequence_id;
                }
                pthread_mutex_unlock(&ws_monitor_output.mutex);
            }
            break;

        case LWS_CALLBACK_RECEIVE:
            if(len >= 8 && strcmp((const char *)in, "closeme\n") == 0)
            {
                lws_close_reason(wsi, LWS_CLOSE_STATUS_GOINGAWAY,
                         (unsigned char *)"seeya", 5);
                return -1;
            }
            if(vhost_session->protocol->id == WS_CONTROL)
            {
                if(len >= 2 && len < 32)
                {
                    char message_string[32];
                    memcpy(message_string, in, len);
                    message_string[len] = '\0';

                    //printf("RX: %s\n", message_string);

                    if(message_string[0] == 'F')
                    {
                        // F{rx},{freq},{SR},{offset}
                        char *token, *str, *tofree;
                        int count = 0;

                        uint32_t freq = 0, sr = 0, rx = 0, offset = 0;

                        tofree = str = strdup(&message_string[1]);  

                        while ((token = strsep(&str, ","))) 
                        {
                            //printf("token: %s\n", token);

                            switch(count)
                            {
                                case 0: rx = (uint32_t)strtol(token,NULL,10); break;
                                case 1: freq = (uint32_t)strtol(token,NULL,10); break;
                                case 2: sr = (uint32_t)strtol(token,NULL,10); break;
                                case 3: offset = (uint32_t)strtol(token,NULL,10); break;
                                default: break;
                            }

                            count += 1;
                        }

                        
                        configurefrequency(rx, freq, offset, sr);


                    }
                    else if(message_string[0] == 'U')
                    {
                        // U{rx}{udp_host}
                        char *field2_ptr;
                        char *udp_host;
                        int rx;

                        field2_ptr = memchr(message_string, ',', len);

                        if(field2_ptr != NULL)
                        {
                            field2_ptr[0] = '\0';

                            rx = (int)strtol(&message_string[1],NULL,10);
                            udp_host = &field2_ptr[1];

                            //printf("rx: %i\n", rx );
                            //printf("udp_host: %s\n", udp_host );

                            configureip(rx,udp_host);
                        }
                    }
                }
            }
            break;
        
        default:
            break;
    }

    return 0;
}

static struct lws_protocols protocols[] = {
    {
        .id = 0,
        .name = "http",
        .callback = lws_callback_http_dummy,
        .per_session_data_size = 0,
        .rx_buffer_size = 0,
    },
    {
        .id = 1,
        .name = "monitor",
        .callback = callback_ws,
        .per_session_data_size = 128,
        .rx_buffer_size = 4096,
    },
    {
        .id = 2,
        .name = "control",
        .callback = callback_ws,
        .per_session_data_size = 128,
        .rx_buffer_size = 4096,
    },
    {
        0 /* terminator, .id = 0 */
    }
};

/* default mount serves the URL space from ./mount-origin */

static const struct lws_http_mount mount_opts = {
    /* .mount_next */       NULL,        /* linked-list "next" */
    /* .mountpoint */       "/",        /* mountpoint URL */
    /* .origin */           HTDOCS_DIR,   /* serve from dir */
    /* .def */              "index.html",   /* default filename */
    /* .protocol */         NULL,
    /* .cgienv */           NULL,
    /* .extra_mimetypes */      NULL,
    /* .interpret */        NULL,
    /* .cgi_timeout */      0,
    /* .cache_max_age */        0,
    /* .auth_mask */        0,
    /* .cache_reusable */       0,
    /* .cache_revalidate */     0,
    /* .cache_intermediaries */ 0,
    /* .origin_protocol */      LWSMPRO_FILE,   /* files in a dir */
    /* .mountpoint_len */       1,      /* char count */
    /* .basic_auth_login_file */    NULL,
    /* __dummy */ { 0 },
};


static void web_status_json(char **status_string_ptr, rxcontrol *rcv)
{
    JsonNode *statusObj;
    JsonNode *statusPacketObj;
    JsonNode *receiverArrayObj;   
    
    statusObj = json_mkobject();

    json_append_member(statusObj, "type", json_mkstring("status"));
    json_append_member(statusObj, "timestamp", json_mknumber(((double)timestamp_ms())/1000));

    int rx = 0;

    receiverArrayObj = json_mkarray();
    for (rx = 0 ; rx <= MAXRECEIVERS ; rx++)
    {
        statusPacketObj = json_mkobject();
        json_append_member(statusPacketObj, "rx", json_mknumber(rcv[rx].receiver));       
        json_append_member(statusPacketObj, "scanstate", json_mknumber(rcv[rx].scanstate));       
        json_append_member(statusPacketObj, "ts_addr", json_mkstring(rcv[rx].ipaddress));       
        json_append_member(statusPacketObj, "ts_port", json_mknumber(rcv[rx].tsport));       
        json_append_member(statusPacketObj, "service_name", json_mkstring(rcv[rx].textinfos[STATUS_SERVICE_NAME]));       
        json_append_member(statusPacketObj, "service_provider_name", json_mkstring(rcv[rx].textinfos[STATUS_SERVICE_PROVIDER_NAME]));       
        json_append_member(statusPacketObj, "mer", json_mkstring(rcv[rx].textinfos[STATUS_MER]));       
        json_append_member(statusPacketObj, "frequency", json_mkstring(rcv[rx].textinfos[STATUS_CARRIER_FREQUENCY]));       
        json_append_member(statusPacketObj, "symbol_rate", json_mkstring(rcv[rx].textinfos[STATUS_SYMBOL_RATE]));       
        json_append_member(statusPacketObj, "null_percentage", json_mkstring(rcv[rx].textinfos[STATUS_TS_NULL_PERCENTAGE ]));       
        json_append_member(statusPacketObj, "state", json_mkstring(rcv[rx].textinfos[STATUS_STATE]));       
        json_append_member(statusPacketObj, "dbmargin", json_mkstring(rcv[rx].textinfos[STATUS_DNUMBER]));       
        json_append_member(statusPacketObj, "video_type", json_mkstring(rcv[rx].textinfos[STATUS_VIDEO_TYPE]));       
        json_append_member(statusPacketObj, "audio_type", json_mkstring(rcv[rx].textinfos[STATUS_AUDIO_TYPE]));       
        json_append_member(statusPacketObj, "modcod", json_mkstring(rcv[rx].textinfos[STATUS_MODCOD]));       
        json_append_element(receiverArrayObj, statusPacketObj);
    }

    json_append_member(statusObj, "rx", receiverArrayObj);

    *status_string_ptr = json_stringify(statusObj, NULL);

    json_delete(statusObj);

}



/* Websocket Service Thread */
static struct lws_context *context;
static pthread_t ws_service_thread;

void *ws_service(void *arg)
{
    printf("ws service");

    thread_vars_t *thread_vars = (thread_vars_t *)arg;
    uint8_t *err = &thread_vars->thread_err;
    int lws_err = 0;

    while (*err == ERROR_NONE )
    {
        lws_err = lws_service(context, 0);
        if(lws_err < 0)
        {
            printf(stderr, "Web: lws_service() reported error: %d\n", lws_err);
            *err = ERROR_WEB_LWS;
        }
    }

    return NULL;
}

void *loop_web(void *arg)
{
    thread_vars_t *thread_vars = (thread_vars_t *)arg;
    uint8_t *err = &thread_vars->thread_err;

    rxcontrol *rcv_ptr = thread_vars->rcv;

    int status_json_length;
    char *status_json_str;
    //static longmynd_status_t status_cache;

    struct lws_context_creation_info info;
    int logs = LLL_USER | LLL_ERR | LLL_WARN ; // | LLL_NOTICE;

    lws_set_log_level(logs, NULL);

    memset(&info, 0, sizeof info);

    info.options = LWS_SERVER_OPTION_VALIDATE_UTF8 | LWS_SERVER_OPTION_EXPLICIT_VHOSTS;
    context = lws_create_context(&info); 
    if (!context)
    {
        printf("LWS: Init failed.\n");
        return NULL;
    }

    info.vhost_name = "localhost";
    info.port = 8080;
    info.mounts = &mount_opts;
    info.error_document_404 = "/404.html";
    info.protocols = protocols;

    if(!lws_create_vhost(context, &info))
    {
        printf("LWS: Failed to create vhost\n");
        lws_context_destroy(context);
        return NULL;
    }

    /* Create dedicated ws server thread */
    if(0 != pthread_create(&ws_service_thread, NULL, ws_service, (void *)thread_vars))
    {
        printf(stderr, "Error creating web_lws pthread\n");
    }

    uint64_t last_status_sent_monotonic = 0;

    while (*err == ERROR_NONE )
    {
            web_status_json(&status_json_str, rcv_ptr);
            status_json_length = strlen(status_json_str);

            pthread_mutex_lock(&ws_monitor_output.mutex);
            memcpy(&ws_monitor_output.buffer[LWS_PRE], status_json_str, status_json_length);
            ws_monitor_output.length = status_json_length;
            ws_monitor_output.sequence_id++;
            pthread_mutex_unlock(&ws_monitor_output.mutex);

            lws_callback_on_writable_all_protocol(context, &protocols[WS_MONITOR]);


        sleep_ms(500);
    }

    if(*err == ERROR_NONE)
    {
        /* Interrupt service thread */
        lws_cancel_service(context);
    }
    pthread_join(ws_service_thread, NULL);

    lws_context_destroy(context);

    return NULL;
}
