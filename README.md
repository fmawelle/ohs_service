# OHS Windows Service

## Create Oracle HTTP Server (OHS) Windows Service

If you want to create a Windows service for your OHS, you are in the right place.

On windows, the only way provided by Oracle is to start OHS 12c via command line (Doc ID 1946552.1). 

That means when you reboot your system, OHS will not automatically start. You can create a PowerShell script to run via Task scheduler to do the job. However, I found that creating a service was a much cleaner solution as all other processes already have services defined.

So, I borrowed a solution that is used by PeopleSoft dpk scripts i.e. create a Windows Service using Ruby.

We shall create two files based on examples I got here <https://github.com/chef/win32-service>

- `ohs_service.rb` - This is the file that will contain the logic to start and stop ohs service. It also ensures ohs is restarted in an event of unexpected failure.
- `service_control.rb` - We use this to install the service and also run the service via command line for testing.

## Installing the ohs_service

- I am assuming the following:
  - You already have ruby installed
  - You have a working instance of OHS already
  - You have elevated access to install services on your Windows server
  - You have added ruby to the path environment enviroment variable (no worries if you haven't).
 
- To install the service:
  - Down and place the two files `ohs_service.rb` and `service_control.rb` in a convenient location
  - Make changes to the `ohs_service.rb` file to provide the following:
    - `LOG_FILE` -path to your log file
    - `OHS_START_CMD` e.g `Z:\\Oracle\\domains\\ohs_domain\\bin\\startComponent.cmd ohs1`
    - `OHS_STOP_CMD` e.g. `"Z:\\Oracle\\domains\\ohs_domain\\bin\\stopComponent.cmd ohs1"`
    - `OHS_PID_FILE` we use this to check the status of the ohs process by process. Usually this is the same folder as the OHS server log directory.
  - Add the OHS Start command string to the `service_control.rb` file as well for when the `start` command is issued.
  - Open command prompt or powershell and change directory to the location of the ruby scripts
  - If ruby is in your path environment variable, they use `ruby service_control.rb install` to install the service
  - If ruby is NOT in your path variable, you can specify the ruby executable as follows e.g `Z:\Oracle\psft_puppet_agent\bin\ruby.exe service_control.rb install`

  ## Starting and Stopping OHS Service

  - After successfully installing the service, you should be able to start and stop it using the Windows Services app like any other windows service.
 
  ## Uninstall the service

  - Run `<path to ruby executable>\bin\ruby.exe service_control.rb delete`
  - Or  run `<path to ruby executable>\bin\ruby.exe service_control.rb uninstall`
 
  ## Warranty

  The code here is provided "as is" with no warranties whatsoever, express or implied. By using it, you assume any and all risks.

  ## Credits
  Credit to the folks at <https://github.com/chef> who created the win32-service package and the examples upon which this is based.
  
