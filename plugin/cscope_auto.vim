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

if ! exists("g:_cscope_auto_develop")
    let s:_cscope_auto_develop = 0
    let g:_cscope_auto_develop = 0
else
    let s:_cscope_auto_develop = g:_cscope_auto_develop
endif

if has("cscope")
    if exists("g:cscope_auto_loaded")
        finish
    endif


    " Autoinit: {{{1

    " If complete cscope DB exists then automatically init the plugin.
    " Means we launch vim from a location that we've already started using
    " the plugin from.

    " The first time cscope_auto.vim loaded, l:_db_target._status._dir_project is ""
    call cscope_auto#au_install()
    " call cscope_auto#reset_force()

    " 1}}}

    " Section: Maps {{{1

    if ! exists("g:cscope_auto_loaded")

        " noremap <unique> <Plug>CscopeInit :call <sid>init_force(<f-args>)<cr>
        if 1 == s:_cscope_auto_develop
            noremap <unique> <Plug>CG :call cscope_auto#generate()<cr>
        endif
        command! -nargs=0 CS :call cscope_auto#reset_force()

        let g:cscope_auto_loaded = 1
        call boot#log_silent("g:cscope_auto_loaded", g:cscope_auto_loaded, g:_environment)
    endif

    " 1}}}

endif    " has("cscope")



