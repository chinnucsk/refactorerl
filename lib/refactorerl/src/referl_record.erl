%%% -*- coding: latin-1 -*-

%%% The contents of this file are subject to the Erlang Public License,
%%% Version 1.1, (the "License"); you may not use this file except in
%%% compliance with the License. You should have received a copy of the
%%% Erlang Public License along with this software. If not, it can be
%%% retrieved via the world wide web at http://plc.inf.elte.hu/erlang/
%%%
%%% Software distributed under the License is distributed on an "AS IS"
%%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%% License for the specific language governing rights and limitations under
%%% the License.
%%%
%%% The Original Code is RefactorErl.
%%%
%%% The Initial Developer of the Original Code is E�tv�s Lor�nd University.
%%% Portions created by E�tv�s Lor�nd University are Copyright 2008, E�tv�s
%%% Lor�nd University. All Rights Reserved.

%%% @doc Record properties and record based queries

-module(referl_record).
-vsn("$Rev: 2390 $").
-include("refactorerl.hrl").

%% =============================================================================
%% Exports

-export([name/1, file/0, form/0]).

%% =============================================================================

%% @spec name(node(#record{})) -> atom()
%% @doc The name of the record object
name(Record) ->
    (?Graph:data(Record))#record.name.

%% @spec file() -> query(#record{}, #file{})
%% @doc The result query returns the file that defines the record
file() ->
    [{record, back}].

%% @spec form() -> query(#record{}, #form{})
%% @doc The result query returns the form that defines the record
form() ->
    [{recdef, back}].
