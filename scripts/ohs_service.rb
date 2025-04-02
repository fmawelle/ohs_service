
####  Run OHS as a Windows Service
####  Credit to https://github.com/chef
####  Provide the appropriate path for the following variables.
#### The values provided below are merely examples.
#### Make changes appriopriate to your enviroment
LOG_FILE = 'Z:\\Oracle\\logs\\OHS_Service.log'
OHS_START_CMD = "Z:\\Oracle\\domains\\ohs_domain\\bin\\startComponent.cmd ohs1"
OHS_STOP_CMD = "Z:\\Oracle\\domains\\ohs_domain\\bin\\stopComponent.cmd ohs1"

# OHS process id file. I have into situations where the process id file 
# was not correctly deleted after ohs stops and the process id
# is now being referenced by a different process 
# and ohs "thinks" it is still running based on pid.
OHS_PID_FILE = "Z:\\Oracle\\domains\\ohs_domain\\servers\\ohs1\\logs\\httpd.pid"

begin
  require "rubygems"
  require "win32/daemon"
  include Win32

  class OhsDaemon < Daemon
    # This method fires off before the +service_main+ mainloop is entered.
    # Any pre-setup code you need to run before your service's mainloop
    # starts should be put here. Otherwise the service might fail with a
    # timeout error when you try to start it.
    #
    def service_init
      # Dir.mkdir("C:/Tmp") unless File.exist?("C:/Tmp")
      File.open(LOG_FILE, "a") { |f| f.puts "**********************************************************" }
      msg =  Time.now.to_s + ":  Initializing service."
      File.open(LOG_FILE, "a") { |f| f.puts msg }
    end

    # This is the daemon's mainloop. In other words, whatever runs here
    # is the code that runs while your service is running. Note that the
    # loop is not implicit.
    #
    # You must setup a loop as I've done here with the 'while running?'
    # code, or setup your own loop. Otherwise your service will exit and
    # won't be especially useful.
    #
    #
    def service_main(*args)
      msg = Time.now.to_s + ":  Starting service. Waiting for results from the WebLogic Scripting Tool (WLST)."
      File.open(LOG_FILE, "a") { |f| f.puts msg }

      startOhs
      
      # While we're in here the daemon is running.
      while running?
        if state == RUNNING
          ## check every 60 seconds if OHS is running; adjust to your liking.
          sleep 60
          if (!isOhsRunning)
            startOhs
          end
        else # PAUSED or IDLE. Pausing the service does not stop/pause ohs.
          sleep 0.5
        end
      end

      # We've left the loop, the daemon is about to exit.

      File.open(LOG_FILE, "a") { |f| f.puts Time.now.to_s + ":  STATZ: #{state}" }

      msg = Time.now.to_s + ":  Stopping service."

      File.open(LOG_FILE, "a") { |f| f.puts msg }
    end

    # This event triggers when the service receives a signal to stop.
    #
    def service_stop
      msg = Time.now.to_s + ":  Received stop signal."
      File.open(LOG_FILE, "a") { |f| f.puts msg }
      # system("OHS_STOP_CMD")
      result = %x[ #{OHS_STOP_CMD} ]
      File.open(LOG_FILE, "a") { |f| f.puts result.split('\n') }
    end

    # This event triggers when the service receives a signal to pause.
    #
    def service_pause
      msg = Time.now.to_s + ":  Received pause signal."
      File.open(LOG_FILE, "a") { |f| f.puts msg }
    end

    # This event triggers when the service receives a signal to resume
    # from a paused state.
    #
    def service_resume
      msg = Time.now.to_s + ":  Received resume signal."
      File.open(LOG_FILE, "a") { |f| f.puts msg }
    end

    # Check if OHS is currently running
    # It is used to restart ohs if, for some reason, 
    # it is unxepectedly stopped.
    def isOhsRunning
        file_exists = File.exist?(OHS_PID_FILE)
        httpd_process = "httpd"
        isRunning = false
        msg = ""
        if file_exists
            ohs_process_id = File.read(OHS_PID_FILE)
            command = "pwsh.exe -Command (Get-Process -id " + ohs_process_id.chomp + ").ProcessName"
            # File.open(LOG_FILE, "a") { |f| f.puts command }
            result = %x[#{command}]
            if (result.chomp == httpd_process)
                isRunning = true;
            else
                msg = "OHS is no longer running under process id: " + ohs_process_id
            end            
        else # PID file does not exist.
            command = "pwsh.exe -Command (Get-Process -name " + httpd_process + ").ProcessName"
            result = %x[#{command}]
            # File.open(LOG_FILE, "a") { |f| f.puts command }            
            process_name = result.split()[0]

            if (process_name == httpd_process)
                isRunning = true
                msg = Time.now.to_s + ":  OHS is running but the process id file is no longer available. This may result to inconsistent state for the server."
                File.open(LOG_FILE, "a") { |f| f.puts  msg}
            else
                isRunning = false
                msg = "OHS is no longer running. Attempting to restart now."            
            end
        end 
        isRunning ? "Do nothing" :  File.open(LOG_FILE, "a") { |f| f.puts  msg}
        return isRunning
    end

    def startOhs
        result = %x[ #{OHS_START_CMD} ]
        File.open(LOG_FILE, "a") { |f| f.puts result.split('\n') }
    end
  end

  # Create an instance of the Daemon and put it into a loop. 
  #
  OhsDaemon.mainloop
rescue Exception => err
  File.open(LOG_FILE, "a") { |fh| fh.puts "Daemon failurZ: #{err}" }
  raise
end
