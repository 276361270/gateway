-module(gateway_hander).
-behaviour(cowboy_websocket).
-include_lib("erlware_commons/include/log.hrl").
%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------
-export([init/2]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([terminate/3]).

-record(state, {otp, ip, port, timeref, roompid, ping = 0, islogin = false, isfirst = true}).
%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------


%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------
%% -> {ok | module(), Req, any()}
%% | {module(), Req, any(), hibernate}
%% | {module(), Req, any(), timeout()}
%% | {module(), Req, any(), timeout(), hibernate}
init(Req, Opts) ->
  {ok, TimeRef} = timer:send_after(3000, disconnect),
  {Address, Port} = erlang:element(8, Req),
  ?TRACE(Opts),
  {cowboy_websocket, Req, #state{otp = Opts, ip = Address, port = Port, timeref = TimeRef}, hibernate}.

%% handle client send msg
%%  {ok, Req, State}
%% | {ok, Req, State, hibernate}
%% | {reply, cow_ws:frame() | [cow_ws:frame()], Req, State}
%% | {reply, cow_ws:frame() | [cow_ws:frame()], Req, State, hibernate}
%% | {stop, Req, State}
%%第一个数据包必须是房间名称 如果房间 名称存在 返回房间数据
websocket_handle({binary, Data}, Req, State = #state{isfirst = true,ping = Ping}) ->
  case get_room_pid(Data) of
    {ok, RoomPid} ->
      ok = gen_server:call(RoomPid,{enterroom,self()}),
      {reply, {binary, Data}, Req, State#state{isfirst = false, roompid = RoomPid,ping=Ping+1}, hibernate};
    {error, Reson} ->
      ?TRACE("first data message must be room name",Reson),
      {stop, Req, State}
  end;

websocket_handle({binary, Data}, Req, State = #state{isfirst = false, roompid = RoomPid}) ->
  gen_server:cast(RoomPid, Data),
  {ok, Req, State, hibernate};

websocket_handle(_Data, Req, State) ->
  ?TRACE("UnDeal Data",_Data),
  {ok, Req, State, hibernate}.

%% 超时发送数据
%%{ok, Req, State}
%%| {ok, Req, State, hibernate}
%%| {reply, cow_ws:frame() | [cow_ws:frame()], Req, State}
%%|{reply, cow_ws:frame() | [cow_ws:frame()], Req, State, hibernate}
%%| {stop, Req, State}

websocket_info(disconnect, Req, State = #state{ping = Ping, timeref = TimeRef}) ->
  timer:cancel(TimeRef),
  case Ping > 0 of
    true -> {ok, Req, State, hibernate};
    false -> {stop, Req, State}
  end;
%%gen_cast处理
websocket_info({'$gen_cast', {mess_to_client, DataObj}}, Req, State) ->
  {reply, {binary, DataObj}, Req, State, hibernate};

websocket_info({'$gen_cast', {disconnect, Info}}, Req, State = #state{timeref = Timeref}) ->
  timer:cancel(Timeref),
  send(Info),
  {stop, Req, State};
%%给自己发送消息
websocket_info({binary, {send_to_self, Binary}}, Req, State) ->
  {reply, {binary, Binary}, Req, State, hibernate};

websocket_info(_Info, Req, State) ->
  io:format("websocket_info~p~n", [_Info]),
  {ok, Req, State, hibernate}.

%%没有登录就不存在登录的用户
terminate(_Reason, _Req, _State) ->
  ok.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

send(Binary) ->
  self() ! {binary, {send_to_self, Binary}}.

get_room_pid(<<"">>)->
  {error,"the room is empty"};

get_room_pid(RoomName) when is_binary(RoomName)->
  {ok,self()};

get_room_pid(RoomName)->
  get_room_pid(ec_cnv:to_binary(RoomName)).