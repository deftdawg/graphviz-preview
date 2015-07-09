# {WorkspaceView} = require 'atom'
GraphvizPreview = require '../lib/graphviz-preview'
{$} = require 'atom-space-pen-views'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "GraphvizPreview", ->
  activationPromise = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)
    activationPromise = atom.packages.activatePackage('graphviz-preview')
    waitsForPromise ->
      atom.workspace.open 'test.dot'

  describe "when the graphviz-preview:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      expect(editor.getPath()).toContain 'test.dot'
      expect(workspaceElement.querySelector('.graphviz-preview')).toBeNull

      editor.insertText("graph {a -- b;b -- c;a -- c;d -- c;e -- c;e -- a;} ");

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch(editorElement, 'graphviz-preview:toggle')

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.graphviz-preview')).not.toBeNull
        atom.commands.dispatch(editorElement, 'graphviz-preview:toggle')
        expect(workspaceElement.querySelector('.graphviz-preview')).toBeNull
