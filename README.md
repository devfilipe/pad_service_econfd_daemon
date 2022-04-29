pad_service_econfd_daemon
=====

This module is a template to create a dummy econfd daemon.

The service must be launched by external caller (see `pad_service_econfd_mgr`).

To add a new CloudI service, see `cloudi_service_api:services_add/2`.

The callback `pad_service_econfd_daemon:cloudi_service_init/4` function receives `Args` (binary string) as defined by the JSON:


```json
{
  "subscriptions": [
    "get_state/get"
  ],
  "ip": "172.26.0.3",
  "port": 4565,
  "name": "econfd_daemon_default",
  "callpoint": "default_cp",
  "callback_module": "pad_service_econfd_daemon",
  "args": []
}
```
These are default values in case of `Args` be empty.

_subscriptions_: a list of paths

_ip_: ConfD ip address

_port_: ConfD port

_name_: econfd daemon name, it is also used to compose the service prefix

_callpoint_: callpoint name used in the yang model to invoke confd callbacks

_callback_module_: erlang module where confd callbacks are defined

_args_: optional arguments (i.e. set daemon for many callpoints and callbacks)

The `service prefix` composed by `pad_service_econfd_mgr` is given by

    "/econfd/daemons/<name>/"

Build
-----

    $ rebar3 compile
