-module(filetree).
 
-include_lib("kernel/include/file.hrl").
-include("eronide.hrl").
   
-export([show/1, showdirs/1, showfiles/1, renamefiles/3]).
 
is_symlink(Path) ->
	case file:read_link_info(Path) of
		{ok, #file_info{type = symlink}} ->
			true;
		_ ->
			false
	end.
 
file_type(Path) ->
	
	IsRegular = filelib:is_dir(Path),
	case IsRegular of
		true ->
			directory;
		false ->
			case is_symlink(Path) of
				true ->
					symlink;
				false ->
					file
			end
	end.

show(Path) ->
	FileType = file_type(Path),
	case FileType of
		file ->
			#filetree{name=Path};
		symlink ->
			#filetree{name=Path};
		directory ->
			Childname=filename:join(Path , <<"*">>),		
			Children = filelib:wildcard(binary_to_list(Childname)),
			#filetree{name=Path, isdir=true, files=lists:map(fun(P) -> show(P) end, Children)}
	end
.

renamefile(Oldname, Holder, Newname) ->
	Bname=filename:basename(Oldname),
	Basename = if
		is_binary(Bname) ->
			binary:bin_to_list(Bname);
		true ->
			Bname
	end,
	Psub=string:substr(Basename, 1, length(Holder)),
	Eq=string:equal(Psub, Holder),
	if 
		Eq == true ->
			Newfile=filename:join(filename:dirname(Oldname), string:concat(binary:bin_to_list(Newname), string:substr(Basename, length(Holder)+1))),
			file:rename(Oldname, Newfile)
		;
		true ->
			Basename
	end
.

renamefiles(UPath, Holder, Newname) ->
	Path = if
		is_binary(UPath) ->
			UPath;
		true ->
			binary:list_to_bin(UPath)
	end,
	FileType = file_type(Path),
	case FileType of
		file ->
			renamefile(Path, Holder, Newname);
		symlink ->
			renamefile(Path, Holder, Newname);
		directory ->
			Childname=filename:join(Path , <<"*">>),		
			Children = filelib:wildcard(binary_to_list(Childname)),
			lists:map(fun(P) -> renamefiles(P, Holder, Newname) end, Children),
			renamefile(Path, Holder, Newname)
	end
.

showfiles(Path) ->
	Childname=filename:join(Path , <<"*">>),	
	lists:filter(fun(P) -> file_type(P) /=directory end, lists:map(fun(P) ->  binary:list_to_bin(filename:basename(P)) end, filelib:wildcard(binary_to_list(Childname))))
.

showdirs(Path) ->
	FileType = file_type(Path),
	case FileType of
		file ->
			false;
		symlink ->
			false;
		directory ->
			Childname=filename:join(Path , <<"*">>),		
			Children = filelib:wildcard(binary_to_list(Childname)),
			#filetree{name=Path, isdir=true, files=lists:filter(fun(P) -> P /= false end, lists:map(fun(P) -> showdirs(P) end, Children))}
	end
.
