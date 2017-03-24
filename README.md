# [atom-markdown-image-assistant](https://atom.io/packages/markdown-image-assistant)

Add sane drag and drop and copy/paste support for images to markdown
files. This is especially useful for notetaking in Atom.

![](https://cloud.githubusercontent.com/assets/1661487/19503385/137f1da6-9568-11e6-9796-910e6927459d.gif)

## Atom Settings

These settings can be accessed under Settings -> Packages -> Markdown
Image Assistant.

### Default Settings

Whenever an image is dragged and dropped or copy and pasted on an open markdown file, this package automatically copies it to an `assets/` folder in the current directory, renames the image, and inserts a relative link to the image.

### Active file types

File type that image assistant should activate for

### Image directory

Default image directory

### Preserve original file names

When dragging and dropping files, whether to preserve original file names when copying over into the image directory

### Use the Markdown filename

Creates an asset folder in the form of `<fileroot>.assets/`.  Where
`<fileroot>` is the root of the file without the supported Markdown extensions (`.markdown`, `.md`, `.mdown`, `.mkd`, `.mkdow`).


### Insert image as Markup, instead of Markdown

Insert an image as HTML Markup, `<img src=''>`, instead of Markdown, `![]()`.  Useful if you want to adjust image `width` or `height`

-----


## Installation

This plugin can be installed via Atom's GUI or via the command line:

```
apm install markdown-image-assistant
```


### Demo
* My Cat folder name
```
![](CAT-assets/README-684b45a8.jpg)
```

* Markup
```
<img alt="README-684b45a8.jpg" src="assets/README-684b45a8.jpg" width="" height="" >
```
* Per-file asset directory
```
![](README.assets/README-684b45a8.jpg)
```

* Preserve Original filename
```
![](README.assets/README-Fort-*ssHole.jpg)
```

-----
![atom-image-assistant](https://cloud.githubusercontent.com/assets/118112/24306827/2db2494a-107f-11e7-969a-2581851aa816.gif)
