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

%%% @doc Expand implicit fun expression
%%%
%%% @author Daniel Horpacsi <daniel_h@inf.elte.hu>

-module(referl_tr_expand_funexpr).
-vsn("$Rev: 2599 $").
-include("refactorerl.hrl").

%% Callbacks
-export([prepare/1, error_text/2]).

%%% ============================================================================
%%% Errors

%% @private
error_text(implicit_not_found, []) ->
    "Implicit fun expression has to be given".

%%% ============================================================================
%%% Callbacks

%% @private
prepare(Args) ->
    ArgExpr = ?Args:expression(Args),
    [Expr] = ?Query:exec(ArgExpr, ?Expr:sup()),
    case is_implicit_fun_expr(Expr) of
        false -> throw(?LocalErr0r(implicit_not_found));
        true ->
            fun() ->
                    File = ?Syn:get_file(Expr),
                    ?Expr:expand_funexpr(Expr),
                    ?Transform:touch(File)
            end
    end.

is_implicit_fun_expr(Expr) ->
    ExprKindOk = ?Expr:kind(Expr) == implicit_fun,
    SubExprKindOk =
        case ?Query:exec(Expr, ?Expr:children()) of
            [] -> false;
            [FunRef|_Arity] ->
                case ?ESG:data(FunRef) of
                    #expr{kind=infix_expr, value=':'} -> true;
                    #expr{kind=atom}                  -> true;
                    _                                 -> false
                end
        end,
    ExprKindOk andalso SubExprKindOk.
