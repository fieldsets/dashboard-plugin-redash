

## Installation
Copy `env.example` to top level `.env` and make necessary changes

`git clone --recurse-submodules https://github.com/fieldsets/dashboard-plugin-redash`

Install plugin dependency
`git clone --recurse-submodules https://github.com/fieldsets/cache-plugin-redis`


Add to `/plugins/docker-compose.yml``
```
version: '3.7'

include:
  - path: ./cache-plugin-redis/docker-compose.yml
    project_directory: ${FIELDSETS_PLUGIN_PATH:-./plugins/}cache-plugin-redis/
  - path: ./dashboard-plugin-redash/docker-compose.yml
    project_directory: ${FIELDSETS_PLUGIN_PATH:-./plugins/}dashboard-plugin-redash/
```


Add to `/plugins/docker-compose.networks.yml``
```
version: '3.7'

include:
  - path: ${FIELDSETS_PLUGIN_PATH:-./plugins/}cache-plugin-redis/config/docker/networks/docker-compose-${DOCKER_NETWORK_TYPE:-bridge}-network.yml
    project_directory: ${FIELDSETS_PLUGIN_PATH:-./plugins/}cache-plugin-redis/
  - path: ${FIELDSETS_PLUGIN_PATH:-./plugins/}dashboard-plugin-redash/config/docker/networks/docker-compose-${DOCKER_NETWORK_TYPE:-bridge}-network.yml
    project_directory: ${FIELDSETS_PLUGIN_PATH:-./plugins/}dashboard-plugin-redash/
```

Add to `/plugins/docker-compose.envvars.yml``
```
version: '3.7'

include:
  - path: ${FIELDSETS_PLUGIN_PATH:-./plugins/}dashboard-plugin-redash/config/docker/docker-compose.envvars.yml
    project_directory: ${FIELDSETS_PLUGIN_PATH:-./plugins/}dashboard-plugin-redash/
```