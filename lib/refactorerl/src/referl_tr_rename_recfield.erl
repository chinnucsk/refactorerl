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

%%% ============================================================================
%%% Module information

%%% @doc Rename record field
%%% @todo Full documentation
%%%
%%% @author Daniel Horpacsi <daniel_h@inf.elte.hu>

-module(referl_tr_rename_recfield).
-vsn("$Rev: 2599 $").
-include("refactorerl.hrl").

%% Callbacks
-export([prepare/1, error_text/2]).


%%% ============================================================================
%%% Errors

%% @private
error_text(name_collision, []) ->
    "Name collision with an existing field name".


%%% ============================================================================
%%% Callbacks

%% @private
prepare(Args) ->

    NewName = ?Args:name(Args),
    Field   = ?Args:record_field(Args),
    Record  = ?Query:exec(Field, [{field, back}]),

    %% Checking name collisions

    Names = [Name || F <- ?Query:exec(Record, [field]) -- [Field],
                     #field{name=Name} <- [?ESG:data(F)]],
    ?Check(not lists:member(NewName, Names), ?LocalErr0r(name_collision)),

    %% Collecting references

    Refs    =
        ?Query:exec(Field, [{fieldref, back}]) ++
        ?Query:exec(Field, [{fielddef, back}]),

    fun() ->
        [?Syn:replace(Expr, {elex,1}, [io_lib:write_atom(NewName)]) ||
                Expr <- Refs],
        [?Transform:touch(Node) || Node <- Refs]
    end.