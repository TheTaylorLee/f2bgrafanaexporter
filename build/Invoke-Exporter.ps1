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
while ($true) {
    Write-Output "[+] Updating the Exporter Database"

    $datasourcef2b = "/f2bgrafanaexporter/db/$env:fail2bandatabase"
    $datasourcelog = '/f2bgrafanaexporter/db/banlog.sqlite'
    $f2b = Invoke-SqliteQuery -ErrorAction continue -DataSource $DataSourcef2b -Query "Select ip FROM bips"
    $log = Invoke-SqliteQuery -ErrorAction continue -DataSource $DataSourcelog -Query "Select ip FROM banned"

    switch ($log) {
        $null {
            $ips = ($f2b).ip
        }
        default {
            $ips = (Compare-Object ($f2b).ip ($log).ip).inputobject
        }
    }

    if ($null -ne $ips) {
        $insertdata = Get-PublicIP $ips -Sleep 2

        try {
            foreach ($ip in $insertdata) {
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
            }
            $insertdata = $null
        }
        catch {
            Write-Host "Error: $_"
            Write-Host "[-] If the database is locked, stop grafana or close the dashboard, try again, and start grafana" -ForegroundColor green
        }
    }
    else {
        Write-Output "[+] No new IPs to add to the database"
    }

    Start-Sleep -Seconds 3600
}