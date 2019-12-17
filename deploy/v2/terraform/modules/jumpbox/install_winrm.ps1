# Opening firewall ports
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5986
netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow protocol=TCP localport=5985

# Enabling basic authentication for WinRM service
winrm set winrm/config/service/Auth "@{Basic=`"true`"}"

# Allowing HTTP traffic on WinRM service
winrm set winrm/config/service "@{AllowUnencrypted=`"true`"}"

# Enabling basic authentication for WinRM client
winrm set winrm/config/client/Auth "@{Basic=`"true`"}"

# Allowing HTTP traffic on WinRM client
winrm set winrm/config/client "@{AllowUnencrypted=`"true`"}"

# Enabling powershell remoting
Enable-PSRemoting -Force

# Restarting WinRM
net stop winrm
net start winrm
