" edit-jekyll-post.vim - Quickly create new post for Jekyll blog
" Copyright (C) Retorillo <http://github.com/retorillo/> 
" Distributed under the MIT license

" Usage:
" :EditJekyllPost {title}
" :ejek {title}

command! -nargs=1 -complete=file EditJekyllPost :call EditJekyllPost("<args>")
cabbrev editjekyllpost <c-r>=getcmdtype() == ":" ? "EditJekyllPost" : "editjekyllpost"<CR>
cabbrev ejek <c-r>=getcmdtype() == ":" ? "EditJekyllPost" : "ejek"<CR>

let g:editJekyllPost#defaultExtension = ".md" 
let g:editJekyllPost#defaultLayout = "post"
let g:editJekyllPost#postsDirectory = "_posts\\"

function! EditJekyllPost(title)
   let l:dir = ""
   if isdirectory(g:editJekyllPost#postsDirectory) == 1
      let l:dir = g:editJekyllPost#postsDirectory
   endif
   let l:fname = l:dir.strftime("%Y-%m-%d-").a:title.g:editJekyllPost#defaultExtension
   exec "e ". l:fname
   let l:empty = line(".") == 1 && line("$") == 1 && col(".") == 1
   if l:empty
      call setline(".", "---")
      call append(1, "layout: ". g:editJekyllPost#defaultLayout)
      call append(2, "title: ")
      call append(3, "---")
      call append(4, "")
      exec '3'
      call cursor(".", col("$") + 1)
   else
      exec '$'
   endif
endfunction
