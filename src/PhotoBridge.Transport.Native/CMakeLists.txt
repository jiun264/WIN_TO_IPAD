add_library(PhotoBridge.Transport.Native SHARED
    src/transport_api.cpp
)

target_include_directories(PhotoBridge.Transport.Native
    PUBLIC include
)

target_compile_features(PhotoBridge.Transport.Native PRIVATE cxx_std_20)

set_target_properties(PhotoBridge.Transport.Native PROPERTIES
    OUTPUT_NAME "PhotoBridge.Transport.Native"
)
