{WorkspaceView} = require 'atom'
GraphvizPreview = require '../lib/graphviz-preview'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "GraphvizPreview", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('graphviz-preview')

  describe "when the graphviz-preview:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.graphviz-preview')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'graphviz-preview:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.graphviz-preview')).toExist()
        atom.workspaceView.trigger 'graphviz-preview:toggle'
        expect(atom.workspaceView.find('.graphviz-preview')).not.toExist()
