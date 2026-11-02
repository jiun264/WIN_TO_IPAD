#pragma once

#include <stdint.h>

#if defined(_WIN32)
#define PB_API __declspec(dllexport)
#else
#define PB_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef enum pb_result {
    PB_RESULT_OK = 0,
    PB_RESULT_INVALID_ARGUMENT = 1,
    PB_RESULT_NOT_IMPLEMENTED = 2,
    PB_RESULT_INTERNAL_ERROR = 3
} pb_result;

PB_API pb_result pb_start_server(uint16_t port, const char* manifest_json);
PB_API pb_result pb_stop_server(void);
PB_API const char* pb_get_last_error(void);

#ifdef __cplusplus
}
#endif
