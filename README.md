# f2bgrafanaexporter
I created this container as a way to generate a fail2ban grafana dashboard when running fail2ban in a container as well. All the exporter solutions I could find relied on fail2ban running on metal and not in a container. This solution will work with either scenario.

f2bgrafanaexporter will log all ban instances without clearing old entries. If your jails don't perma ban and the desire is to only show statistics for actively banned addresses, then this isn't the solution for you. f2bgrafanaexporter will update the dashboard once an hour.

## Deploying the image
### Compose Example
```yml
services:
  f2bgrafanaexporter:
    image: ghcr.io/thetaylorlee/f2bgrafanaexporter:latest
    container_name: f2bgrafanaexporter
    environment:
      - fail2bandatabase='fail2ban.sqlite3' # This is the name of your fail2ban database. If your f2b install uses a different database name then this should be different.
    volumes:
      - /home/user/docker/fail2ban:/f2bgrafanaexporter/db # This is where the existing fail2ban database is stored and where the exporter db will be stored
      - /home/user/docker/f2bgrafanaexporter/logs:/f2bgrafanaexporter/logs # This volume is where logs will be stored
    network_mode: none
    restart: unless-stopped
  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    privileged: true
    environment:
      - PUID=0
      - PGID=0
      - TZ=Chicago/Illinois
    ports:
      - "3000:3000"
    volumes:
      - /home/user/docker/grafana/grafana-data:/var/lib/grafana # Grafana config files
      - /home/user/docker/appdata/fail2ban:/f2bgrafanaexporter/db # fail2ban exporter database location
```

## Importing the Grafana Dashboard after the container has been started
1. In grafana install the sqlite plugin at Administration > Plugins and Data > Plugins
2. Navigate to datasources and add a new sqlite datasource
  - Name it f2b
  - For path enter /f2bgrafanaexporter/db/banlog.sqlite
  - click Save & Test
3. Navigate to Dashboards, click new, and Import.
  - Download the grafana.json file from this repository and upload it.
  - Click load

![Grafana Dashboard](https://raw.githubusercontent.com/TheTaylorLee/f2bgrafanaexporter/main/images/grafana.png)