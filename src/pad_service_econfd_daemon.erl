-module(pad_service_econfd_daemon).
-behaviour(cloudi_service).

%% cloudi_service callbacks
-export([cloudi_service_init/4,
         cloudi_service_handle_request/11,
         cloudi_service_handle_info/3,
         cloudi_service_terminate/3]).

-export([init_daemon/1]).

% default (dummy) callbacks - don't return data
-export([s_init/1, s_finish/1, get_elem/2, get_next/3]).

-include_lib("cloudi_core/include/cloudi_logger.hrl").
-include_lib("econfd/include/econfd.hrl").

-record(state,
  {
  }).

cloudi_service_init(Args, _Prefix, _Timeout, Dispatcher) ->
  Defaults = [% cloudi
              {<<"subscriptions">>,           [<<"get_state/get">>]},
              % econfd
              {<<"ip">>,                      <<"172.26.0.3">>},
              {<<"port">>,                    4565},
              {<<"name">>,                    <<"econfd_daemon_default">>},
              {<<"callpoint">>,               <<"default_cp">>},
              {<<"callback_module">>,         <<"pad_service_econfd_daemon">>},
              {<<"args">>,                    []}],

  [Subs,
   IpStr,
   Port,
   NameStr,
   CallpointStr,
   CallbackModuleStr,
   ExtraArgs
  ] = econfd_mgr_utils:take_values(Defaults, Args),

  cloudi_service:subscribe(Dispatcher, "status/get"),
  [cloudi_service:subscribe(Dispatcher, binary_to_list(S)) || S <- Subs],

  Ip = cloudi_ip_address:from_binary(IpStr),
  Name = binary_to_atom(NameStr),
  Callpoint = binary_to_atom(CallpointStr),
  CallbackModule = binary_to_atom(CallbackModuleStr),
  CallbackModule:init_daemon({default, {Ip, Port, Name, Callpoint, CallbackModule, ExtraArgs}}),

  {ok, #state{}}.

cloudi_service_handle_request(_RequestType, _Name, _Pattern,
                              _RequestInfo, _Request,
                              _Timeout, _Priority,
                              _TransId, _Pid,
                              #state{} = State, _Dispatcher) ->
    Response = cloudi_x_jsx:encode([{<<"status">>, <<"ok">>}]),
    {reply, Response, State}.

cloudi_service_handle_info(Request, State, _Dispatcher) ->
    ?LOG_WARN("Unknown info \"~p\"", [Request]),
    {noreply, State}.

cloudi_service_terminate(_Reason, _Timeout, #state{}) ->
    ok.

%%==============================================================================
%% Defaults
%%==============================================================================

init_daemon({default, {Ip, Port, Name, Callpoint, CallbackModule, _Args}}) ->

  {ok, Daemon} = econfd:init_daemon(Name, ?CONFD_TRACE, user, none, Ip, Port),
  register(Name, Daemon),

  ?LOG_INFO(" ~p:~p:~p Data provider ~p initialized (pull mode).\n" ++
            " Connected to ConfD at ~p:~p.\n",
            [?MODULE, ?FUNCTION_NAME, ?LINE, Name, Ip, Port]),

  Trans = #confd_trans_cbs{init = fun CallbackModule:s_init/1,
                           finish = fun CallbackModule:s_finish/1},

  Cbs = #confd_data_cbs{get_elem = fun CallbackModule:get_elem/2,
                        get_next = fun CallbackModule:get_next/3,
                        callpoint = Callpoint},

  ok = econfd:register_trans_cb(Daemon, Trans),
  ok = econfd:register_data_cb(Daemon, Cbs),
  ok = econfd:register_done(Daemon),
  Daemon.

s_init(Tctx) ->
  ?LOG_DEBUG("Tctx = ~p\n", [Tctx]),
  {ok, Tctx}.

s_finish(Tctx) ->
  ?LOG_DEBUG("Tctx = ~p\n", [Tctx]),
  ok.

get_next(Tctx, KeyPath, Prev) ->
  ?LOG_DEBUG("Tctx = ~p\nKeyPath = ~p\nPrev = ~p\n", [Tctx, KeyPath, Prev]),
  {ok, {false, undefined}}.

get_elem(Tctx, KeyPath) ->
  ?LOG_DEBUG("Tctx = ~p\nKeyPath = ~p\n", [Tctx, KeyPath]),
  {ok, not_found}.
