url = require 'url'

GraphvizPreviewView = require './graphviz-preview-view'

{$, $$$, ScrollView} = require 'atom'

module.exports =
  graphvizPreviewView: null

  activate: (state) ->
    atom.workspaceView.command 'graphviz-preview:toggle', =>
      @toggle()

    atom.workspace.registerOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'html-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        new GraphvizPreviewView(editorId: pathname.substring(1))
      else
        new GraphvizPreviewView(filePath: pathname)

  toggle: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?

    uri = "html-preview://editor/#{editor.id}"

    previewPane = atom.workspace.paneForUri(uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForUri(uri))
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (graphvizPreviewView) ->
      if graphvizPreviewView instanceof GraphvizPreviewView
        graphvizPreviewView.renderHTML()
        previousActivePane.activate()
