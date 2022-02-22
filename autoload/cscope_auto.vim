" vim: set foldmethod=marker:
"
" Copyright (c) 2014, Eric Garver
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1. Redistributions of source code must retain the above copyright notice, this
"    list of conditions and the following disclaimer.
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
" ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
" WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
" DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
" ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
" (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
" LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
" ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
" (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
" SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


" Vim Plugin to automatically update cscope when a buffer has been written.

" if exists("g:cscope_auto_loaded")
"     finish
" endif
" let g:cscope_auto_loaded = 1

if ! exists("s:_init_value")
    let s:_init_value = {}
    let s:_init_value._log_address      = $HOME . '/.vim.log'
    let s:_init_value._fixed_tips_width = 27
    let s:_init_value._log_verbose      = 0
    let s:_init_value._is_windows       = 0
    let s:_init_value._script_develop   = 0
    let s:_init_value._log_one_line     = 1
endif

if ! exists("g:_cscope_auto_develop")
    let s:_cscope_auto_develop = 0
    let g:_cscope_auto_develop = 0
else
    let s:_cscope_auto_develop = g:_cscope_auto_develop
endif

if 1 == s:_cscope_auto_develop
    com! -nargs=* -complete=command FrameworkLocal <args>
    function! cscope_auto#return_local(_value)
        execute 'return s:' . a:_value
    endfunction
endif

if ! exists("s:environment")
    let s:environment = {}
endif

if ! exists("s:_environment")
    let s:_environment = boot#environment(s:environment, 'cscope_auto.vim', s:_cscope_auto_develop, s:_init_value)
    " let s:_environment = boot#environment(s:environment, boot#chomped_system('basename ' . resolve(expand('#'. bufnr(). ':p'))),
    "     \ s:_cscope_auto_develop, s:_init_value)
endif

if ! exists("g:_environment")
    let g:_environment  = deepcopy(s:_environment, 1)
endif

if has("cscope")

if ! exists("s:_csprg")
    let s:_csprg = boot#chomped_system("which cscope")
endif

    " Section: Default variables and Tunables {{{1
if ! exists("s:no_file_exists")
    let s:no_file_exists = 'no_file_exists'
endif
if ! exists("s:out_of_date")
    let s:out_of_date    = 'out_of_date'
endif
if ! exists("s:updated")
    let s:updated        = 'updated'
endif
    " let s:linked         = 'linked'
if ! exists("s:status_of_file")
    " let status_of_file = {'link_reseted' : 0, s:out_of_date : 1, s:updated : 2}
    let s:status_of_file = {
        \ s:no_file_exists : 1,
        \ s:out_of_date    : 0,
        \ s:updated        : 0,
        \ }
        " \ s:linked         : 0
endif

    function! s:status_of_file_new(_status_dict)
        return deepcopy(a:_status_dict, 1)
    endfunction

    function! s:exclusive(_func_name, _db_target, _file_type, _key = "", _environment = g:_environment)
        let result = s:no_file_exists
        let l:dict = eval('a:_db_target._status._file_' . a:_file_type)
        let l:file_name = eval('a:_db_target._file_' . a:_file_type)
        if "" != a:_key
            if has_key(l:dict, a:_key)
                for k in keys(l:dict)
                    let l:dict[k] = 0
                endfor
                let l:dict[a:_key] = 1
                let result = a:_key
            else
                call boot#log_silent(a:_func_name . "::try to index an invalid key of " . a:_key, l:dict)
            endif
        else

            if filereadable(l:file_name)
                let l:dict[s:no_file_exists] = 0
                let l:dict[s:out_of_date] = 0
                let l:dict[s:updated] = 1
                let all = range(0, bufnr('$'))
                for b in all
                    let l:buf_name = bufname(b)
                    if buflisted(b) && boot#project(l:buf_name, a:_environment) == a:_db_target._status._dir_project
                        let l:file_name = fnamemodify(resolve(expand("#". b . ":p")), ':p')
                        let a:_db_target._status._file_opened[l:file_name] =
                            \ boot#chomped_system('basename ' . a:_db_target._status._dir_project)
                        if getbufvar(b, "&mod")
                            let l:dict[s:out_of_date] = 1
                            " let db_result = s:read_link_status(a:_db_target, a:_file_type, a:_environment)
                            " if "" != db_result
                            "     let l:dict[s:linked] = 1
                            " endif
                        endif
                    endif
                endfor
                if l:dict[s:out_of_date] == 1
                    let l:dict[s:updated] = 0
                endif
            else
                let l:dict[s:no_file_exists] = 1
                let l:dict[s:out_of_date] = 0
                let l:dict[s:updated] = 0
                " let l:dict[s:linked] = 0
            endif

            for [key, b:value] in items(l:dict)
                if b:value != 0
                    let result = key
                    break
                endif
            endfor
        endif
        return result
    endfunction
if ! exists("s:status")
    let s:status = {}
endif
    function! s:status.new(
        \ _init_succeeded           = 0
        \, _file_complete_force     = 0
        \, _file_complete_link_time = 0
        \, _ready_to_switch         = 0
        \, _dir_project             = boot#project(fnamemodify(resolve(expand("#". bufnr(). ":p:h")), ':p:h'), s:_environment)
        \, _file_opened             = {}
        \, _file_partial            = {}
        \, _file_complete           = {}
        \, _file_dict_partial       = {}
        \ )
        " \, _linked_partial          = 0
        " \, _linked_complete         = 0
        let object = deepcopy(self, 1)
        let object._init_succeeded          = a:_init_succeeded
        let object._file_complete_force     = a:_file_complete_force
        let object._file_complete_link_time = a:_file_complete_link_time
        let object._ready_to_switch         = a:_ready_to_switch
        let object._dir_project             = a:_dir_project
        let object._file_opened             = a:_file_opened
        let object._file_partial            = s:status_of_file_new(s:status_of_file)
        let object._file_complete           = s:status_of_file_new(s:status_of_file)
        let object._file_dict_partial       = deepcopy(a:_file_dict_partial, 1)
        " let object._linked_partial          = a:_linked_partial
        " let object._linked_complete         = a:_linked_complete
        return object
    endfunction

    " let s:update_description = {}
    " let s:update_description[0] = "Database reseted"
    " let s:update_description[1] = "List file updated"
    " let s:update_description[2] = "Database should be updated"
if ! exists("s:file_system_db_status")
    " File system status
    let s:file_system_db_status = {}
    let s:file_system_db_status[0] = "Error: Database file does not exist"
    let s:file_system_db_status[1] = "Database file created"
endif
if ! exists("s:vim_db_init_status")
    " Link status
    let s:vim_db_init_status = {}
    let s:vim_db_init_status[0] = "Error: Vim database has not been linked"
    let s:vim_db_init_status[1] = "Vim database has been linked"
endif
if ! exists("s:vim_cscope_init_status")
    " Initialize status
    let s:vim_cscope_init_status = {}
    let s:vim_cscope_init_status[0] = "Error: Vim database should not have been inited"
    let s:vim_cscope_init_status[1] = "Vim database should have been inited"
endif
    function! s:status.show(_func_name, _enter_state, _environment) dict
        let l:chaged_value = {}
        let l:removed_item = {}
        let l:appened_item = {}
        " Based on changes
        for [key, b:value] in items(self)
            if key != 'new' && key != 'show' && b:value != a:_enter_state[key]
                " if type(b:value) == v:t_dict && key != '_file_dict_partial'
                if type(b:value) == v:t_dict
                    for [K, V] in items(a:_enter_state[key])
                        if ! exists("b:value[K]")
                            let l:removed_item[K] = V
                        else
                            if V != b:value[K]
                                let l:chaged_value[K] = V
                            endif
                        endif
                    endfor
                    for [K, V] in items(b:value)
                        if ! exists("a:enter_state[key][K]")
                            let l:appened_item[K] = V
                        else
                            if V != a:_enter_state[key][K]
                                let l:chaged_value[K] = V
                            endif
                        endif
                    endfor
                else
                    let l:chaged_value[key] = b:value
                endif
            endif
        endfor
        " let l:_db_target = s:_db_target_list[self._dir_project]

        call boot#log_silent(a:_func_name . '::s:_db_.._list[' . boot#chomped_system('basename ' . self._dir_project) . ']._status::l:removed_item', l:removed_item, a:_environment)
        call boot#log_silent(a:_func_name . '::s:_db_.._list[' . boot#chomped_system('basename ' . self._dir_project) . ']._status::l:chaged_value', l:chaged_value, a:_environment)
        call boot#log_silent(a:_func_name . '::s:_db_.._list[' . boot#chomped_system('basename ' . self._dir_project) . ']._status::l:appened_item', l:appened_item, a:_environment)
    endfunction

    " let s:_status = s:status.new()

