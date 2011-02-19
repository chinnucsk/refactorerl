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
%%% Header information

%%% @ doc Types of Pretty Printer (PP).
%%%
%%% @ author Kornel Horvath <kornel@inf.elte.hu>

-vsn("$Rev: $").



%%% ============================================================================
%%% Types

%% @type tokenRule().
%% Special settings of EPP.
-record(tokenRule, {
    allowMore = true,           % bool()
    allowLess = false,          % bool()
    parents = [],               % parents
    default = [],               % default value
    rules = []                  % own value for specified items
    }).

%% @type indentRule().
%% Indentation rule.
-record(indentRule, {
    parent,                     % parents
    indent                      % childs descriptions
    }).


%% @type ppConfig_general().
%% General configurations of the Pretty Printer.
-record(ppConfig_general, {
    useTab  = false,            % bool(): use tabulator in indentation or don't
    tabSize = 4,                % natural(): tabulator size
    optLineLength = 80,         % natural(): optimal line length
    minTextChars  = 30,         % natural(): if a line has less character
                                %   the line won't be broken
    maxTextChars  = 65,         % natural(): if a line has more character
                                %   the line will be broken
    nlStr = "\n",               % string(): default "End of Line" sequence
    commentLines                % [string()]: Comment lines
    }).

%% @type ppConfig().
%% Configuration of Pretty Printer.
-record(ppConfig, {
    % General
    general = #ppConfig_general{},
    % Language specific options
    resWords,                   % [string()]: Reserved words
    % White space, line break, indentation rules
    indent,                     % [indentRule()]: Indentaions
    ws_nl,                      % [tokenRule()]: Required white spaces and
                                %   recommended line breaks
    longNl,                     % [tokenRule()]: Possible line breakers in
                                %   long line case
    multiNl                     % [tokenRule()]: Extra line breakers for
                                %   long terms
    }).



