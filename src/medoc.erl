-module(medoc).
-behaviour(provider).

-export([init/1, do/1, format_error/1]).
-define(PROVIDER, medoc).
-define(DEPS, [edoc]).

-define(DOC_DIR, "doc").
-define(TOC_TEMPLATE, "toc.html").
-define(MODULE_TEMPLATE, "module.html").
-define(TOC_PLACEHOLDER, "{toc}").
-define(MODULE_PLACEHOLDER, "{module}").
-define(TOC_FILE, "modules-frame.html").

%% ==================================================
%% PUBLIC API
%% ==================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
	Provider = providers:create([
			{name, ?PROVIDER},
			{module, ?MODULE},
			{bare, true},
			{deps, ?DEPS},
			{example, "rebar medoc"},
			{opts, []},
			{short_desc, "Generates edoc for all the apps"},
			{desc, "Runs edoc and then recreates the table of contents"
			 	" to include all the applications."}
		]),
	%% Put all the docs into single dir
	% {edoc_opts, [{dir, "doc"}]}.
	EDocOpts = rebar_state:get(State, edoc_opts),
	State2 = rebar_state:set(State, edoc_opts, [{dir, ?DOC_DIR} | proplists:delete(dir, EDocOpts)]),
	{ok, rebar_state:add_provider(State2, Provider)}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
	%% Explor the doc dir
	Modules = get_modules(?DOC_DIR),
	Html = build_toc(Modules),
	ok = write_toc(Html),
	{ok, State}.

get_modules(Path) ->
	{ok, Files} = file:list_dir(Path),
	Htmls = [F || F <- Files, 
		filename:extension(F) == ".html",
		string:str(F, "index") == 0,
		string:str(F, "overview") == 0,
		string:str(F, "modules") == 0],

	%% Chop off .html
	Modules = [filename:basename(H, ".html") || H <- Htmls],
	lists:sort(Modules).

-spec format_error(any()) -> iolist().
format_error(Reason) ->
	io_lib:format("~p", [Reason]).

build_toc(Modules) ->
	ModuleTemplate = module_template(),
	ModuleHtml = build_module_html(ModuleTemplate, Modules),

	TocTemplate = toc_template(),
	build_template_html(ModuleHtml, TocTemplate).


write_toc(TocHtml) ->
	file:write_file(filename:join(?DOC_DIR, ?TOC_FILE), TocHtml).


build_template_html(ModuleHtml, TocTemplate) ->
	re:replace(TocTemplate, ?TOC_PLACEHOLDER, ModuleHtml, [global, {return, list}]).

build_module_html(Template, Modules) ->
	ModuleHtmls = lists:reverse(build_module_htmls(Template, Modules, [])),
	string_join("\r\n", ModuleHtmls).

build_module_htmls(_, [], Acc) -> Acc;
build_module_htmls(Template, [M|Rest], Acc) ->
	M2 = re:replace(Template, ?MODULE_PLACEHOLDER, M, [global, {return,list}]),
	build_module_htmls(Template, Rest, [M2 | Acc]).

module_template() ->
	Dir = code:priv_dir(?MODULE),
	{ok, File} = file:read_file(filename:join(Dir, ?MODULE_TEMPLATE)),
	unicode:characters_to_list(File).

toc_template() ->
	Dir = code:priv_dir(?MODULE),
	{ok, File} = file:read_file(filename:join(Dir, ?TOC_TEMPLATE)),
	unicode:characters_to_list(File).


%% Helper function:
%% https://erlangcentral.org/wiki/index.php?title=String_join_with
string_join(Join, L) ->
    string_join(Join, L, fun(E) -> E end).
 
string_join(_Join, L=[], _Conv) ->
    L;
string_join(Join, [H|Q], Conv) ->
    lists:flatten(lists:concat(
        [Conv(H)|lists:map(fun(E) -> [Join, Conv(E)] end, Q)]
    )).