#pragma once

#include <string>
#include <functional>

struct FrameworkModuleInfo
{
    std::string name;
    std::string icon;
    std::string version;
    std::string description;
    std::string modify_time;

    std::string interface_version;
};

typedef void (*ReadInfoFunction)(FrameworkModuleInfo& info);
