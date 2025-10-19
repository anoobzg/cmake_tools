#pragma once

#include <string>
#include <vector>
#include <map>
#include <functional>

class wxApp;
class wxFrame;
class wxPanel;
class FrameworkContext
{
public:
    virtual wxApp* app() = 0;
    virtual wxFrame* mainframe() = 0;

    //command
    virtual void execute_cmd(const std::string& cmd, const std::vector<std::string>& args) = 0; // framework execute 
    virtual void broadcast_cmd(const std::string& cmd, const std::vector<std::string>& args) = 0;  //broadcast to modules
    virtual void broadcast_json_cmd(const std::string& cmd, const std::string& json_arg) = 0;

    virtual std::string resource_path() = 0;
    virtual std::pair<int, char**>  run_params() = 0;
};

class FrameworkModule
{
public:
    virtual ~FrameworkModule() {};

    virtual std::string name() = 0;
    virtual wxPanel* panel() = 0;

    virtual bool init(std::string* error = nullptr) = 0;
    virtual bool deinit() = 0;

    virtual void execute_cmd(const std::string& cmd, const std::vector<std::string>& args) = 0;  //work as cmdline
    virtual void execute_json_cmd(const std::string& cmd, const std::string& json_arg) = 0;
};

typedef FrameworkModule* (*CreateFunction)(FrameworkContext* context);