# [atom-markdown-image-assistant](https://atom.io/packages/markdown-image-assistant)

Add sane drag and drop and copy/paste support for images to markdown
files. This is especially useful for notetaking in Atom.

Whenever an image is dragged and dropped or copy and pasted on an open
markdown file, this package automatically copies it to the folder `<fileroot>.assets/`
in the current directory, renames the image, and inserts a relative link
to the image.   

`<fileroot>` is the root of the file without the supported Markdown extensions (`.markdown`, `.md`, `.mdown`, `.mkd`, `.mkdow`).

![](README.assets/README-54317719.png)

-----

![](https://cloud.githubusercontent.com/assets/1661487/19503385/137f1da6-9568-11e6-9796-910e6927459d.gif)

## Installation

This plugin can be installed via Atom's GUI or via the command line:

```
apm install markdown-image-assistant
```
