%%%-------------------------------------------------------------------
%% @doc gateway public API
%% @end
%%%-------------------------------------------------------------------

-module(gateway_app).

-behaviour(application).

-include_lib("erlware_commons/include/log.hrl").

%%websocket port
-define(WEBPORT, 8080).
%% default websocket listen number
-define(WEB_LISTENNUM, 10).

%% Application callbacks
-export([start/2
  , stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
  ListenNum = application:get_env(gateway, listen, ?WEB_LISTENNUM),
  WebPort = application:get_env(gateway, webport, ?WEBPORT),
  ?TRACE("gateway start listen munber and port",[ListenNum,WebPort]),
  gateway_sup:start_link([WebPort, ListenNum]).

%%--------------------------------------------------------------------
stop(_State) ->
  ok.

%%====================================================================
%% Internal functions
%%====================================================================
