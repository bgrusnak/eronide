-module(jstree).
 
-include("eronide.hrl").
   
-export([parsefiles/2]).
 
relname(Filename, Reldir) ->
	 Answer=filename:join(lists:nthtail(length(filename:split(Reldir)), filename:split(Filename))),
	 if 
		is_binary(Answer) ->
			Answer;
		true ->
			binary:list_to_bin(Answer)
	end
. 
%
%parsefiles(Filetree, Reldir) ->
%	Name=relname(Filetree#filetree.name, Reldir),
%	Fext=filename:extension(binary:bin_to_list(Name)),
%	Filetype= if 
%		length(Filetree#filetree.files) > 0 ->
%			<<"folder">>;
%		length(Fext) > 0 ->
%			binary:list_to_bin(Fext);
%		true ->
%			<<"default">>
%	end,
%	if
%		length(Filetree#filetree.files)>0 ->
%			[ { <<"data">> , binary:list_to_bin(filename:basename(binary:bin_to_list(Name))) }, { <<"type">>, Filetype}, { <<"metadata">>, Name }, { <<"children">>, lists:map(fun(P) -> parsefiles(P, Reldir) end, Filetree#filetree.files)}];
%		true ->
%			[ { <<"data">> , binary:list_to_bin(filename:basename(binary:bin_to_list(Name))) }, { <<"type">>, Filetype}, { <<"metadata">>, Name }]
%	end
%.
%}
parsefiles(Filetree, Reldir) ->
	Name=relname(Filetree#filetree.name, Reldir),
	Fext=filename:extension(binary:bin_to_list(Name)),
	Iconlist=process_conf:lookup(icons),
%	Filetype= if 
%		length(Filetree#filetree.files) > 0 ->
%			<<"folder">>;
%		length(Fext) > 0 ->
%			binary:list_to_bin(Fext);
%		true ->
%			<<"default">>
%	end,
	Iconfound=lists:keyfind(binary:list_to_bin(Fext), 1, Iconlist),
	if
		length(Filetree#filetree.files)>0 ->
			if 
				Iconfound==false ->
					[ { <<"title">> , binary:list_to_bin(filename:basename(binary:bin_to_list(Name))) }, { <<"key">>, Name },  { <<"isFolder">>, true }, { <<"children">>, lists:map(fun(P) -> parsefiles(P, Reldir) end, Filetree#filetree.files)}];
				true ->
					{_, Icon} = Iconfound,
					[ { <<"title">> , binary:list_to_bin(filename:basename(binary:bin_to_list(Name))) }, { <<"key">>, Name }, { <<"icon">>, Icon},  { <<"isFolder">>, true }, { <<"children">>, lists:map(fun(P) -> parsefiles(P, Reldir) end, Filetree#filetree.files)}]
			end;
		true ->
			if 
				Iconfound==false ->
					[ { <<"title">> , binary:list_to_bin(filename:basename(binary:bin_to_list(Name))) }, { <<"key">>, Name },  { <<"isFolder">>, Filetree#filetree.isdir }];
				true ->
					{_, Icon} = Iconfound,
					[ { <<"title">> , binary:list_to_bin(filename:basename(binary:bin_to_list(Name))) }, { <<"key">>, Name }, { <<"icon">>, Icon},  { <<"isFolder">>, Filetree#filetree.isdir }]
			end
	end
.
