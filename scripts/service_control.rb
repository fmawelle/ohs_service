############################################################################
# service_control.rb
#
# To run the service, you must install it first.
# this command line script will help you install the service.
#
# Usage: ruby service_control.rb <option>
#
# Note that you *must* pass this program an option
#
# Options:
#    install    - Installs the service. 
#    start      - Starts the service.  
#    stop       - Stops the service.
#    pause      - Pauses the service. ohs will continue running although the service is paused
#    resume     - Resumes the service.
#    uninstall  - Uninstalls the service.
#    delete     - Same as uninstall.
#
# You can also used the Windows Services GUI to start and stop the service.
#
# To get to the Windows Services GUI just follow:
#    Start -> Control Panel -> Administrative Tools -> Services
############################################################################
require "win32/service"
require "rbconfig"
include Win32
include RbConfig

# Make sure you're using the version you think you're using.
puts "VERSION: " + Service::VERSION

SERVICE_NAME = "OHS_Service"
SERVICE_DISPLAYNAME = "Oracle HTTP Server (Custom Service)"

# add if you want dependency with Node Manager
DEPENDENCIES = ["Oracle Weblogic ohs_domain NodeManager"]

# Quote the full path to deal with possible spaces in the path name.
ruby = File.join(CONFIG["bindir"], CONFIG["ruby_install_name"]).tr("/", '\\')
path = ' "' + File.dirname(File.expand_path($0)).tr("/", '\\')
path += '\ohs_service.rb"'
cmd = ruby + path

# You must provide at least one argument.
raise ArgumentError, "No argument provided" unless ARGV[0]

case ARGV[0].downcase
   when "install"
     Service.new(
        service_name: SERVICE_NAME,
        display_name: SERVICE_DISPLAYNAME,
        description: SERVICE_DISPLAYNAME,
        dependencies: DEPENDENCIES,
        binary_path_name: cmd
      )
     puts "Service " + SERVICE_NAME + " installed"
   when "start"
     if Service.status(SERVICE_NAME).current_state != "running"
       Service.start(SERVICE_NAME, nil, "Z:\\Oracle\\domains\\ohs_domain\\bin\\startComponent.cmd ohs1")
       while Service.status(SERVICE_NAME).current_state != "running"
         puts "One moment..." + Service.status(SERVICE_NAME).current_state
         sleep 1
       end
       puts "Service " + SERVICE_NAME + " started"
     else
       puts "Already running"
     end
   when "stop"
     if Service.status(SERVICE_NAME).current_state != "stopped"
       Service.stop(SERVICE_NAME)
       while Service.status(SERVICE_NAME).current_state != "stopped"
         puts "One moment..." + Service.status(SERVICE_NAME).current_state
         sleep 1
       end
       puts "Service " + SERVICE_NAME + " stopped"
     else
       puts "Already stopped"
     end
   when "uninstall", "delete"
     if Service.status(SERVICE_NAME).current_state != "stopped"
       Service.stop(SERVICE_NAME)
     end
     while Service.status(SERVICE_NAME).current_state != "stopped"
       puts "One moment..." + Service.status(SERVICE_NAME).current_state
       sleep 1
     end
     Service.delete(SERVICE_NAME)
     puts "Service " + SERVICE_NAME + " deleted"
   when "pause"
     if Service.status(SERVICE_NAME).current_state != "paused"
       Service.pause(SERVICE_NAME)
       while Service.status(SERVICE_NAME).current_state != "paused"
         puts "One moment..." + Service.status(SERVICE_NAME).current_state
         sleep 1
       end
       puts "Service " + SERVICE_NAME + " paused"
     else
       puts "Already paused"
     end
   when "resume"
     if Service.status(SERVICE_NAME).current_state != "running"
       Service.resume(SERVICE_NAME)
       while Service.status(SERVICE_NAME).current_state != "running"
         puts "One moment..." + Service.status(SERVICE_NAME).current_state
         sleep 1
       end
       puts "Service " + SERVICE_NAME + " resumed"
     else
       puts "Already running"
     end
   else
     raise ArgumentError, "unknown option: " + ARGV[0]
end