if ! exists("s:db_target")
    let s:db_target = {}
endif
    function! s:target_settings(_object, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))

        let target = deepcopy(a:_object, 1)

        let l:_session_info = session_auto#read(resolve(expand("#". bufnr(). ":p:h")), a:_environment)

        if filereadable(l:_session_info['session_dir']) != 2
            execute '!mkdir -p ' . l:_session_info['session_dir']
        endif

        let target._status = s:status.new()
        let target._status._dir_project = l:_session_info['project_dir']

        call assert_true(target._status._dir_project != "", "target._status._dir_project should not be \"\"")

        if target._status._dir_project == ""
            call boot#log_silent(l:func_name . '::Error::target._status._dir_project ==', target._status._dir_project, a:_environment)
        endif

        if exists("g:cscopedb_file_complete")
            let target._file_complete = g:cscopedb_file_complete
        else
            let target._file_complete = l:_session_info['session_dir'] . "/.cscope.complete"
        endif

        let $CSCOPE_DB = resolve(expand(target._file_complete))

        if exists("g:cscopedb_file_partial")
            let target._file_partial = g:cscopedb_file_partial
        else
            let target._file_partial = l:_session_info['session_dir'] . "/.cscope.partial"
        endif

        let $CSCOPE_DB = resolve(expand(target._file_partial . ' ' . $CSCOPE_DB))

        if exists("g:cscopedb_auto_init")
            let target._auto_init = g:cscopedb_auto_init
        else
            let target._auto_init = 1
        endif

        if exists("g:cscopedb_extra_files")
            let target._extra_files = g:cscopedb_extra_files
        else
            let target._extra_files = l:_session_info['session_dir'] . "/.cscope.extra.files"
        endif

        if exists("g:cscopedb_src_dirs_file")
            let target._src_dirs_file = g:cscopedb_src_dirs_file
        else
            let target._src_dirs_file = l:_session_info['session_dir'] . "/.cscope.dirs.file"
        endif

        if exists("g:cscopedb_auto_files")
            let target._auto_files = g:cscopedb_auto_files
        else
            let target._auto_files = 2
        endif

        if exists("g:cscopedb_resolve_links")
            let target._resolve_links = g:cscopedb_resolve_links
        else
            let target._resolve_links = 1
        endif

        if exists("g:cscopedb_lock_file")
            let target._lock_file = g:cscopedb_lock_file
        else
            let target._lock_file = l:_session_info['session_dir'] . "/.cscope.lock"
        endif

        if exists("g:cscopedb_complete_min_interval")
            let target._complete_min_interval = g:cscopedb_complete_min_interval
        else
            let target._complete_min_interval = 180
        endif

        if exists('g:directory_for_scan')
            unlet g:directory_for_scan
        endif

        if exists('g:file_extensions')
            unlet g:file_extensions
        endif

        let initializing_file = target._status._dir_project . '/.vimrc.local'
        if filereadable(initializing_file)
            execute 'source ' . initializing_file
        endif

        if ! exists('g:directory_for_scan')
            let target._directory_for_scan = []
        else
            let target._directory_for_scan = g:directory_for_scan
        endif

        if ! exists('g:file_extensions')
            let extension = expand('%:e')

            if extension == ""
                let target._file_extensions = ['*']
            else
                let target._file_extensions = ['*.' . extension]
            endif
        else
            let target._file_extensions = g:file_extensions
        endif


        function! target._cmd_for_file_partial() closure
            let cmd = ""
            let cmd .= "(cscope -kbR "
            if self._status._file_complete_force
                let cmd .= "-u "
            else
                let cmd .= "-U "
            endif
            let cmd .= "-i" . self._file_partial . ".files -f" . self._file_partial
            let cmd .= "; rm -f ". self._lock_file
            " let cmd .= ") &>/dev/null &"
            let cmd .= ") &"
            " if 1 == s:_cscope_auto_develop
            "     call boot#log_silent(l:func_name . "::_cmd_for_file_partial::cmd", cmd, a:_environment)
            " endif
            return cmd
        endfunction

        function! target._cmd_for_file_complete() closure
            let cmd = ""
            " if len(self._directory_for_scan) == 0
            "     let self._directory_for_scan = [l:_db_target._status._dir_project]
            " endif
            " Build source dirs string for find command
            let src_dirs = ""

            if exists('self._directory_for_scan') && len(self._directory_for_scan) > 0
                for path in self._directory_for_scan
                    let src_dirs .= " \"" . self._status._dir_project . "/" . path . "\""
                    if 1 == s:_cscope_auto_develop
                        call boot#log_silent(l:func_name . "::path in self._directory_for_scan",
                            \ " \"" . self._status._dir_project . "/" . path . "\"", a:_environment)
                    endif
                endfor
            endif

            if filereadable(expand(self._src_dirs_file))
                for path in readfile(expand(self._src_dirs_file))
                    let src_dirs .= " \"" . self._status._dir_project . "/" . path . "\""
                    if 1 == s:_cscope_auto_develop
                        call boot#log_silent(l:func_name . "::path in readfile(expand(self._src_dirs_file))",
                            \ " \"" . self._status._dir_project . "/" . path . "\"", a:_environment)
                    endif
                endfor
            endif

            let heavy_search = 0
            for value in self._file_extensions
                if value == '*'
                    let heavy_search = 1
                    break
                endif
            endfor

            if src_dirs == ""
                " call boot#log_silent(l:func_name . "::failed in fallback in _cmd_for_file_complete::self._status._dir_project",
                "     \ self._status._dir_project, a:_environment)
                let src_dirs .= "\"" . self._status._dir_project . "\""
            endif

            " if src_dirs == '"' . $HOME . '"' && heavy_search
            if heavy_search
                call boot#log_silent(l:func_name . "::failed in _cmd_for_file_complete::src_dirs",
                    \ src_dirs, a:_environment)
                call boot#log_silent(l:func_name . "::failed in _cmd_for_file_complete::self._file_extensions",
                    \ self._file_extensions, a:_environment)
                return "echo \"Invalid command ::failed in _cmd_for_file_complete::src_dirs == $HOME && self._file_extensions == [" . shellescape('*', 1) . "]\""
            endif

            if src_dirs == ""
                call boot#log_silent(l:func_name . "::failed in _cmd_for_file_complete::self._status._dir_project",
                    \ self._status._dir_project, a:_environment)
                return "echo \"Invalid command ::failed in _cmd_for_file_complete::self._status._dir_project\""
            endif

            let cmd .= "("
            let cmd .= "set -f; " " turn off sh globbing
            if self._auto_files
                " Do the find command a 'portable' way
                let cmd .= "find " . src_dirs . " -type f -and \\("
                let cmd .= " -name \'" . self._file_extensions[0] . "\'"
                let element_index = 0
                for element in self._file_extensions
                    if ( 0 < element_index)
                        let cmd .= " -or -name \'" . element . "\'"
                    endif
                    let element_index += 1

                    "   let cmd .= " -name *.c   -or -name *.h -or"
                    "   let cmd .= " -name *.C   -or -name *.H -or"
                    "   let cmd .= " -name *.c++ -or -name *.h++ -or"
                    "   let cmd .= " -name *.cxx -or -name *.hxx -or"
                    "   let cmd .= " -name *.cc  -or -name *.hh -or"
                    "   let cmd .= " -name *.cpp -or -name *.hpp"

                endfor
                let cmd .= " \\) 2>/dev/null"
            else
                let cmd .= "echo "  " dummy so following cat command does not hang.
            endif

            " trick to combine extra file list below and auto list above
            " let cmd .= "| cat - | awk '{print \"\\\"\"$0\"\\\"\"}' "
            let cmd .= '| cat - | sed -e ' . shellescape('"', 1) . 's/^/' . shellescape('\"', 1). '/g' .
                \ shellescape('"', 1) . ' -e ' . shellescape('"', 1) . 's/$/' . shellescape('\"', 1). '/g' . shellescape('"', 1) . ' '
            " Append extra file list if present
            if filereadable(expand(self._extra_files))
                let cmd .= self._extra_files
            endif

            " prune entries that are in the partial DB
            if ! empty(self._status._file_dict_partial)
                let cmd .= " | grep -v -f " . self._file_partial . ".files "
            endif

            " Trick to resolve links with relative paths
            if self._resolve_links
                " let cmd .= "| xargs realpath --relative-to=\"$(pwd)\" | awk '{print \"\\\"\"$0\"\\\"\"}' "
                " let cmd .= "| xargs realpath --quiet --relative-to=\"" . self._status._dir_project . "\" | awk '{print \"\\\"\"$0\"\\\"\"}' "
                " "--relative-to=" will generate "cscope: cannot find file tinit/tmux/resurrect/tmux_resurrect_xxxx.txt" errors
                " let cmd .= '| xargs realpath --quiet --relative-to=\"' . self._status._dir_project . '\"'
                let cmd .= '| xargs realpath --quiet ' .
                    \ ' | sed -e ' . shellescape('"', 1) . 's/^/' . shellescape('\"', 1). '/g' .
                    \ shellescape('"', 1) . ' -e ' . shellescape('"', 1) . 's/$/' . shellescape('\"', 1). '/g' . shellescape('"', 1) . ' '
            endif

            let cmd .= "> " . self._file_complete . ".files"

            " Build the tags
            let cmd .= " && nice cscope -kqbR "
            if self._status._file_complete_force
                let cmd .= "-u "
            else
                let cmd .= "-U "
            endif
            let cmd .= "-i" . self._file_complete . ".files -f" . self._file_complete
            let cmd .= "; rm -f ". self._lock_file
            " let cmd .= ") &>/dev/null &"
            let cmd .= ") &"
            call assert_true(cmd != "", "cmd should not be empty")
            " if 1 == s:_cscope_auto_develop
            "     call boot#log_silent(l:func_name . "::_cmd_for_file_complete::cmd", cmd, a:_environment)
            " endif
            return cmd
        endfunction

        let cmd_partial = target._cmd_for_file_partial()
        let cmd_complete = target._cmd_for_file_complete()
        call assert_true(cmd_partial != "", "cmd_partial should not be empty")
        call assert_true(cmd_complete != "", "cmd_complete should not be empty")

        " vim-huge reports s:db_link undefined here
        " let l:file_status = {}
        " for item in ['partial', 'complete']
        "     let l:file_status[item] = s:exclusive(l:func_name, target, item)
        "     if l:file_status[item] != s:no_file_exists
        "         let result = s:db_link(item, target, a:_environment)
        "         if 0 == result
        "             let target._status._init_succeeded = 1
        "         endif
        "     endif
        " endfor
        return target
    endfunction

    if ! exists("s:_db_target_list")
        " let s:_db_target = s:target_settings(s:db_target, s:_environment)
        let s:_db_target_list = {}
        let s:_db_target_list[boot#project(fnamemodify(resolve(expand("#". bufnr(). ":p:h")), ':p:h'), s:_environment)]
            \ = s:target_settings(s:db_target, s:_environment)
    endif
    if ! exists("s:_project_previos")
        let s:_project_previos = boot#project(fnamemodify(resolve(expand("#". bufnr(). ":p:h")), ':p:h'), s:_environment)
    endif
    if ! exists("s:_project_current")
        let s:_project_current = boot#project(fnamemodify(resolve(expand("#". bufnr(). ":p:h")), ':p:h'), s:_environment)
    endif

    " 1}}}

    " Section: Internal script variables {{{1

    if ! exists("s:callback_update_setuped")
        let s:callback_update_setuped = 0
    endif

    " Section: Script functions {{{1'

    function! s:check_target(_environment)
        let l:current_absolute_path = fnamemodify(resolve(expand("#". bufnr(). ":p:h")), ':p:h')
        let l:project_dir = boot#project(l:current_absolute_path, a:_environment)
        if ! exists("s:_db_target_list[l:project_dir]")
            let s:_db_target_list[l:project_dir] = s:target_settings(s:db_target, a:_environment)
        elseif s:_db_target_list[l:project_dir]._status._dir_project != l:project_dir
            let s:_db_target_list[l:project_dir] = s:target_settings(s:db_target, a:_environment)
        endif
        let s:_project_current = l:project_dir
        return s:_db_target_list[l:project_dir]
    endfunction

    function! cscope_auto#generate() abort
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1
        if s:_environment._script_develop  == 1
            call boot#log_silent("\n", "", s:_environment)
        endif

        let l:_db_target = s:check_target(s:_environment)

        if 1 == l:_db_target._status._init_succeeded
            return result
        endif

        let enter_state = deepcopy(l:_db_target._status, 1)
        " if((l:git != "") && (l:git != "/"))
        if "" == l:_db_target._status._dir_project
            return result
        endif
        let l:lock_file = l:_db_target._lock_file
        " " "wrong character '\n'" just for testing typoes :)
        let date = boot#chomped_system("date")

        call boot#log_silent("date", date, s:_environment)
        call boot#log_silent(l:func_name . "::_dir_project", l:_db_target._status._dir_project, s:_environment)

        " call boot#log_silent(l:func_name . "::inner  \$PWD", $PWD, s:_environment)
        " call boot#log_silent(l:func_name . "::bef cd \%\:p\:h", resolve(expand('%:p:h')), s:_environment)


        " call boot#log_silent(l:func_name . "::bef cd getcwd", getcwd(), s:_environment)        " Will change
        " silent! execute '!printf "\ngenerate::outer  \$PWD\t: "$PWD' . ' >> ' . s:_environment._log_address . ' 2>&1 &' |  " Value will change

        " " :cd l:_db_target._status._dir_project
        " " execute "!cd " . l:_db_target._status._dir_project

        " " Might change other plugins' behavior
        " " silent! execute "cd " . l:_db_target._status._dir_project

        call boot#log_silent(l:func_name . "::inner  \$PWD", $PWD, s:_environment)                        " never changed
        call boot#log_silent(l:func_name . "::file   \%\:p\:h", resolve(expand('%:p:h')), s:_environment) " never changed

        call boot#log_silent(l:func_name . "::getcwd", getcwd(), s:_environment)                   " changed
        silent! execute '!printf "\ngenerate::outer  \$PWD\t: "$PWD' . ' >> ' . s:_environment._log_address . ' 2>&1 &' |  " Value changed

        if(s:_environment._is_windows == 1)
            let l:tags   = l:_db_target._status._dir_project. "\\". "tags"
            let l:csfile = l:_db_target._status._dir_project. "\\". "cscope.files"
            let l:csout  = l:_db_target._status._dir_project. "\\". "cscope.out"
        else
            let l:tags   = l:_db_target._status._dir_project. "/tags"
            let l:csfile = l:_db_target._status._dir_project. "/cscope.files"
            let l:csout  = l:_db_target._status._dir_project. "/cscope.out"
        endif

        call boot#log_silent(l:func_name . "::l:tags", l:tags, s:_environment)
        call boot#log_silent(l:func_name . "::l:csfile", l:csfile, s:_environment)
        call boot#log_silent(l:func_name . "::l:csout", l:csout, s:_environment)

        if filereadable(l:tags)
            let tags_deleted     = delete(l:tags)
            if 0 != tags_deleted
                echohl WarningMsg | echo "Fail to do tags! I cannot delete the " . l:tags | echohl None
                return result
            endif
        endif

        if 1 == s:_cscope_auto_develop
            if has("cscope") && filereadable(s:_csprg)
                silent! execute "cs kill -1"
            endif

            " call s:file_remove_if_exists(l:lock_file, s:_environment)
            call s:file_remove_if_exists(l:csfile, s:_environment)
            call s:file_remove_if_exists(l:csout, s:_environment)
        endif

        if(executable('ctags'))
            " silent! execute "!ctags -R --c-types=+p --fields=+S *"
            silent! execute "!(ctags -R --c++-kinds=+p --fields=+iaS --extras=+q ". l:_db_target._status._dir_project ." &) > /dev/null"
        endif

        if ! (executable('cscope') && has("cscope") && filereadable(s:_csprg))
            return result
        endif

        let l:_db_target._status._file_complete_force = 1
        :call s:reset(l:_db_target, s:_environment)

        if 1 == s:_cscope_auto_develop
            return result
        endif

        if(s:_environment._is_windows != 1)
            let file_types = " -name \'". l:_db_target._file_extensions[0] . "\'"
        else
            let file_types = " ". l:_db_target._file_extensions[0]
        endif
        let il_count=0
        for il in l:_db_target._file_extensions
            if (10 > il_count)
                call boot#log_silent("l:_db_target._file_extensions[ 0" . il_count . " ]", il, s:_environment)
            else
                call boot#log_silent("l:_db_target._file_extensions[ " . il_count . " ]", il, s:_environment)
            endif
            if ( 0 < il_count)
                if(s:_environment._is_windows != 1)
                    let file_types .= " -o -name \'" . il  . "\'"
                else
                    let file_types .= "," . il
                endif
            endif
            let il_count+=1
        endfor

        call boot#log_silent("\n", "", s:_environment)
        call boot#log_silent(l:func_name . "::file_types", file_types, s:_environment)
        call boot#log_silent("\n", "", s:_environment)

        if s:_environment._is_windows != 1
            " echom l:func_name . '::find: ' . '!(set -f; find . -type f -and  ' . file_types . ' | cat - | xargs realpath --relative-to=$(pwd) > cscope.files) '
            " exe '!(printf l:func_name . "::find: (set -f; find . -type f -and  ' . file_types . ' | cat -
            "             \ | xargs realpath --relative-to=$(pwd) > cscope.files)" >> '. s:_environment._log_address . ' 2>&1)'
            call boot#log_silent(l:func_name . "::find", '!(set -f; find . -type f -and \(' . file_types . ' \) 2>/dev/null
                \ | cat - | xargs realpath --relative-to=$(pwd) > cscope.files) &>/dev/null', s:_environment)
            call boot#log_silent("\n", "", s:_environment)
            " silent! execute "!find . -name '*.h' -o -name '*.c' -o -name '*.cpp' -o -name '*.java' -o -name '*.cs' -o -name
            "             \ '*.cxx' -o -name '*.hxx' -o -name '*.inl' -o -name '*.impl' | xargs realpath > cscope.files"
            silent! execute '!(set -f; find '. l:_db_target._status._dir_project .' -type f -and \(' . file_types .
                \ ' \) 2>/dev/null | cat - | xargs realpath > cscope.files) &>/dev/null'
        else
            call boot#log_silent(l:func_name . "::find", "!(dir /s/b " . file_types . " >> cscope.files) &>/dev/null ", s:_environment)
            call boot#log_silent("\n", "", s:_environment)
            " silent! execute "!(dir /s/b *.c,*.cpp,*.h,*.java,*.cs >> cscope.files &>/dev/null &)"
            silent! execute "!(dir /s/b " . file_types . " >> cscope.files) &>/dev/null"
        endif

        if filereadable("cscope.files")
            call boot#log_silent(l:func_name . "::!cscope", "!nice cscope -Rbkq -u -i cscope.files -f cscope.out &>/dev/null", s:_environment)
            call boot#log_silent("\n", "", s:_environment)
            " silent! execute "!cscope -b" "   silent! execute "!cscope -Rbq "
            silent! execute "!nice cscope -Rbkq -u -i cscope.files -f cscope.out &>/dev/null"
        elseif filereadable(l:csfile)
            call boot#log_silent(l:func_name . "::!cscope", "!cscope -Rbkq -i ". l:csfile . " -f " . l:csfile . " &>/dev/null", s:_environment)
            call boot#log_silent("\n", "", s:_environment)
            silent! execute "!cscope -Rbkq -u -i ". l:csfile . " -f " . l:csfile . " &>/dev/null"
        else
            echohl WarningMsg | echo "Fail to read cscope.files!" | echohl None
            return result
        endif

        " Without silent! or silent, youu will receive a "Press ENTER or type command to continue" prompt
        silent! execute "normal :"

        if filereadable("cscope.out")
            call boot#log_silent(l:func_name . "::cs add", "cs add cscope.out " .
                \ l:_db_target._status._dir_project . " &>/dev/null ", s:_environment)
            call boot#log_silent("\n", "", s:_environment)
            " :call job_start("cs add cscope.out")
            " :cs add cscope.out
            silent! execute "cs add cscope.out " . l:_db_target._status._dir_project
        elseif filereadable(l:csout)
            call boot#log_silent(l:func_name . "::cs add", "cs add " . l:csout . ' ' . l:_db_target._status._dir_project, s:_environment)
            call boot#log_silent("\n", "", s:_environment)
            " :call job_start("cs add " . l:csout . ' ' . l:_db_target._status._dir_project)
            silent! execute "cs add " . l:csout . ' ' . l:_db_target._status._dir_project
            " :cs show
        else
            echohl WarningMsg | echo "Fail to read cscope.out!" | echohl None
            return result
        endif

        let l:_db_target._status._init_succeeded = 1
        " 1 == a:cscope_auto_develop


        " call s:chomped_system("!clear & | redraw!")
        silent! execute "!clear &" | redraw!
        execute "redrawstatus!"


        let result = 0
        call l:_db_target._status.show(l:func_name, enter_state, s:_environment)
        if s:_environment._script_develop  == 1 &&result == 0
            call boot#log_silent(l:func_name, "done", s:_environment)
            call boot#log_silent("\n", "", s:_environment)
        endif
        return result
    endfunction

    function! cscope_auto#setup(auto_update)
        let s:cscope_auto_update = a:auto_update
        let s:callback_update_setuped = 1
    endfunction

    function! s:shell_silent(check_result, cmd, _db_target, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1

        let l:_db_target = a:_db_target

        " if a:_environment._script_develop  == 1
        "     call boot#log_silent("\n", "", a:_environment)
        " endif
        let enter_state = deepcopy(l:_db_target._status, 1)
        " Use perl if we have it. Using :!<shell command>
        " breaks the tag stack for some reason.
        " echom l:func_name . "::cmd: " . a:cmd
        " call boot#log_silent("\n", "", a:_environment)
        " silent! execute '!(printf "' . l:func_name . '::cmd\t: ' .
        "     \ a:cmd .'")' . ' >> ' . a:_environment._log_address . ' 2>&1 &'

        " call boot#log_silent("\n", "", a:_environment)
        call boot#log_silent(l:func_name . "::cmd", a:cmd, a:_environment)
        " call boot#log_silent("\n", "", a:_environment)

        " LogSilent a:_environment._log_address "\n" ""
        " call boot#chomped_system("printf \n >> " . a:_environment._log_address . "  &>/dev/null")
        " silent! execute "!(printf \n  >> " . a:_environment._log_address . " 2>&1) &>/dev/null"

        if has('perl')
            let result = execute("perl system('" . a:cmd . "')")
            redraw!
        else
            let result = execute("!" . a:cmd)
            redraw!
        endif

        let result = a:check_result()

        call l:_db_target._status.show(l:func_name, enter_state, a:_environment)

        if a:_environment._script_develop  == 1 && result == 0
            call boot#log_silent(l:func_name . "::result", result, a:_environment)
            " call boot#log_silent(l:func_name, "done", a:_environment)
            call boot#log_silent("\n", "", a:_environment)
        endif
        return result
    endfunction

    " Add the file to the partial DB file list. {{{2
    " This moves the file to the partial cscope DB and triggers an update of the necessary databases.
    function! s:file_dict_update(_caller_info, _file, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1
        if a:_environment._script_develop  == 1
            call boot#log_silent("\n", "", a:_environment)
        endif

        let l:_db_target = s:check_target(a:_environment)

        let l:caller_info = {'func_name': l:func_name, 'result': 1,
            \ 'enter_state': deepcopy(l:_db_target._status, 1)}

        " let l:_db_target._status._file_partial[s:out_of_date] = 1
        call s:exclusive(l:func_name, l:_db_target, "partial", s:out_of_date, a:_environment)

        " If file moves to partial DB then we also do a complete DB update so
        " we don't end up with duplicate lookups.
        if l:_db_target._resolve_links
            " let path = fnamemodify(resolve(expand(a:_file)), ":p:.")
            " E944: Reverse range in character class
            " let path = fnameescape(fnamemodify(resolve(expand(a:_file)), ":p"))
            let path = fnameescape(fnamemodify(resolve(expand("#". bufnr(). ":p")), ':p'))
        else
            " let path = fnamemodify(expand(a:_file), ":p:.")
            " E944: Reverse range in character class
            " let path = fnameescape(fnamemodify(expand(a:_file), ":p"))
            let path = fnameescape(fnamemodify(expand("#". bufnr(). ":p"), ':p'))
        endif

        " call boot#log_silent(l:func_name, path, a:_environment)

        " for [key, value] in items(l:_db_target._status._file_dict_partial)
        "     call boot#log_silent(l:func_name . "::" . key, value, a:_environment)
        " endfor

        if ! has_key(l:_db_target._status._file_dict_partial, path)
            let l:_db_target._status._file_dict_partial[path] = 1
            " let l:_db_target._status._file_complete[s:out_of_date] = 1
            call s:exclusive(l:func_name, l:_db_target, 'complete', s:out_of_date, a:_environment)
            call writefile(keys(l:_db_target._status._file_dict_partial),
                \ expand(l:_db_target._file_partial) . ".files")
        endif

        for [key, value] in items(l:_db_target._status._file_dict_partial)
            call boot#log_silent(l:func_name . "::" . key, value, a:_environment)
        endfor

        if a:_caller_info['func_name'] !~? 'db_update'
            let l:result = s:update_pre(l:caller_info, a:_environment)
            for item in l:result
                call s:db_update(l:caller_info, item, a:_environment)
            endfor
        endif

    endfunction

    function! s:read_link_status(_db_target, _file_type, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let db_result = ""

        let query_links = substitute(call('execute', ["cs show"]), '\n\+$', '', '')
        " let l:link_list = execute('cs show')->split()
        " let l:link_list = split(query_links, ' ')
        let l:link_list = query_links->split()
        " call boot#log_silent(l:func_name . '::db_list', db_list, a:_environment)
        " call boot#log_silent(l:func_name . '::query_links', query_links, a:_environment)
        if query_links =~? "no cscope connections"
            return db_result
        endif

        if type(l:link_list) == v:t_list
            " let l:_db_target._status._ready_to_switch = 0
            let index = 0

            call boot#log_silent(l:func_name . "::execute('cs show').split()
                \ to a list", l:link_list, a:_environment)
            let l:db_filename = eval('a:_db_target._file_' . a:_file_type)
            for item in l:link_list
                if item =~? l:db_filename
                    call boot#log_silent(l:func_name . "::l:db_filename", item, a:_environment)
                    let db_result = item
                endif
                let index += 1
            endfor

            " " 0 based index
            " let file_name = l:link_list[0]
            " call boot#log_silent(l:func_name . "::linked file_name at index 0", file_name, a:_environment)

        elseif type(l:link_list) == v:t_string && l:link_list =~ '.cscope'
            call boot#log_silent(l:func_name . "::execute('cs show').split()
                \ is not a list", l:link_list, a:_environment)
            let l:db_filename = eval('a:_db_target._file_' . a:_file_type)
            if l:link_list =~? l:db_filename
                call boot#log_silent(l:func_name . "::l:db_filename", l:db_filename, a:_environment)
                let db_result = l:db_filename
            endif
        endif

        return db_result
    endfunction

    function! s:db_link(_file_type, _db_target, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1
        if a:_environment._script_develop  == 1
            call boot#log_silent("\n", "", a:_environment)
        endif
        let l:_db_target = a:_db_target
        let enter_state = deepcopy(l:_db_target._status, 1)
        silent! execute 'set csprg=' . boot#chomped_system("which cscope")
        set csto=0
        set cst
        set nocsverb

        for [key, V] in items(s:_db_target_list)
            if V == a:_db_target
                " use echo v:errors to read the output (:h assert-return)
                call assert_true(V is a:_db_target, "Deep copy sould not give this message")
            endif
            if filereadable(eval('V._file_' . a:_file_type)) && key != l:_db_target._status._dir_project
                " if eval('V._status._linked_' . a:_file_type) == 1 && key != l:_db_target._status._dir_project
                call assert_true(! (V is a:_db_target), "If you saw this,
                    \ it means that deep copy has not made things work")
                " silent! execute 'cs kill ' . V._file_complete
                call s:db_break(a:_file_type, V, a:_environment)
            endif
        endfor

        " let db_list = execute('cs show')
        let query_links = substitute(call('execute', ["cs show"]), '\n\+$', '', '')
        if query_links =~? eval('l:_db_target._file_' . a:_file_type)
            call s:db_break(a:_file_type, l:_db_target, a:_environment)
            " silent cs reset
            " silent! execute 'let l:_db_target._status._linked_' . a:_file_type . ' = 0'
        endif

        " silent execute "cs add " . l:_db_target._file_partial
        call boot#log_silent(l:func_name . "::"
            \, "cs add " . eval('l:_db_target._file_' . a:_file_type) .
            \ ' ' . l:_db_target._status._dir_project, a:_environment)

        " silent! execute "( cs add " . eval('l:_db_target._file_' . a:_file_type) .
        "     \ ' ' . l:_db_target._status._dir_project . " ) &>/dev/null &"

        silent! execute "cs add " . eval('l:_db_target._file_' . a:_file_type) .
            \ ' ' . l:_db_target._status._dir_project

        let db_result = s:read_link_status(a:_db_target, a:_file_type, a:_environment)
        if "" == db_result
            call s:db_break(a:_file_type, l:_db_target, a:_environment)
        else
            call boot#log_silent(l:func_name . "::linked file", db_result, a:_environment)
            let s:_project_previos = l:_db_target._status._dir_project
            " call s:exclusive(l:func_name, eval('l:_db_target._status._file_' . a:_file_type), s:linked, a:_environment)
            if a:_file_type =~? "complete"
                let l:_db_target._status._file_complete_link_time = localtime()
            endif
            let result = 0
        endif

        set csverb!

        call l:_db_target._status.show(l:func_name, enter_state, a:_environment)
        if a:_environment._script_develop  == 1 && result == 0
            call boot#log_silent(l:func_name, "done", a:_environment)
            call boot#log_silent("\n", "", a:_environment)
        endif
        return result
    endfunction

    function! s:db_link_ready_to_switch(_db_target, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let ready = 0
        let l:_db_target = a:_db_target
        if ! l:_db_target._status._ready_to_switch
            call boot#log_silent(l:func_name . "::cancelled by ! l:_db_target._status._ready_to_switch",
                \ ! l:_db_target._status._ready_to_switch, a:_environment)
            return ready
        endif
        if filereadable(expand(l:_db_target._lock_file))
            call boot#log_silent(l:func_name . "::cancelled by filereadable(expand(l:_db_target._lock_file))",
                \ filereadable(expand(l:_db_target._lock_file)), a:_environment)
            let ready = s:try_unlock(l:_db_target, a:_environment)
            if 0 == ready
                return ready
            endif
        endif
        let ready = 1
        return ready
    endfunction

    function! s:db_break(_file_type, _db_target, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let l:_db_target = a:_db_target
        silent! execute 'cs kill l:_db_target._file_' . a:_file_type
        " silent! cs reset
        " silent! execute 'let l:_db_target._status._linked_' . a:_file_type . ' = 0'
        call s:exclusive(l:func_name, l:_db_target, a:_file_type, s:no_file_exists, a:_environment)
        " let l:_db_target._status._file_complete['link_reseted'] = 1
        " silent cs kill -1
        let l:_db_target._status._ready_to_switch = 0
        call boot#log_silent(l:func_name . "::link reseted on l:_db_target._status._file_" . a:_file_type,
            \ s:exclusive(l:func_name, l:_db_target, a:_file_type), a:_environment)
    endfunction

    " Reset/add the cscope DB connection if the database was recently {{{2
    " updated/created and the update has finished.
    function! s:db_link_switch(_db_target, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1
        if a:_environment._script_develop  == 1
            call boot#log_silent("\n", "", a:_environment)
            call boot#log_silent(l:func_name, "entered", a:_environment)
        endif

        let l:_db_target = a:_db_target
        let enter_state = deepcopy(l:_db_target._status, 1)

        for item in ["partial", "complete"]
            " if eval('s:exclusive(l:func_name, l:_db_target._status._file_' . item . ') == s:updated')
            " if ! eval('l:_db_target._status._linked_' . item)
            let db_result = s:read_link_status(l:_db_target, item, a:_environment)
            " if s:exclusive(l:func_name, eval('l:_db_target._status._file_' . item)) != s:linked
            if "" == db_result
                " silent execute "cs add " . l:_db_target._file_partial
                call boot#log_silent(l:func_name . '::',
                    \ '(cs add ' . eval('l:_db_target._file_' . item) . ' ' .
                    \ l:_db_target._status._dir_project . ') &>/dev/null &', a:_environment)
                " silent! execute "(cs add " . l:_db_target._file_partial .
                "     \ ' ' . l:_db_target._status._dir_project . " ) &>/dev/null &"
                " let l:_db_target._status._linked_partial = 1
                let result = s:db_link(item, l:_db_target, a:_environment)
            else
                call s:db_break(item, l:_db_target, a:_environment)
                " silent! cs reset
                " let l:_db_target._status._linked_partial = 0
                " " let l:_db_target._status._file_partial['link_reseted'] = 1
                " let l:_db_target._status._ready_to_switch = 0
                " call boot#log_silent(l:func_name, "link reseted by l:_db_target._status._linked_partial::" .
                "        \ l:_db_target._status._linked_partial, a:_environment)
            endif
            " endif
        endfor

        " " if l:_db_target._status._file_partial == 2
        " if l:_db_target._status._file_partial[s:updated] == 1
        "     if ! l:_db_target._status._linked_partial
        "         " silent execute "cs add " . l:_db_target._file_partial
        "         call boot#log_silent(l:func_name . "::"
        "                     \, "(cs add " . l:_db_target._file_partial . ' ' . l:_db_target._status._dir_project . " ) &>/dev/null &", a:_environment)
        "         " silent! execute "(cs add " . l:_db_target._file_partial . ' ' . l:_db_target._status._dir_project . " ) &>/dev/null &"
        "         " let l:_db_target._status._linked_partial = 1
        "         let result = s:db_link("partial", l:_db_target, a:_environment)
        "     else
        "         call s:db_break("partial", l:_db_target, a:_environment)
        "         " silent! cs reset
        "         " let l:_db_target._status._linked_partial = 0
        "         " " let l:_db_target._status._file_partial['link_reseted'] = 1
        "         " let l:_db_target._status._ready_to_switch = 0
        "         " call boot#log_silent(l:func_name, "link reseted by l:_db_target._status._linked_partial::" .
        "         "        \ l:_db_target._status._linked_partial, a:_environment)
        "     endif
        " elseif l:_db_target._status._file_complete[s:updated] == 1
        "     if ! l:_db_target._status._linked_complete
        "         " silent execute "cs add " . l:_db_target._file_complete
        "         call boot#log_silent(l:func_name . "::"
        "                     \, "(cs add " . l:_db_target._file_complete . ' ' . l:_db_target._status._dir_project . " ) &>/dev/null &", a:_environment)
        "         " silent! execute "(cs add " . l:_db_target._file_complete . ' ' . l:_db_target._status._dir_project . " ) &>/dev/null &"
        "         " let l:_db_target._status._linked_complete = 1
        "         let result = s:db_link("complete", l:_db_target, a:_environment)
        "     else
        "         call s:db_break("complete", l:_db_target, a:_environment)
        "         " silent! cs reset
        "         " let l:_db_target._status._linked_complete = 0
        "         " " let l:_db_target._status._file_complete['link_reseted'] = 1
        "         " let l:_db_target._status._ready_to_switch = 0
        "         " call boot#log_silent(l:func_name, "link reseted by l:_db_target._status._linked_complete::" .
        "         "        \ l:_db_target._status._linked_complete, a:_environment)
        "     endif
        "     " let l:_db_target._status._file_complete_link_time = localtime()
        "     " let l:_db_target._status._file_complete_link_time = boot#chomped_system("stat -L -c '%Y' '" . l:_db_target._file_complete . "'")
        " endif

        " Don't call hook if there are partial updates left.
        " Complete update has backoff delay, so we call hook even if
        " _file_complete has an update pending.
        " if l:_db_target._status._file_partial != 1
        if s:exclusive(l:func_name, l:_db_target, 'partial') == s:out_of_date
            if s:callback_update_setuped
                call s:cscope_auto_update(0)
            endif
        endif

        call l:_db_target._status.show(l:func_name, enter_state, a:_environment)
        if a:_environment._script_develop == 1 && result == 0
            call boot#log_silent(l:func_name, "done", a:_environment)
            call boot#log_silent("\n", "", a:_environment)
        endif
        return result
    endfunction

    function! s:file_remove_if_exists(file, _environment)
        if filereadable(expand(a:file))
            " call s:shell_silent("rm ". a:file, l:_db_target._status, a:_environment)
            let file_deleted = delete(a:file)
            if 0 != file_deleted
                echohl WarningMsg | echo "Fail to delete the " . a:file | echohl None
                return 1
            endif
        endif
        return 0
    endfunction

    function! s:try_unlock(_db_target, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let _next_step_available = 0
        let l:_db_target = a:_db_target
        " let l:update_time_not_arrived = localtime() <
        "             \ boot#chomped_system("stat -L -c '%Y' '" . l:_db_target._file_complete . "'")
        "             \ + l:_db_target._complete_min_interval

        let l:update_time_not_arrived = 0
        " if filereadable(l:_db_target._file_partial)
        "     if l:_db_target._status._file_complete_link_time >
        "         \ boot#chomped_system("stat -L -c '%Y' '" . l:_db_target._file_partial . "'")
        "         let l:update_time_not_arrived = 1
        "     endif
        " endif
        if filereadable(l:_db_target._file_complete)
            if l:_db_target._status._file_complete_link_time >
                \ boot#chomped_system("stat -L -c '%Y' '" . l:_db_target._file_complete . "'")
                let l:update_time_not_arrived = 1
            endif
        endif

        if l:update_time_not_arrived
            " localtime() < l:_db_target._status._file_complete_link_time + l:_db_target._complete_min_interval
            call boot#log_silent(l:func_name . "::l:update_time_not_arrived", l:update_time_not_arrived, a:_environment)
        else
            call s:file_remove_if_exists(l:_db_target._lock_file, a:_environment)
            call boot#log_silent(l:func_name . "::unlock " . l:_db_target._lock_file,
                \ ! filereadable(expand(l:_db_target._lock_file)), a:_environment)
            " let l:_db_target._status._file_complete_force = 1
            let _next_step_available = 1
        endif
        return _next_step_available
    endfunction

    function! s:update_pre(_caller_info, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        call boot#log_silent(l:func_name . "::a:_caller_info", a:_caller_info, a:_environment)
        let _db_needs_update = []

        let l:_db_target = s:check_target(a:_environment)

        if filereadable(expand(l:_db_target._lock_file))

            " Limit how often a complete DB update can occur.

            " if s:exclusive(l:func_name, l:_db_target, 'partial') == s:updated
            "     \ && s:exclusive(l:func_name, l:_db_target, 'complete') == s:out_of_date
            if s:exclusive(l:func_name, l:_db_target, 'complete') == s:updated
                " let l:update_time_not_arrived = localtime() < l:_db_target._status._file_complete_link_time
                    \ + l:_db_target._complete_min_interval
                let _db_needs_update = s:try_unlock(l:_db_target, a:_environment)
                " let l:update_time_not_arrived = localtime() <
                "             \ boot#chomped_system("stat -L -c '%Y' '" . l:_db_target._file_complete . "'")
                "             \ + l:_db_target._complete_min_interval
                " if l:update_time_not_arrived
                "     " localtime() < l:_db_target._status._file_complete_link_time + l:_db_target._complete_min_interval
                "     call boot#log_silent(l:func_name . "::l:update_time_not_arrived", l:update_time_not_arrived, a:_environment)
                "     return _db_needs_update
                " else
                "     call s:file_remove_if_exists(l:_db_target._lock_file, a:_environment)
                "     let l:_db_target._status._file_complete_force = 1
                " endif
                if 0 == _db_needs_update
                    return _db_needs_update
                endif
            endif

            " let l:dir  = boot#project(a:_environment)
            call boot#log_silent(l:func_name . "::_dir_project", l:_db_target._status._dir_project, a:_environment)
            call boot#log_silent(l:func_name . "::getcwd()", getcwd(), a:_environment)
            call boot#log_silent(l:func_name . "::resolve(expand(l:_db_target._lock_file))",
                \ resolve(expand(l:_db_target._lock_file)), a:_environment)
            call boot#log_silent(l:func_name . "::filereadable(expand(l:_db_target._lock_file))",
                \ filereadable(expand(l:_db_target._lock_file)), a:_environment)
            call boot#log_silent(l:func_name . "::db_update is still working with the holding of l:_db_target._lock_file",
                \ l:_db_target._lock_file, a:_environment)
            call boot#log_silent(l:func_name . "::db_update is still working with the holding of
                \ resolve(expand(l:_db_target._lock_file))", resolve(expand(l:_db_target._lock_file)), a:_environment)
            " let enter_state = deepcopy(l:_db_target._status, 1)
            " call s:reset_force(a:file_extensions, l:_db_target._status, a:_environment)
            " call l:_db_target._status.show(l:func_name, enter_state, a:_environment)

            " return _db_needs_update
        endif

        if s:exclusive(l:func_name, l:_db_target, 'partial') == s:updated
            if a:_environment._script_develop  == 1
                call boot#log_silent(l:func_name . "::cancelled by s:exclusive(l:func_name, l:_db_target, 'partial') is ",
                    \ s:exclusive(l:func_name, l:_db_target, 'partial'), a:_environment)
            endif
            let l:_db_target._status._ready_to_switch = 1
            return _db_needs_update
        else
            call add(_db_needs_update, "partial")
        endif
        if s:exclusive(l:func_name, l:_db_target, 'complete') == s:updated
            if a:_environment._script_develop  == 1
                call boot#log_silent(l:func_name . "::cancelled by s:exclusive(l:func_name, l:_db_target, 'complete') is ",
                    \ s:exclusive(l:func_name, l:_db_target, 'complete'), a:_environment)
            endif
            let l:_db_target._status._ready_to_switch = 1
            return _db_needs_update
        else
            call add(_db_needs_update, "complete")
        endif

        return _db_needs_update

    endfunction

    " Update any/all of the DBs {{{2
    function! s:db_update(_caller_info, _file_type, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1
        let l:_db_target = s:check_target(a:_environment)
        if a:_environment._script_develop  == 1
            call boot#log_silent("\n", "", a:_environment)
            call boot#log_silent(l:func_name, "entered", a:_environment)
            call boot#log_silent(l:func_name . "::l:_db_target", l:_db_target, a:_environment)
        endif

        let enter_state = deepcopy(l:_db_target._status, 1)

        " Touch lock file synchronously

        " Might change other plugins' behavior
        " silent! execute "cd " . l:_db_target._status._dir_project

        " call boot#log_silent(l:func_name, "touch " . l:_db_target._lock_file, a:_environment)
        call s:shell_silent({ -> boot#chomped_system('if [ -f "' . l:_db_target._lock_file . '" ];
            \ then echo 0; else echo 1; fi') }, "touch " . l:_db_target._lock_file, l:_db_target, a:_environment)

        " let cmd_for_file_complete = ""
        " let cmd_for_file_partial = ""

        " " Do partial update first. We'll do complete update
        " " after the partial updates are done.
        " if l:_db_target._status._file_partial[s:out_of_date] == 1

        "     " " let l:_db_target._status._file_partial[s:updated] = 1 | " let l:_db_target._status._file_partial = 2
        "     " call s:exclusive(l:func_name, l:_db_target, "partial", s:updated, a:_environment)
        " else

        "     " " let l:_db_target._status._file_complete[s:updated] = 1
        "     " call s:exclusive(l:func_name, l:_db_target, 'complete', s:updated, a:_environment)
        "     " let l:_db_target._status._file_complete_force = 0
        " endif


        if s:exclusive(l:func_name, l:_db_target, a:_file_type) != s:updated
            call boot#log_silent(l:func_name . '::s:exclusive(l:func_name, l:_db_target._status._file_' . a:_file_type . ') is ',
                \ s:exclusive(l:func_name, l:_db_target, a:_file_type), a:_environment)

            " resolve(expand("#". bufnr(). ":p"))

            " call s:file_dict_update({'func_name': l:func_name, 'result': 1, 'enter_state':
            "     \ deepcopy(l:_db_target._status, 1)},
            "     \ expand("<afile>"), a:_environment)

            " let cmd_partial = l:_db_target._cmd_for_file_partial()
            " call boot#log_silent(l:func_name . "::cmd_partial", cmd_partial, a:_environment)
            " let cmd_complete = l:_db_target._cmd_for_file_complete()
            " call boot#log_silent(l:func_name . "::cmd_complete", cmd_complete, a:_environment)

            " let l:CmdRef = eval('l:_db_target._cmd_for_file_' . a:_file_type)
            " execute 'let cmd_' . a:_file_type . ' = l:CmdRef()'
            " call boot#log_silent(l:func_name . "::current case cmd_" . a:_file_type,
            "     \ eval('cmd_' . a:_file_type), a:_environment)
            " call boot#log_silent(l:func_name . "::eval('l:_db_target._cmd_for_file_' . a:_file_type)()",
            "     \ eval('l:_db_target._cmd_for_file_' . a:_file_type)(), a:_environment)
            " let cmd_eval = eval('l:_db_target._cmd_for_file_' . a:_file_type . '()')
            " " let cmd = execute('l:_db_target._cmd_for_file_' . a:_file_type . '()')
            " " let cmd = substitute(call('execute', ['l:_db_target._cmd_for_file_' . a:_file_type . '()']), '\n\+$', '', '')
            " call boot#log_silent(l:func_name . "::cmd_eval", cmd_eval, a:_environment)

            let result = s:shell_silent({ -> boot#chomped_system('if [ -f "' . eval('l:_db_target._file_' . a:_file_type) . '" ];
                \ then echo 0; else echo 1; fi') }, eval('l:_db_target._cmd_for_file_' . a:_file_type)(), l:_db_target, a:_environment)

        endif

        function! s:update_status() closure
            let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
            " ps wf -A -o user,group,pid,tty,stat,state,args | grep cscope
            if s:exclusive(l:func_name, l:_db_target, a:_file_type) != s:updated
                if 0 == s:try_unlock(l:_db_target, a:_environment)
                    return
                endif
                " if filereadable(expand(l:_db_target._file_partial)) && ! filereadable(expand(l:_db_target._lock_file))
                if eval('filereadable(expand(l:_db_target._file_' . a:_file_type .  '))')
                    call s:exclusive(l:func_name, l:_db_target, a:_file_type, s:updated, a:_environment)
                    " execute 'let l:_db_target._status._file_exists_' . a:_file_type . ' = 1'
                    let l:_db_target._status._ready_to_switch = 1
                    if a:_file_type == 'partial'
                        for [key, value] in items(l:_db_target._status._file_dict_partial)
                            call boot#log_silent(l:func_name . "::" . key, value, a:_environment)
                        endfor
                    endif
                    if a:_file_type == 'complete'
                        let l:_db_target._status._file_complete_force = 0
                    endif
                    let result = 0
                else
                    " execute 'let l:_db_target._status._file_exists_' . a:_file_type . ' = 0'
                    call s:exclusive(l:func_name, l:_db_target, a:_file_type, s:no_file_exists, a:_environment)
                    let result = 1
                endif
            endif

            call l:_db_target._status.show(l:func_name, enter_state, a:_environment)

            if result == 0
                " if 0 == result
                " call s:file_remove_if_exists(l:_db_target._lock_file, a:_environment)
                let l:_db_target._status._ready_to_switch = 1

                if s:callback_update_setuped
                    call s:cscope_auto_update(1)
                endif
                " endif

                if s:db_link_ready_to_switch(l:_db_target, a:_environment)
                    let result = s:db_link_switch(l:_db_target, a:_environment)
                endif

                if a:_environment._script_develop  == 1 && 0 == result
                    call boot#log_silent(l:func_name, "done", a:_environment)
                    call boot#log_silent("\n", "", a:_environment)
                endif

                call l:_db_target._status.show(a:_caller_info['func_name'], a:_caller_info['enter_state'], a:_environment)

                if a:_environment._script_develop  == 1 && 0 == result
                    call boot#log_silent(a:_caller_info['func_name'], "done", a:_environment)
                    call boot#log_silent("\n", "", a:_environment)
                endif
            endif
        endfunction

        if 1 == result
            " Refer to following setting
            " let target._complete_min_interval = 180
            call timer_start(60, { -> s:update_status() }, {'repeat': 3})
        else
            call s:update_status()
        endif

    endfunction

    function! s:db_tick(_environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))

        let l:_db_target = s:check_target(a:_environment)

        " let s:_db_target = s:target_settings(s:db_target, s:_environment)

        if a:_environment._script_develop == 1
            call boot#log_silent("\n", "", a:_environment)
        endif

        let l:caller_info = {'func_name': l:func_name, 'result': 1, 'enter_state': deepcopy(l:_db_target._status, 1)}
        let l:result = s:update_pre(l:caller_info, a:_environment)
        for item in l:result
            call s:db_update(l:caller_info, item, a:_environment)
        endfor
    endfunction

    " Do a FULL DB update {{{2
    function! s:db_unify_update(_environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1
        if a:_environment._script_develop  == 1
            call boot#log_silent("\n", "", a:_environment)
        endif

        let l:_db_target = s:check_target(a:_environment)

        " let l:_db_target._status._dir_project  = boot#project(a:_environment)

        " let l:_db_target._status._file_complete[s:out_of_date] = 1
        call s:exclusive(l:func_name, l:_db_target, 'complete', s:out_of_date, a:_environment)
        if ! empty(l:_db_target._status._file_dict_partial)
            " let l:_db_target._status._file_partial[s:out_of_date] = 1
            call s:exclusive(l:func_name, l:_db_target, "partial", s:out_of_date, a:_environment)
        endif
        let l:caller_info = {'func_name': l:func_name, 'result': 1, 'enter_state': deepcopy(l:_db_target._status, 1)}
        let l:result = s:update_pre(l:caller_info, a:_environment)
        if 0 < len(l:result)
            call s:db_update(l:caller_info, 'partial', a:_environment)
            call s:db_update(l:caller_info, 'complete', a:_environment)
        endif
    endfunction

    " Enable/init dynamic cscope updates {{{2
    function! s:reset(_db_target, _environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1
        " Blow away cscope connections (allows re-init)

        " let project_dir_current  = boot#project(a:_environment)
        " let l:_db_target  = s:_db_target_list[project_dir_current]
        let l:_db_target = a:_db_target
        call assert_true(l:_db_target is a:_db_target, "l:_db_target is a:_db_target should be True")
        if ! (l:_db_target is a:_db_target)
            call boot#log_silent(l:func_name . "::Error::! (l:_db_target is a:_db_target)",
                \ ! (l:_db_target is a:_db_target), a:_environment)
        endif
        if a:_environment._script_develop  == 1
            call boot#log_silent("\n", "", a:_environment)
        endif
        let enter_state = deepcopy(l:_db_target._status, 1)
        if "" != l:_db_target._status._dir_project
            call s:file_remove_if_exists(l:_db_target._lock_file, a:_environment)
            " let l:_db_target._status._file_complete_link_time = 0

            " If they DBs exist, then add them before the update.
            for item in ["complete", "partial"]
                silent! execute 'cs kill l:_db_target._file_' . item
                " silent! execute 'let l:_db_target._status._linked_' . item . ' = 0'
                call s:exclusive(l:func_name, l:_db_target, item, s:no_file_exists, a:_environment)
                if filereadable(expand(eval('l:_db_target._file_' . item)))
                    " silent execute "cs add " . l:_db_target._file_complete
                    call boot#log_silent("init::", "(cs add " . eval('l:_db_target._file_' . item) .
                        \ ' ' . l:_db_target._status._dir_project . " ) &>/dev/null &", a:_environment)
                    " silent! execute "(cs add " . l:_db_target._file_complete .
                    "     \ ' ' . l:_db_target._status._dir_project . " ) &>/dev/null &"
                    " let l:_db_target._status._linked_complete = 1
                    call s:db_link(item, l:_db_target, a:_environment)
                endif
            endfor
            if filereadable(expand(l:_db_target._file_partial))
                " Seed the _file_dict_partial dictionary with the file list
                " from the partial DB.
                for path in readfile(expand(l:_db_target._file_partial) . ".files")
                    let l:_db_target._status._file_dict_partial[path] = 1
                endfor
            endif

            " call s:au_install(l:_db_target._status, a:_environment)
            call s:db_unify_update(a:_environment)
            let l:_db_target._status._init_succeeded = 1
        endif


        call l:_db_target._status.show(l:func_name, enter_state, a:_environment)
        if a:_environment._script_develop  == 1 && result == 0
            call boot#log_silent(l:func_name, "done", a:_environment)
            call boot#log_silent("\n", "", a:_environment)
        endif
        return result
    endfunction

    " Force full update of DB {{{2

    function! cscope_auto#reset_force()
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let result = 1
        " if s:initialize_avaiable()
        let l:_db_target = s:check_target(s:_environment)

        if s:_environment._script_develop  == 1
            call boot#log_silent("\n", "", s:_environment)
            " call boot#log_silent(l:func_name . "::boot" . shellescape('#', 1) .
            "     \ "project(resolve(expand(" . shellescape('#', 1) . " . bufnr() . ':p:h')), a:_environment)",
            "     \ boot#project(resolve(expand('#'. bufnr(). ':p:h')), a:_environment), a:_environment)
            call boot#log_silent(l:func_name . '::boot\#project(resolve(expand(' . shellescape('#', 1) .
                \ ' . bufnr() . ' . shellescape(':p:h', 1) . ')), a:_environment)',
                \ boot#project(resolve(expand('#'. bufnr(). ':p:h')), s:_environment), s:_environment)
            call boot#log_silent(l:func_name . "::l:_db_target._status._dir_project",
                \ l:_db_target._status._dir_project, s:_environment)
        endif
        let enter_state = deepcopy(l:_db_target._status, 1)

        if "" != l:_db_target._status._dir_project
            " let l:lock_file = s:_db_target._lock_file
            let l:_db_target._status._file_complete_force = 1
            let result = s:reset(l:_db_target, s:_environment)
        endif

        call l:_db_target._status.show(l:func_name, enter_state, s:_environment)

        if s:_environment._script_develop  == 1 && result == 0
            call boot#log_silent(l:func_name, "done", s:_environment)
            call boot#log_silent("\n", "", s:_environment)
        endif
        " else
        "     call boot#log_silent(l:func_name . "s:initialize_avaiable()", s:initialize_avaiable(), s:_environment)
        " endif
        return result
    endfunction

    " 2}}}

    function! s:on_bufwritepost(_environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        let l:_db_target = s:check_target(a:_environment)
        call s:exclusive(l:func_name, l:_db_target, 'complete', s:out_of_date, a:_environment)
        call boot#log_silent(l:func_name . "s:exclusive(l:func_name, l:_db_target, 'complete')",
            \ s:exclusive(l:func_name, l:_db_target, 'complete'), a:_environment)
        if ! empty(l:_db_target._status._file_dict_partial)
            " let l:_db_target._status._file_partial[s:out_of_date] = 1
            call s:exclusive(l:func_name, l:_db_target, "partial", s:out_of_date, a:_environment)
            call boot#log_silent(l:func_name . "s:exclusive(l:func_name, l:_db_target, 'partial')",
                \ s:exclusive(l:func_name, l:_db_target, 'partial'), a:_environment)
        endif
        let l:caller_info = {'func_name': l:func_name, 'result': 1,
            \ 'enter_state': deepcopy(l:_db_target._status, 1)}
        let l:result = s:update_pre(l:caller_info, a:_environment)
        for item in l:result
            call s:db_update(l:caller_info, item, a:_environment)
        endfor
    endfunction

    function! s:on_bufswitch(_environment)
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        " let project_dir = boot#project(resolve(expand('#'. bufnr(). ':p:h')), a:_environment)
        let l:_db_target = s:check_target(a:_environment)
        if s:_project_previos == l:_db_target._status._dir_project
            return
        endif
        if bufname('%') =~? "buffergator"
            return
        endif
        if ! boot#is_writable(winnr())
            return
        endif
        if l:_db_target._status._init_succeeded == 0

            call assert_true(l:_db_target._status._dir_project != "",
                \ "l:_db_target._status._dir_project should not be \"\"")
            if l:_db_target._status._dir_project == ""
                call boot#log_silent(l:func_name . '::Error::l:_db_target._status._dir_project ==',
                    \ l:_db_target._status._dir_project, a:_environment)
            endif

            let l:_db_target._status._file_complete_force = 1
            " might be recursively called
            call s:reset(l:_db_target, a:_environment)

            call assert_true(l:_db_target._status._init_succeeded == 1,
                \ "l:_db_target._status._init_succeeded should not be 0")
            if l:_db_target._status._init_succeeded == 0
                call boot#log_silent(l:func_name . '::Error::l:_db_target._status._init_succeeded ==',
                    \ l:_db_target._status._init_succeeded, a:_environment)
            endif

            " for item in ['partial', 'complete']
            "     if s:exclusive(l:func_name, eval('l:_db_target._status._file_' . item)) != s:linked
            "         call s:reset_force(a:_environment)
            "         break
            "     endif
            " endfor

        else
            call s:file_dict_update({'func_name': l:func_name, 'result': 1, 'enter_state':
                \ deepcopy(l:_db_target._status, 1)},
                \ expand("<afile>"), a:_environment)
        endif

    endfunction

    " Section: Autocommands {{{1

    function! cscope_auto#au_install()
        let l:func_name = boot#function_name(expand('<SID>'), expand('<sfile>'))
        if s:_environment._script_develop  == 1
            call boot#log_silent("\n", "", s:_environment)
        endif
        augroup cscopedb_augroup
            au!
            au BufWritePre *.[cChH],*.[cChH]{++,xx,pp},*.inl,*.impl,*.vim
                \ call s:file_dict_update({'func_name': "BufWritePre", 'result': 1, 'enter_state':
                \ deepcopy(s:_db_target_list[boot#project(resolve(expand('#'. bufnr(). ':p:h')), s:_environment)]._status, 1)},
                \ expand("<afile>"), s:_environment)
            au BufWritePost *.[cChH],*.[cChH]{++,xx,pp},*.inl,*.impl,*.vim call s:on_bufwritepost(s:_environment)
            au FileChangedShellPost *.[cChH],*.[cChH]{++,xx,pp},*.inl,*.impl,*.vim
                \ call s:db_unify_update(s:_environment)
            " au QuickFixCmdPre,CursorHoldI,CursorHold,WinEnter,CursorMoved,CursorMovedI *
            " au QuickFixCmdPre,CursorHoldI,CursorHold *
            au QuickFixCmdPre * call s:db_tick(s:_environment)
            au BufEnter,BufWinEnter,BufNew * call s:on_bufswitch(s:_environment)
        augroup END

        if s:_environment._script_develop  == 1
            call boot#log_silent(l:func_name, "done", s:_environment)
            call boot#log_silent("\n", "", s:_environment)
        endif
    endfunction

    " 1}}}

    " Autoinit: {{{1
    " 1}}}

    " Section: Maps {{{1


    " 1}}}

endif
" has("cscope")
