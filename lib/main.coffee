{CompositeDisposable, Directory, File} = require 'atom'
fs = require 'fs'
path = require 'path'
crypto = require "crypto"

module.exports = MarkdownImageAssistant =
    subscriptions: null
    config:
        suffixes:
            type: 'array'
            default: ['.markdown', '.md', '.mdown', '.mkd', '.mkdow']
            items:
                type: 'string'

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
                @process_file(editor, imgbuffer, path.extname(f.path))

    # triggered in response to a copy pasted image
    handle_cp: (e) ->
        clipboard = require 'clipboard'
        img = clipboard.readImage()
        return if img.isEmpty()
        editor = atom.workspace.getActiveTextEditor()
        e.stopImmediatePropagation()
        imgbuffer = img.toPng()
        file = new File(editor.getPath())
        @process_file(editor, imgbuffer, ".png")

    # write a given buffer to the local "assets/" directory
    process_file: (editor, imgbuffer, extname) ->
        target_file = editor.getPath()

        if path.extname(target_file) not in atom.config.get('markdown-image-assistant.suffixes')
            console.log "Adding images to non-markdown files is not supported"
            return false

        assets_path = path.join(target_file, "..", "assets")

        md5 = crypto.createHash 'md5'
        md5.update(imgbuffer)

        img_filename = "#{path.parse(target_file).name}-#{md5.digest('hex').slice(0,8)}#{extname}"
        console.log img_filename

        @create_dir assets_path, ()=>
            fs.writeFile path.join(assets_path, img_filename), imgbuffer, 'binary', ()=>
                console.log "Copied file over to #{assets_path}"
                editor.insertText "![](#{path.join("assets", img_filename)})"

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
