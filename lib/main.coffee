{CompositeDisposable, Directory, File} = require 'atom'
fs = require 'fs'
path = require 'path'
crypto = require "crypto"

defaultImageDir = "assets/"

module.exports = MarkdownImageAssistant =
    subscriptions: null
    config:
        suffixes:
            title: "Active file types"
            description: "File type that image assistant should activate for"
            type: 'array'
            default: ['.markdown', '.md', '.mdown', '.mkd', '.mkdow']
            items:
                type: 'string'
        preserveOrigName:
            title: "Preserve original file names"
            description: "When dragging and dropping files, whether to preserve original file names when copying over into the image directory"
            type: 'boolean'
            default: false
        prependTargetFileName:
            title: "Prepend the target file name"
            description: "Whether to prepend the target file name when copying over the image. Overrides the \"Preserve Original Name\" setting."
            type: 'boolean'
            default: true
        prependDate:
            title: "Prepend current date and time"
            description: "Whether to prepend current date in format yyyy-mm-dd-########. The date will be added after the target file name."
            type: 'boolean'
            default: true
        preserveFileNameInAssetsFolder:
            title: "Create per-file asset directories"
            description: "Creates a separate asset directory for each markdown file, e.g. `README.assets/`; setting `Image Directory` to a value other than the default of `assets/` overrides this option"
            type: 'boolean'
            default: false
        imageDir:
            title: "Image directory"
            description: "Local directory to copy images into; created if not found."
            type: 'string'
            default: defaultImageDir
        insertHtmlOverMarkdown:
            title: "Insert image as Markup, instead of Markdown"
            description: "Insert an image as HTML Markup, `<img src=''>`, instead of Markdown, `![]()`.  Useful if you want to adjust image `width` or `height`"
            type: 'boolean'
            default: false

    activate: (state) ->
        # Events subscribed to in atom's system can be easily cleaned up
        # with a CompositeDisposable
        @subscriptions = new CompositeDisposable

        # Register handler for drag 'n drop events
        @subscriptions.add atom.workspace.observeTextEditors (editor) => @handle_subscription(editor)
        # Register handler for copy and paste events
        @subscriptions.add atom.commands.onWillDispatch (e) =>
            if event? and event.type == 'core:paste'
                editor = atom.workspace.getActiveTextEditor()
                return unless editor
                @handle_cp(e)

    handle_subscription: (editor) ->
        textEditorElement = atom.views.getView editor
        # on drag and drop event
        textEditorElement.addEventListener "drop", (e) => @handle_dropped(e)

    # triggered in response to dragged and dropped files
    handle_dropped: (e) ->
        e.preventDefault?()
        e.stopPropagation?()
        editor = atom.workspace.getActiveTextEditor()
        return unless editor

        dropped_files = e.dataTransfer.files

        for f in dropped_files
            if fs.lstatSync(f.path).isFile()
                imgbuffer = new Buffer(fs.readFileSync(f.path))
                extname = path.extname(String(f.path))
                if atom.config.get('markdown-image-assistant.preserveOrigName')
                    origname = path.basename(f.path, extname)
                else
                    origname = ""
                @process_file(editor, imgbuffer, extname, origname)

    # triggered in response to a copy pasted image
    handle_cp: (e) ->
        clipboard = require 'clipboard'
        img = clipboard.readImage()
        return if img.isEmpty()
        editor = atom.workspace.getActiveTextEditor()
        e.stopImmediatePropagation()
        if Number process.versions.electron[0] >= 2
          imgbuffer = img.toPNG()
        else
          imgbuffer = img.toPng()
        @process_file(editor, imgbuffer, ".png", "")

    # write a given buffer to the local "assets/" directory
    process_file: (editor, imgbuffer, extname, origname) ->
        target_file = editor.getPath()

        if path.extname(target_file) not in atom.config.get('markdown-image-assistant.suffixes')
            console.log "Adding images to non-markdown files is not supported"
            return false

        if atom.config.get('markdown-image-assistant.imageDir') == defaultImageDir && atom.config.get('markdown-image-assistant.preserveFileNameInAssetsFolder')
            assets_dir = path.basename(path.parse(target_file).name + "." + atom.config.get('markdown-image-assistant.imageDir'))
        else
            assets_dir = path.basename(atom.config.get('markdown-image-assistant.imageDir'))
        assets_path = path.join(target_file, "..", assets_dir)

        if origname != ""
          img_filename = "#{origname}#{extname}"
        else
          md5 = crypto.createHash 'md5'
          md5.update(imgbuffer)
          if atom.config.get('markdown-image-assistant.prependDate') # shorten cash if we prepend datetime
            img_filename = "#{md5.digest('hex').slice(0,3)}#{extname}"
          else
            img_filename = "#{md5.digest('hex').slice(0,8)}#{extname}"

        # Prepend date
        if atom.config.get('markdown-image-assistant.prependDate')
            today = new Date
            dd = today.getDate()
            #The value returned by getMonth is an integer between 0 and 11, referring 0 to January, 1 to February, and so on.
            mm = today.getMonth() + 1
            yyyy = today.getFullYear()
            # Format fix
            if dd < 10
              dd = '0' + dd
            if mm < 10
              mm = '0' + mm
            # Time
            hh = today.getHours()
            mins = today.getMinutes()
            secs = today.getSeconds()
            msecs = today.getMilliseconds()
            if hh < 10
              hh = '0' + hh
            if mins < 10
              mins = '0' + mins
            if secs < 10
              secs = '0' + secs
            if msecs < 10
              msecs = '0' + msecs
            
            today = yyyy + '-' + mm + '-' + dd  + '-' + hh + mins + secs + msecs + '-'
        else
           today = ''

        img_filename = today + img_filename

        if atom.config.get('markdown-image-assistant.prependTargetFileName')
            target_file_name = path.parse(target_file).name + '-'
        else
            target_file_name = ''
        img_filename = target_file_name + img_filename

        console.log img_filename

        @create_dir assets_path, ()=>
            fs.writeFile path.join(assets_path, img_filename), imgbuffer, 'binary', ()=>
                console.log "Copied file over to #{assets_path}"
                if atom.config.get('markdown-image-assistant.insertHtmlOverMarkdown')
                  editor.insertText "<img alt=\"#{img_filename}\" src=\"#{assets_dir}/#{img_filename}\" width=\"\" height=\"\" >"
                else
                  editor.insertText "![](#{assets_dir}/#{img_filename})"

        return false

    create_dir: (dir_path, callback)=>
        dir_handle = new Directory(dir_path)

        dir_handle.exists().then (existed) =>
            if not existed
                dir_handle.create().then (created) =>
                    if created
                        console.log "Successfully created #{dir_path}"
                        callback()
            else
                callback()

    deactivate: ->
        @subscriptions.dispose()
