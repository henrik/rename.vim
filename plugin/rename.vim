" rename.vim  -  Rename a buffer within Vim and on the disk
"
" Copyright June 2007 by Christian J. Robinson <infynity@onewest.net>
" Updated August 2011 by Dan Rogers <dan@danro.net>
" Updated February 2012 with fixes by Andrew Raw (http://andrewray.me),
" added by Henrik Nyh (http://henrik.nyh.se).
"
" Distributed under the terms of the Vim license.  See ":help license".
"
" Usage:
"
" :Rename[!] {newname}

command! -nargs=* -complete=file -bang Rename call Rename(<q-args>, '<bang>')

function! Rename(name, bang)
    if a:name =~ "!$"
      let l:name = substitute(a:name, "!$", "", "")
      let l:bang = 1
    else
      let l:name = a:name
      let l:bang = (a:bang == '!')
    endif

    " Attempt be smart, if the new file name has a slash in it, don't assume
    " current directory
    if matchstr(a:name, "/") == "/"
        let l:name = l:name
    else
        let l:name = expand("%:h") . "/" . l:name
    endif

    let l:oldfile = expand('%:p')

    " Replace buffer with same name if bang was given.
    if bufexists(fnamemodify(l:name, ':p'))
        if l:bang
            silent exe bufnr(fnamemodify(l:name, ':p')) . 'bwipe!'
        else
            echohl ErrorMsg
            echomsg 'A buffer with that name already exists (use ! to override).'
            echohl None
            return 0
        endif
    endif

    " Create missing directory if bang was given.
    let l:dir = fnamemodify(l:name, ":p:h")
    if !isdirectory(l:dir)
      if l:bang
        call mkdir(l:dir, "p")
      else
        echohl ErrorMsg
        echomsg 'The directory does not exist (use ! to create).'
        echohl None
        return 0
      endif
    endif

    let l:status = 1

    let v:errmsg = ''
    silent! exe 'saveas' . (l:bang ? '!' : '') . ' ' . l:name
    filetype detect

    if v:errmsg =~# '^$\|^E329'
        let l:lastbufnr = bufnr('$')

        if expand('%:p') !=# l:oldfile && filewritable(expand('%:p'))
            if fnamemodify(bufname(l:lastbufnr), ':p') ==# l:oldfile
                silent exe l:lastbufnr . 'bwipe!'
            else
                echohl ErrorMsg
                echomsg 'Could not wipe out the old buffer for some reason.'
                echohl None
                let l:status = 0
            endif

            if delete(l:oldfile) != 0
                echohl ErrorMsg
                echomsg 'Could not delete the old file: ' . l:oldfile
                echohl None
                let l:status = 0
            endif
        else
            echohl ErrorMsg
            echomsg 'Rename failed for some reason.'
            echohl None
            let l:status = 0
        endif
    else
        echoerr v:errmsg
        let l:status = 0
    endif

    return l:status
endfunction
