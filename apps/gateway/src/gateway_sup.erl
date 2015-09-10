-module(gateway_sup).

-behaviour(supervisor).

%% API
-export([start_link/1]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 2000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link([WebPort, WebListenNum]) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, [WebPort, WebListenNum]).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([WebPort, WebListenNum]) ->
  Dispatch = cowboy_router:compile([
    {'_', [
      {"/",gateway_hander, []},
      {"/index", cowboy_static, {priv_file, gateway, "index.html"}},
      {"/static/[...]", cowboy_static, {priv_dir, gateway, "static"}}
    ]}
  ]),
  {ok, _} = cowboy:start_http(http, WebListenNum, [{port, WebPort}], [{env, [{dispatch, Dispatch}]}]),
  Children = [],
  {ok, {{one_for_one, 5, 10}, Children}}.
