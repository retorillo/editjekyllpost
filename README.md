# Jekyll-Util.vim

[![MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Jekyll utilities for vimmer. Works on Windows, MSYS2, Linux, and Mac!

I'm happy if it can helps yo from boring works. (enter to `_posts` directory,
type ISO date-formatted file name, and so on)

**I renamed this plugin name from `editjekyllpost.vim` to `jekyll-util.vim`.**i

- [Install](#install_pathogen)
- [Commands](#commands)
   - [JekyllConf](#jekyllconf)
   - [JekyllEdit](#jekylledit)
- [Where is JekyllRename?](#where_is_jekyllrename)
- [Configuration](#configuration)
- [License](#lisence)


## Install (Pathogen)

```bash
git clone https://github.com/retorillo/jekyll-util.vim.git ~/.vim/bundle/jekyll-util.vim
```

## Commands

### JekyllConf

Open configuration file of this plugin `~/.jekyllutil`

```vimL
:JekyllConf
```

First, set your blog name and local path as follow and save this.

```ini
[blog1]
root=~/your/blog1/
```

In this case, blog name is `blog1` and path is `~/your/blog1`.
Now you can use [JekyllEdit](#jekylledit) command!

Of course, for advanced user, there are more options can be configured.

| Key       | Description                             | DefaultValue | Required |
|-----------|-----------------------------------------|--------------|----------|
| root      | Specify root directory of jekyll blog   |              | yes      |
| posts     | Set to change _posts directory path     | _posts       |          |
| extension | Set to change default extension of post | .md          |          |
| layout    | Set to change default layout of post    | post         |          |

```ini
[blog1]
root=~/your/blog1/
posts=_posts
extension=.markdown
layout=blogpost

[blog2]
root=~/your/blog2/
; Comment starts with semicolon
; ...
```

### JekyllEdit

Create or amend post more quickly. (including past and feature posts)

```vim
:JekyllEdit name [ [ dayoffset ] title ]
```

- Specify `name` for blog name defined in `~/.jekyllutil`. See
  [JekyllConf](#jekyllconf)
   - Tab autocompletion is available if `~/.jekyllutil` is correctly configured.
- Specify `dayoffset` for past or future post. For example, when specified `-1`,
  creates or amend blog post as yesterday's. This is optinal argument. Skip this
  to create or amend post as today's.
- Specify `title` for title of this post. This is not `title` of front
  matter(YML), but is used for filename.(ex. `2016-04-24-title-is-here.md`)
   - Tab autocompletion is available if there are post files of that day, or comes
     from `jekyllUtil#defaultTitles`
- When both `title` and `dayoffset` arguments are omitted, just browses `_posts`
  directory(`netrw`).

If today is 18 March 2016, `:JekyllEdit blog1 2 new-post-title` will try to
create or open `~/your/blog1/_posts/2016-03-20-new-post-title.md`.

`jeke` is an abbrev for `JekyllEdit`. Type `:jeke` and whitespace, then
it will be automatically replaced by `:JekyllEdit `.

## Configuration

By changing the following variables, you can overwrite default values of this plugin.

Blog specific configuration is defined in `~/.jekyllutil`. See
[JekyllConf](#jekyllconf).

```vim
" Change to ~/.jekyllutil path
let g:jekyllUtil#configFile = "~/.jekyllutil"
" To change extension of posts. Must starts with dot.
" This value will be overwritten by ~/.jekyllutil
let g:jekyllUtil#defaultExtension = ".md" 
" To change name of layout on automatically generated YML front matter
" This value will be overwritten by ~/.jekyllutil
let g:jekyllUtil#defaultLayout = "post"
" To change _posts directory.
" This value will be overwritten by ~/.jekyllutil
let g:jekyllUtil#postsDirectory = "_posts"
" Titles that be used for completion when there are no post of that day
" Specify [] to suspend this feature
let g:jekyllUtil#defaultTitles = ['untitled', 'todo-list']
```

## License

Distributed under the MIT license

Copyright (C) 2016 Retorillo
