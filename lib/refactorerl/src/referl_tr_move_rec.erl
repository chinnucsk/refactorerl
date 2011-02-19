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

%%% @doc This module implements the `Move records between files'
%%% transformation
%%%
%%% Side conditions
%%%
%%% <ul>
%%%   <li>The names of the records to be moved do not clash with
%%%   existing record names
%%%     <ul>
%%%       <li>in the target file</li>
%%%       <li>in files that are included in target</li>
%%%       <li>and in files where the target file is included</li>
%%%     </ul>
%%%   </li>
%%%   <li>Moving records from a header file to a module file is only
%%%   permitted if no other modules include the header file and use
%%%   some of the records to be moved</li>
%%%   <li>If a file inclusion has to be introduced during the
%%%   transformation, this inclusion must not cause inconsistency at
%%%   the place of the inclusion.</li>
%%% </ul>
%%%
%%% Transformation steps and compensations
%%%
%%% <ol>
%%%   <li>The record definitions are removed from the source file</li>
%%%   <li>If the target is a header file that does not exist, the file
%%%   is created</li>
%%%   <li>The record definitions are placed at the end of the target
%%%   header file, or before the first function of the target module
%%%   file</li>
%%%   <li>If a record is moved into a header file, then every module
%%%   that uses the record is changed to include the target header
%%%   file. This is not an issue when the target is a module
%%%   file.</li>
%%% </ol>
%%%
%%% @author Daniel Horpacsi <daniel_h@inf.elte.hu>

-module(referl_tr_move_rec).
-vsn("$Rev: 2662 $").
-include("refactorerl.hrl").


%%% ============================================================================
%%% Exports

%% Callbacks
-export([prepare/1]).
-export([error_text/2]).


%%% ============================================================================
%%% Main types

-record(recinfo, {name, form, files}).
-record(info, {fromfile, tofile, fromheader, toheader,
               names, nodes, forms, files}).


%%% ============================================================================
%%% Errors

%% @private
error_text(name_collision, [Clash]) ->
    ["Record with given name already exists in target ",
     ?MISC:format("~p", [Clash])];

error_text(not_only_in_target, [OtherUseNames]) ->
    ["Cannot remove record from header, included in other files: ",
     ?MISC:join(OtherUseNames)];

error_text(unincludable, [FileName, ToFileName]) ->
    ["Cannot include ", FileName, " in ", ToFileName];
%    "Cannot include the target header in some files, " ++
%        "where the from-file header is included";

error_text(not_movable, [FileName, Name]) ->
    ["File ", FileName, " also includes the target file ",
     "and causes name collision with record ", atom_to_list(Name)];
%    "Cannot move to header, because there's name " ++
%        "collision (mediately) with a record in a file, " ++
%        "which includes the target header";

error_text(delete, []) ->
    "Cannot delete record from the source file as it is being used".


%%% ============================================================================
%%% Callbacks

%% @private
prepare(Args) ->
    FromFile = ?Args:file(Args),
    FromPath = ?File:path(FromFile),
    ToName   = ?Args:filename(Args),
    ToPath   = target_path(ToName, FromPath),
    ToFile   = ?Query:exec1(?File:find(ToPath), ?RefErr0r(target_not_found)),
    Records  = ?Args:records(Args),

    {Names, Forms, Files} =
        lists:foldl(
          fun(#recinfo{name=Name, form=Form, files=Files},
              {Na, Fo, Fi}) ->
                  {[Name|Na], [Form|Fo], lists:usort(lists:flatten([Files|Fi]))}
          end,
          {[], [], []},
          [info(Node) || Node <- Records]),

    check_name_conflicts(FromFile, ToFile, Names),

    Info = #info{fromfile = FromFile, tofile = ToFile,
                 fromheader = ?File:type(FromFile) == header,
                 toheader   = ?File:type(ToFile)   == header,
                 names = Names, forms = Forms, files = Files},

    check_unincludable(Info),
    check_movable_to_header(Info),
    check_used_only_in_target(Info),
    check_no_using(Info),

    fun() -> transform(Info) end.


%%% ============================================================================
%%% Implementation

info(Node) ->
    Form = ?Query:exec1(Node, ?Rec:form(), recform_not_found),
    Refs = ?Query:exec(Node,
                       ?Query:seq([[{recref, back}], ?Expr:clause(),
                                   ?Clause:form(), ?Form:file()])),
    #recinfo{name=?Rec:name(Node), form=Form, files=lists:usort(Refs)}.

transform(#info{fromfile=FFile, tofile=TFile, forms=Forms,
                toheader=ToHeader, files=Files}) ->
    %% Must be before the form movings! ?? Analysers??!!
    %[?Graph:rmlink(FFile, record, Node) || Node <- Nodes],
    %[?Graph:mklink(TFile, record, Node) || Node <- Nodes],
    [?Transform:touch(File) || File <- lists:usort([FFile, TFile] ++ Files)],
    [fun() -> init end]
        ++
        [fun(_) ->
                 ?File:add_include(File, TFile)
         end
         || File <- Files, ToHeader]
        ++
        [fun(_) ->
                 ?File:del_form(Form),
                 ?File:add_form(TFile, Form)
         end
         || Form <- Forms].



%%% ----------------------------------------------------------------------------
%%% Checks

check_name_conflicts(FromFile, ToFile, Names) ->
    Includes =
        fun(File) ->
                lists:usort(?Query:exec(File, ?File:includes())) -- [FromFile]
        end,
    Exists =
        fun(File, Name) ->
                ?Query:exec(File,
                            ?Query:seq([Includes, ?File:record(Name)])) =/= []
        end,
    io:format("..... includes ~p~n", [Includes(ToFile)]),
%    [begin
%         io:format(".... ~p~n", [])
%     end || Name <- Names],
    Clash = [Name || Name <- Names, Exists(ToFile, Name)],
    ?Check(Clash == [], ?LocalError(name_collision, [Clash])).

%% header -> module
%% (Are the records used only in target module?)
check_used_only_in_target(#info{fromheader=true, toheader=false,
                                files=Files, tofile=TFile}) ->
    OtherUses = Files -- [TFile],
    OtherUseNames = lists:map(fun ?File:path/1, OtherUses),
    ?Check(OtherUses == [], ?LocalError(not_only_in_target, [OtherUseNames]));
check_used_only_in_target(_) -> ok.

%% module -> module
%% (Are the records used?)
check_no_using(#info{fromheader=false, toheader=false, files=Files}) ->
    ?Check(Files == [], ?LocalErr0r(delete)); %% todo: correct?
check_no_using(_) -> ok.

%% header -> header
%% (Error, when we cannot include the target header somewhere.)
check_unincludable(#info{fromheader=true, toheader=true,
                         tofile=ToFile, files=Files}) ->
    ToFileName = ?File:path(ToFile),
    [?Check(?File:includable(File, ToFile),
            ?LocalError(unincludable, [FileName, ToFileName]))
     || File <- Files,
        FileName <- [?File:path(File)]];
check_unincludable(_) -> ok.


%% _ -> header
%% (Moving should not make name conflicts.)
check_movable_to_header(#info{toheader=true, names=Names,
                              fromfile=FFile, tofile=TFile}) ->
    TargetIncluders = ?Query:exec(TFile, ?File:included()) -- [FFile, TFile],
    [?Check(?Query:exec(File, ?File:record(Name)) == [],
            ?LocalError(not_movable, [FileName, Name]))
     || Name <- Names,
        File <- TargetIncluders,
        FileName <- [?File:path(File)]];
check_movable_to_header(_) -> ok.


%%% ----------------------------------------------------------------------------

target_path(ToName, FromPath) ->
    case filename:pathtype(ToName) of
        absolute ->
            ToName;
        relative ->
%%            SourceDir = filename:dirname(filename:absname(FromPath)),
            SourceDir = filename:dirname(FromPath),
            filename:absname(ToName, SourceDir);
        volumerelative ->
            todo
    end.