function svngit_ver_char = CPversionnumber(CP_root_dir)
%% Find the current svn version number
%% First, try using the 'svn info' command, but if svn is not
%% installed, or if deployed, loop all functions and parse out


current_dir = pwd;
if nargin > 0
    cd(CP_root_dir);
end

svngit_ver_char = '';

try
    if ~isdeployed
        [status,info] = system('svn info');
        if (status == 0)
            %% if successful, parse out svn Revision Number
            str_to_find = 'Revision: ';
            pos = findstr(info,str_to_find);
            if length(pos) == 1
                first = pos+length(str_to_find);
                svngit_ver_char = strtok(info(first:end));
            end
        else
            [status,info] = system('git rev-parse --short HEAD');
            if (status == 0)
                svngit_ver_char = strtrim(info);
            end
        end
    end
end

%% If you've gotten here without returning (e.g.  if not deployed)
%% then just do the loop
if isempty(svngit_ver_char)
    svngit_ver_char = CPsvnloopfunctions();
end
cd(current_dir);
