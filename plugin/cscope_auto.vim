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


"
" Vim Plugin to automatically update cscope when a buffer has been written.
"
if has("cscope")
    if exists("g:cscope_auto_loaded")
        finish
    endif

    if ! exists("g:_cscope_out_debug")
        let s:_cscope_out_debug  = 0
    else
        let s:_cscope_out_debug = g:_cscope_out_debug
    endif

    " Autoinit: {{{1
    " " If big cscope DB exists then automatically init the plugin.
    " " Means we launch vim from a location that we've already started using
    " " the plugin from.
    " if s:auto_init
    "     " if filereadable(expand(s:big_file))
    "     if 0 == s:_init_succeeded
    "         call s:init(s:_status, s:_lock_file, g:file_extensions, g:_environment)
    "     endif
    "     if 1 == s:_cscope_out_debug
    "         if 0 == s:_init_succeeded
    "             call s:generate( s:_status, g:file_extensions, g:_environment)
    "         endif
    "     endif
    " endif

    " if 1 == s:_cscope_out_debug
    "     augroup cscopedb_auto
    "         au!
    "         " au QuickFixCmdPre,CursorHoldI,CursorHold,WinEnter,CursorMoved *
    "         au QuickFixCmdPre,CursorHoldI,CursorHold,WinEnter *
    "                     \ if 0 == s:_init_succeeded |
    "                     \ call s:generate( s:_status, g:file_extensions, g:_environment) |
    "                     \ endif
    "     augroup END
    " endif

    augroup cscope_auto_force
        au!
        autocmd VimEnter * exec 'normal \<Plugin>CscopeDBInit'
    augroup END
    " 1}}}

    " Section: Maps {{{1
    " if ! exists("g:cscope_auto_loaded")
    " Script scope variables won't work, ignore this design
    " noremap <unique> <Plug>CscopeDBInit :call <SID>init_force(s:_status, g:file_extensions, g:_environment)<CR>
    " " noremap <unique> <Plug>CscopeDBInit :call <SID>generate(s:_status, g:file_extensions, g:_environment)<CR>
    " let g:cscope_auto_loaded = 1
    " call boot#log_silent("g:cscope_auto_loaded::plugin", g:cscope_auto_loaded, g:_environment)
    " endif
    " 1}}}
endif    " has("cscope")



