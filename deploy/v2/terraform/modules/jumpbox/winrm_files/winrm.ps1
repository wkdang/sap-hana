Write-Host "Opening firewall ports.."
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5986
netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow protocol=TCP localport=5985

Write-Host "Enabling basic authentication for WinRM service.."
winrm set winrm/config/service/Auth "@{Basic=`"true`"}"

Write-Host "Allowing HTTP traffic on WinRM service.."
winrm set winrm/config/service "@{AllowUnencrypted=`"true`"}"

Write-Host "Enabling basic authentication for WinRM client.."
winrm set winrm/config/client/Auth "@{Basic=`"true`"}"

Write-Host "Allowing HTTP traffic on WinRM client.."
winrm set winrm/config/client "@{AllowUnencrypted=`"true`"}"

Write-Host "Enabling powershell remoting.."
Enable-PSRemoting -Force

Write-Host "Restarting WinRM.."
net stop winrm
net start winrm
