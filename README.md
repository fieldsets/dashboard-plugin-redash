

## Installation
Edit Fieldsets `./plugins/docker-compose.yml` to include our plugin. Copy `env.example` to `.env` and make necessary changes

```
version: '3.7'

include:
  - path: ./dashboard-plugins-redash/docker-compose.yml
    project_directory: ./dashboard-plugins-redash/
    env_file: ./dashboard-plugins-redash/.env
```