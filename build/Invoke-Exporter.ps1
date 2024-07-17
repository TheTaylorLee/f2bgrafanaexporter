# Start Transcript
$date = Get-Date -Format "yyyy-MM-dd-hh-mm"
Start-Transcript /f2bgrafanaexporter/logs/"$date"_exporter.log

# Delete old log files
Write-Output "[+] Deleting old log files"
Get-ChildItem -Path /f2bgrafanaexporter/logs/ |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-14) } |
    Remove-Item

##################################################
# Import needed modules
Import-Module '/f2bgrafanaexporter/run/PSSQLite/1.1.0/PSSQLite.psd1'
Import-Module '/f2bgrafanaexporter/run/AdminToolbox.Networking/AdminToolbox.Networking.psd1'

##################################################
# Setup the Exporter Database
$datasource = '/f2bgrafanaexporter/db/banlog.sqlite'
if ((Test-Path $datasource) -eq $false) {
    function Invoke-DBSetup {

        [CmdletBinding()]
        Param (
            [Parameter(Mandatory = $true)][string[]]$DataSource
        )

        # Create Banned IPs Table
        $Tablename = "banned"
        $Query = "CREATE TABLE $TableName (ip TEXT, hostname TEXT, city TEXT, region TEXT, country TEXT, location TEXT, organization TEXT, phone TEXT)"
        Invoke-SqliteQuery -Query $Query -DataSource $DataSource
    }

    Write-Output "[+] Creating the Exporter Database"
    invoke-dbsetup $datasource
}
else {
    Write-Output "[+] Exporter Database already exists, skipping creation"
}

##################################################
# Update the Exporter Database
$datasourcef2b = "/f2bgrafanaexporter/db/$env:fail2bandatabase"
$datasourcelog = '/f2bgrafanaexporter/db/banlog.sqlite'

while (((Test-Path $datasourcef2b) -eq $true) -and ((Test-Path $datasourcelog) -eq $true)) {
    Write-Output "[+] Updating the Exporter Database"

    $datasourcef2b = "/f2bgrafanaexporter/db/$env:fail2bandatabase"
    $datasourcelog = '/f2bgrafanaexporter/db/banlog.sqlite'
    $f2b = Invoke-SqliteQuery -ErrorAction continue -DataSource $DataSourcef2b -Query "Select ip FROM bips"
    $log = Invoke-SqliteQuery -ErrorAction continue -DataSource $DataSourcelog -Query "Select ip FROM banned"

    if ($null -eq $log) {
        $ips = ($f2b).ip
    }
    else {
        $ips = (Compare-Object ($f2b).ip ($log).ip).inputobject
    }


    if ($null -ne $ips) {
        try {
            foreach ($ipquery in $ips) {
                if ($ipinfotoken) {
                    $ip = Get-PublicIP -IP $ipquery -Token $ipinfotoken -Sleep 2
                }
                else {
                    $ip = Get-PublicIP -IP $ipquery -Sleep 2
                }

                $query = "INSERT INTO banned (ip, hostname, city, region, country, location, organization, phone) Values (@ip, @hostname, @city, @region, @country, @location, @organization, @phone)"
                Invoke-SqliteQuery -ErrorAction stop -DataSource $datasourcelog -Query $query -SqlParameters @{
                    ip           = $ip.ip
                    hostname     = $ip.hostname
                    city         = $ip.city
                    region       = $ip.region
                    country      = $ip.country
                    location     = $ip.location
                    organization = $ip.organization
                    phone        = $ip.phone
                }
                $ip = $null
            }
        }
        catch {
            Write-Output "[-] Error: $_"
        }
    }
    else {
        Write-Output "[+] No new IPs to add to the database"
    }

    Write-Output "[+] Paused for 1 hour before checking for new IPs again"
    Start-Sleep -Seconds 3600
}

Write-Output "[-] Fail2Ban database not found"