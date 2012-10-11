-module(cset_handler).

-behaviour(cowboy_http_handler).
-behaviour(cowboy_http_websocket_handler).

-export([init/3, handle/2, terminate/2]).
-export([websocket_init/3, websocket_handle/3,
	websocket_info/3, websocket_terminate/3]).

init({_Any, http}, Req, []) ->
	case cowboy_http_req:header('Upgrade', Req) of
		{undefined, Req2} -> {ok, Req2, undefined};
		{<<"websocket">>, _Req2} -> {upgrade, protocol, cowboy_http_websocket};
		{<<"WebSocket">>, _Req2} -> {upgrade, protocol, cowboy_http_websocket}
	end.

handle(Req, State) ->
	{ok, Req2} = cowboy_http_req:reply(200, [{'Content-Type', <<"text/html">>}],
<<"Hi!">>, Req),
	{ok, Req2, State}.

terminate(_Req, _State) ->
	ok.

websocket_init(_Any, Req, []) ->
	timer:send_interval(1000, "{}"),
	Req2 = cowboy_http_req:compact(Req),
	{ok, Req2, undefined, hibernate}.

websocket_handle({text, Msg}, Req, []) ->
	{ok, Json} = json:encode({{type, "color"}, {data, "red"}}),
	{reply, {text, << Json >>}, Req, [{color, "red"}, {name, Msg}], hibernate};
websocket_handle({text, Msg}, Req, [State]) ->
	{{color, Color}, {name, Username}} = State,

	ChatMessage = {{time, erlang:timestamp() * 1000}, {text, Msg}, {author, Username}, {color, Color}},
	{ok, Json} = json:encode(ChatMessage),

	{reply, {text, << Json >>}, Req, State, hibernate};
websocket_handle(_Any, Req, State) ->
	{ok, Req, State}.

websocket_info(tick, Req, State) ->
	{reply, {text, <<"Tick">>}, Req, State, hibernate};
websocket_info(_Info, Req, State) ->
	{ok, Req, State, hibernate}.

websocket_terminate(_Reason, _Req, _State) ->
	ok.