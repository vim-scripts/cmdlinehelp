" cmdlinehelp.vim -- Display help on the command in the command line
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-01.
" @Last Change: 2008-07-09.
" @Revision:    340
" GetLatestVimScripts: 2279 0 cmdlinehelp.vim

" :doc:
" NOTE:
" - This plugin temporarily sets &l:tags to g:cmdlinehelpTags. I hope 
"   this doesn't interfere with anything else.

if &cp || exists("loaded_cmdlinehelp")
    finish
endif
let loaded_cmdlinehelp = 5

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:cmdlinehelpMapView')
    " Default map.
    let g:cmdlinehelpMapView = '<c-o>'  "{{{2
    " let g:cmdlinehelpMapView = '<c-]>'  "{{{2
endif

if !exists('g:cmdlinehelpMapDown')
    let g:cmdlinehelpMapDown = '<c-pagedown>'   "{{{2
endif

if !exists('g:cmdlinehelpMapUp')
    let g:cmdlinehelpMapUp = '<c-pageup>'   "{{{2
endif

if !exists('g:cmdlinehelpIgnore')
    " Uninteresting stuff that should be ignored when searching for a command.
    let g:cmdlinehelpIgnore = 'sil\%[ent]\|verb\%[ose]\|debug' "{{{2
endif

if !exists('g:cmdlinehelpPatterns')
    " A dictionary of line patters for extracting the tag from the 
    " command line and format strings for formatting the tag. This is 
    " used for, e.g., the |:set| command to show help on the option but 
    " not on the command.
    " :nodefault:
    " :read: let g:cmdlinehelpPatterns = {}   "{{{2
    let g:cmdlinehelpPatterns = {
                \ 'set\?\s\+\zs\w\+': "'%s'",
                \ 'setl\%[ocal]\s\+\zs\w\+': "'%s'",
                \ 'let\s\+&l:\zs[^=[:space:]]\+': "'%s'",
                \ 'let\s\+&\zs[^=[:space:]]\+': "'%s'",
                \ 'let\s\+\zs[^=[:space:]]\+': "%s",
                \ 'call\s\+\zs[^([:space:]]\+': "%s()",
                \ 'echo\(m\%[sg]\)\?\s\+\zs[^([:space:]]\+': "%s()",
                \ }
endif

if !exists('g:cmdlinehelpTags')
    " The tags. Defaults to standard help tags.
    let g:cmdlinehelpTags = join(split(globpath(&rtp, 'doc/tags'), '\n'), ',') "{{{2
endif

if !exists('g:cmdlinehelpTable')
    " A table of tags (regexps to be precise) and replacement tags that 
    " should be displayed instead of the default tag.
    "
    " If the replacement starts with an asterisk, it is considered a 
    " function name that will be called with 3 arguments  
    " (commandline, cursor-pos, tag) and should return an array 
    " [new commandline, new cursor-pos].
    " :nodefault:
    " :read: let g:cmdlinehelpTable = {} "{{{2
    let g:cmdlinehelpTable = {
                \ ':s\%[ubstitute]': ':s_flags',
                \ ':tag\?!': 'tag-!',
                \ ':Align': 'alignman',
                \ ':AlignCtrl': 'alignman',
                \ }
endif

if !exists('g:cmdlinehelpPrefixes')
    " If a tag with one of these prefixes is found, it will be used 
    " instead of the default one. This should make it quite easy to use 
    " nicely formatted cheat sheets without interfering with normal vim 
    " help. Simply save your cheat sheet to ~/vimfiles/doc/, tag the 
    " entries with a prefix (e.g. "cheat::edit" for ":edit") and run 
    " |:helptags|.
    let g:cmdlinehelpPrefixes = ['cheat:']  "{{{2
endif


let s:buffer = ''
let s:pos = -1
let s:bufnr = -1
let s:ignore = 0


" Find help for the first "interesting" command on the current command line.
function! CmdLineHelpView() "{{{3
    " call TLogDBG(s:buffer)
    let ok = 0
    for [cpat, fmt] in items(g:cmdlinehelpPatterns)
        let tag = matchstr(s:buffer, '\(\('. g:cmdlinehelpIgnore .'\)\W*\s*\)*'. cpat)
        " TLogVAR tag, cpat, fmt
        if !empty(tag)
            let ok = 1
            break
        endif
    endfor
    if !ok
        let tag = matchstr(s:buffer, '\(\('. g:cmdlinehelpIgnore .'\)\W*\s*\)*\zs\w\+!\?')
        let fmt = ':%s'
    endif
    " TLogVAR tag, fmt

    if !empty(tag)
        let tags = &l:tags
        let &tags = g:cmdlinehelpTags
        try
            let tag = printf(fmt, tag)
            let tag1 = s:PrefixTag(tag)
            " TLogVAR tag1
            if empty(tag1) && !s:TagExists(tag)
                if tag[-1 : -1] == '!'
                    let tagm = tag[0 : -2]
                    let tag1 = s:PrefixTag(tagm)
                    " TLogVAR tag1
                    if empty(tag1)
                        let tag1 = s:TableGet(tag, '')
                        " TLogVAR tag1
                        if empty(tag1)
                            if s:TagExists(tagm)
                                let tag1 = tagm
                            else
                                let tag1 = s:TableGet(tagm, '')
                            endif
                            " TLogVAR tag1
                        endif
                    endif
                endif
            endif
            " TLogVAR tag, tag1
            let tag0 = tag
            if !empty(tag1)
                let tag = s:TableGet(tag1, tag1)
            else
                let tag = s:TableGet(tag, tag)
            endif
            if tag[0:0] == '*'
                let [s:buffer, s:pos] = call(tag[1 : -1], [s:buffer, s:pos, tag0])
            else
                exec 'silent ptag '. tag
            endif
            " call s:NormInPreview("jzt")
            call s:NormInPreview("zt")
            call s:InstallAutoHide()
        catch /^Vim\%((\a\+)\)\=:E426/
        finally
            let &l:tags = tags
        endtry
        redraw!
    endif
    call s:RestoreCmdLine()
endf


function! s:TableGet(tag, default) "{{{3
    " TLogVAR a:tag, a:default
    for [tag, repl] in items(g:cmdlinehelpTable)
        if a:tag =~ '^'. tag .'$'
            " TLogVAR tag, repl
            return repl
        endif
    endfor
    return a:default
endf


function! s:PrefixTag(tag) "{{{3
    for prefix in g:cmdlinehelpPrefixes
        let tag1 = prefix . a:tag
        if s:TagExists(tag1)
            return tag1
            break
        endif
    endfor
    return ''
endf


function! s:TagExists(tag) "{{{3
    let taglist = taglist('\V\^'. a:tag .'\$')
    return !empty(taglist)
endf


function! s:RestoreCmdLine() "{{{3
    call feedkeys(':'. s:buffer ."\<Home>". repeat("\<Right>", s:pos - 1))
endf


" Save the current command line.
function! CmdLineHelpBuffer() "{{{3
    let s:buffer = getcmdline()
    let s:pos = getcmdpos()
    return s:buffer
endf


function! s:InstallAutoHide() "{{{3
    autocmd CmdLineHelp CursorHold,CursorHoldI,CursorMovedI,InsertEnter,BufWinEnter * call s:CmdLineHelpClose()
endf


function! s:RemoveAutoHide() "{{{3
    autocmd! CmdLineHelp CursorHold,CursorHoldI,CursorMovedI,InsertEnter,BufWinEnter
endf


function! s:CmdLineHelpClose() "{{{3
    if !s:ignore && !&previewwindow
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
    exec 'cnoremap <silent> '. g:cmdlinehelpMapView .' <c-\>eCmdLineHelpBuffer()<cr><c-c>:call CmdLineHelpView()<cr>'
end
if !hasmapto('CmdLineHelpUp', 'c')
    exec 'cnoremap <silent> '. g:cmdlinehelpMapUp .' <c-\>eCmdLineHelpBuffer()<cr><c-c>:call CmdLineHelpUp()<cr>'
end
if !hasmapto('CmdLineHelpDown', 'c')
    exec 'cnoremap <silent> '. g:cmdlinehelpMapDown .' <c-\>eCmdLineHelpBuffer()<cr><c-c>:call CmdLineHelpDown()<cr>'
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

0.3
- Preferred prefixes: g:cmdlinehelpPrefixes
- Display the help on the top of the preview window

0.4
- For :set, :setlocal, :let show help on the option/variable, not the command
- Catch e426 error.
- Added debug to g:cmdlinehelpIgnore

0.5
- Support an optional command bang [!]
- For :call, :echo[m] show help on the function not the command
- g:cmdlinehelpTable may contain references to custom helper function
- The keys in g:cmdlinehelpTable are regexps
- Don't scroll down one line

