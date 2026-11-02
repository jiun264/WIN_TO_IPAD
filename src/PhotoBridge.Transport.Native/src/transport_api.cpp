#include "photobridge/transport_api.h"

#include <string>

namespace {
thread_local std::string last_error;
}

pb_result pb_start_server(uint16_t port, const char* manifest_json)
{
    if (port == 0 || manifest_json == nullptr) {
        last_error = "Port and photo manifest are required.";
        return PB_RESULT_INVALID_ARGUMENT;
    }

    last_error = "The native LAN transport server has not been implemented yet.";
    return PB_RESULT_NOT_IMPLEMENTED;
}

pb_result pb_stop_server(void)
{
    last_error = "The native LAN transport server has not been implemented yet.";
    return PB_RESULT_NOT_IMPLEMENTED;
}

const char* pb_get_last_error(void)
{
    return last_error.c_str();
}
