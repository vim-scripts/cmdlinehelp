" cmdlinehelp.vim -- Display help on the command in the command line
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-01.
" @Last Change: 2008-07-01.
" @Revision:    0.2.153
" GetLatestVimScripts: 2279 0 cmdlinehelp.vim

" :doc:
" NOTE:
" - This plugin works be temporarily setting &l:tags. I hope but I am 
"   not sure that this doesn't interfere with anything else.

if &cp || exists("loaded_cmdlinehelp")
    finish
endif
let loaded_cmdlinehelp = 2

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:cmdlinehelpMapView')
    " Default map.
    let g:cmdlinehelpMapView = '<c-o>'  "{{{2
endif

if !exists('g:cmdlinehelpMapDown')
    let g:cmdlinehelpMapDown = '<c-pagedown>'   "{{{2
endif

if !exists('g:cmdlinehelpMapUp')
    let g:cmdlinehelpMapUp = '<c-pageup>'   "{{{2
endif

if !exists('g:cmdlinehelpIgnore')
    " Uninteresting stuff that should be ignored when searching for a command.
    let g:cmdlinehelpIgnore = 'sil\%[ent]\|verb\%[ose]' "{{{2
endif

if !exists('g:cmdlinehelpTags')
    " The tags. Defaults to standard help tags.
    let g:cmdlinehelpTags = join(split(globpath(&rtp, 'doc/tags'), '\n'), ',') "{{{2
endif

if !exists('g:cmdlinehelpTable')
    " A table of tags that should be displayed instead of the default 
    " tag. This only works for exact matches.
    " :nodefault:
    " :read: let g:cmdlinehelpTable = "{{{2
    let g:cmdlinehelpTable = {
                \ ':s': ':s_flags'
                \ }
endif


let s:buffer = ''
let s:pos = -1
let s:bufnr = -1
let s:ignore = 0


" Find help for the first "interesting" command on the current command line.
function! CmdLineHelpView() "{{{3
    let cmd = matchstr(s:buffer, '\('. g:cmdlinehelpIgnore .'\)\?\W*\s*\zs\w\+')
    if !empty(cmd)
        let cmd = ':'. cmd
        let cmd = get(g:cmdlinehelpTable, cmd, cmd)
        let tags = &l:tags
        let &tags = g:cmdlinehelpTags
        try
            exec 'ptag '. cmd
            call s:InstallAutoHide()
        finally
            let &l:tags = tags
        endtry
        redraw!
    endif
    call s:RestoreCmdLine()
endf


function! s:RestoreCmdLine() "{{{3
    call feedkeys(':'. s:buffer ."\<HOME>". repeat("\<RIGHT>", s:pos - 1))
endf


" Save the current command line.
function! CmdLineHelpBuffer() "{{{3
    let s:buffer = getcmdline()
    let s:pos = getcmdpos()
    return s:buffer
endf


function! s:InstallAutoHide() "{{{3
    autocmd CmdLineHelp CursorHold,CursorHoldI,CursorMovedI,InsertEnter * call s:CmdLineHelpClose()
endf


function! s:RemoveAutoHide() "{{{3
    autocmd! CmdLineHelp CursorHold,CursorHoldI,CursorMovedI,InsertEnter
endf


function! s:CmdLineHelpClose() "{{{3
    if !s:ignore
        pclose!
        call s:RemoveAutoHide()
    end
endf


function! CmdLineHelpDown() "{{{3
    call s:NormInPreview("\<pagedown>")
    call s:RestoreCmdLine()
endf


function! CmdLineHelpUp() "{{{3
    call s:NormInPreview("\<pageup>")
    call s:RestoreCmdLine()
endf


function! s:NormInPreview(seq) "{{{3
    let s:ignore = 1
    let wn = winnr()
    try
        windo if &previewwindow && &filetype == 'help' | exec 'norm '. a:seq | redraw | endif
    finally
        let s:ignore = 0
        exec wn.'wincmd w'
    endtry
endf


if !hasmapto('CmdLineHelpView', 'c')
    exec 'cnoremap '. g:cmdlinehelpMapView .' <c-\>eCmdLineHelpBuffer()<cr><c-c>:call CmdLineHelpView()<cr>'
end
if !hasmapto('CmdLineHelpUp', 'c')
    exec 'cnoremap '. g:cmdlinehelpMapUp .' <c-\>eCmdLineHelpBuffer()<cr><c-c>:call CmdLineHelpUp()<cr>'
end
if !hasmapto('CmdLineHelpDown', 'c')
    exec 'cnoremap '. g:cmdlinehelpMapDown .' <c-\>eCmdLineHelpBuffer()<cr><c-c>:call CmdLineHelpDown()<cr>'
end

if &cpoptions !~# 'x'
    cnoremap <esc> <c-c><c-w>z
endif
cnoremap <c-c> <c-c><c-w>z


augroup CmdLineHelp
    autocmd!
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

0.2
- g:cmdlinehelpTable
- FIX: wrong window after scrolling

