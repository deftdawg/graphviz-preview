path = require 'path'
{CompositeDisposable, Disposable} = require 'atom'
{$, $$$, ScrollView}  = require 'atom-space-pen-views'
# _ = require 'underscore-plus'

module.exports =
class GraphvizPreviewView extends ScrollView
  atom.deserializers.add(this)

  editorSub           : null


  @deserialize: (state) ->
    new GraphvizPreviewView(state)

  @content: ->
    @div class: 'graphviz-preview native-key-bindings', tabindex: -1

  constructor: ({@editorId, filePath}) ->
    super

    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(filePath)
      else
        atom.packages.onDidActivatePackage =>
          @subscribeToFilePath(filePath)

  serialize: ->
    deserializer: 'GraphvizPreviewView'
    filePath: @getPath()
    editorId: @editorId

  destroy: ->
    @editorSub.dispose()

  subscribeToFilePath: (filePath) ->
    @trigger 'title-changed'
    @handleEvents()
    @renderHTML()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @trigger 'title-changed' if @editor?
        @handleEvents()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        atom.workspace?.paneForItem(this)?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      atom.packages.onDidActivatePackage =>
        resolve()
        @renderHTML()

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: =>

    changeHandler = =>
      @renderHTML()
      pane = atom.workspace.paneForURI(@getURI())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    @editorSub = new CompositeDisposable

    if @editor?
      @editorSub.add @editor.onDidSave changeHandler
      @editorSub.add @editor.onDidChangePath => @trigger 'title-changed'

  renderHTML: ->
    @showLoading()
    if @editor?
      @renderHTMLCode(@editor)

  renderHTMLCode: (editor) ->
    text = @editor.getText();
    text = """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>Dot Preview</title>
        <style>
          body {
            font-family: "Helvetica Neue", Helvetica, sans-serif;
            font-size: 14px;
            /* line-height: 1.6; */
            background-color: #fff;
            overflow: scroll;
            box-sizing: border-box;
          }
          .dot-syntax-error {
            color: red;
            font-weight: bold;
            font-size: larger;
          }
        </style>
        <!-- Viz.js by mdaines from https://github.com/mdaines/viz.js -->
        <script src="atom://graphviz-preview/assets/viz.js"></script>
        <script>
          function src(id) {
            return document.getElementById(id).innerHTML;
          }
          function plotGraphviz(dot) {
            if (dot.trim() != "") { // Empty buffer
              oldConsoleLog = console.log;
              lastConsoleMessage = "";
              window['console']['log'] = function (msg) {
                  if (msg && msg.indexOf("line") > -1) {
                    lastConsoleMessage = msg.replace(/(\\d+)/g, function(a,n){ return "<b>" + (n-1) + "</b>"; });
                  }
              }
              try {
                document.getElementById('rendered-graph').innerHTML = Viz(dot, 'svg');
                var renderedSVG = document.getElementById('rendered-graph').getElementsByTagName('svg')[0];
                renderedSVG.onclick = shrinkSVGToFit;
              } catch (err) {
                document.getElementById('rendered-graph').innerHTML = "<div class='dot-syntax-error'>Dot syntax error</div>"
                  + lastConsoleMessage
                  + "<div style='text-align: center; width: 100%; position:absolute; bottom:0;'>"
                   + "<b>Need GraphViz Help?</b> Try the docs: "
                   + "<a href='http://www.graphviz.org/Documentation.php'>GraphViz Documentation</a></div>";
                   + " -- <a href='http://www.graphviz.org/pdf/dotguide.pdf' target='_blank'>DOT Guide</a>"
                   + " -- <a href='http://www.graphviz.org/pdf/neatoguide.pdf'>Neato Guide</a>"
                if (lastConsoleMessage && lastConsoleMessage.indexOf("line") > -1) {
                  document.getElementById('error-line').innerText = lastConsoleMessage.match(/(\\d+)/)[0];
                }
              }
              window['console']['log'] = oldConsoleLog;
            } else {
              sampleGraph1 = 'digraph g {\\n Hello->World\\n Hello->Atom\\n}';
              sampleGraph2 = 'digraph g {\\n rankdir=LR; graph[label=\\"Example Title\\",labelloc=t, labeljust=l, size="3.5"]\\n node [fontsize=10, shape=record]\\n H[label=\\"Hello!\\", shape=circle, color=green]\\n H->World\\n Atom->Rocks\\n H->Atom\\n The->World->Cup->Rocks[style=dashed]\\n {rank=same; H Atom World }\\n}';

              document.getElementById('rendered-graph').innerHTML = "<h1>Empty Editor</h1>"
               + "<p>This preview panel will show the output of <a href='http://en.wikipedia.org/wiki/DOT_(graph_description_language)'>DOT language</a> "
               + " editor buffers the same way <a href='http://www.graphviz.org/'>GraphViz</a> would. </p>"
               + "<p>It's possible to make some pretty amazing graphs using DOT+GraphViz - check out the <a href='http://www.graphviz.org/Gallery.php'>Graphiz Gallery</a> for some examples.</p>"
               + "<p>GraphViz lays each node out automatically.  You can also feed it parameters to change how it renders.</p>"
               + "<p>Here's a very simple Hello World example (Copy the code into the buffer to make this preview update):</p>"
               + "<div><textarea cols='30' rows='10'>"+sampleGraph1+"</textarea>"
               + Viz(sampleGraph1, 'svg')
               + "</div>"
               + "<p>Here is a slightly more complicated version of the same graph with some addtional rendering parameters:</p>"
               + "<div><textarea cols='30' rows='14'>"+sampleGraph2+"</textarea>"
               + Viz(sampleGraph2, 'svg')
               + "</div>"
               + "<p>Once you begin editing, clicking on a graph will shrink it to fit or zoom back to full size if previously shrunken.";
            }
          }

          function debug_line(message) {
            document.getElementById('debug-line').value = message + "\\n" + document.getElementById('debug-line').value ;
          }

          shrinkToFit = false;
          function shrinkSVGToFit() {
            var renderedSVG = document.getElementById('rendered-graph').getElementsByTagName('svg')[0];
            switch (shrinkToFit) {
              case true:
                shrinkToFit = false;
                renderedSVG.style.webkitTransform = "scale(1.0)";
                break;

              default:
                shrinkToFit = true;

                // Get width/height of document view and rendered SVG image
                vch = document.documentElement.clientHeight;
                vcw = document.documentElement.clientWidth;
                sch = renderedSVG.clientHeight;
                scw = renderedSVG.clientWidth;

                debug_line("vch: " + vch +" vcw: " + vcw + " sch: " + sch + " scw: " + scw);

                // Find which SVG dimension exceeds the bounds of the document view, use that to set new scale
                if (sch > vch) {
                  nsch = Math.trunc(100 * vch / sch);
                } else {
                  nsch = null;
                }
                if (scw > vcw) {
                  nscw = Math.trunc(100 * vcw / scw);
                } else {
                  nscw = null;
                }
                debug_line("nsch: " + nsch + " nscw: " + nscw);

                // Set the new scale (ns) value to null
                ns = null;
                // If we have a new height or a new width we determine which is the smallest to fit the whole picture.
                if (nsch != null || nscw != null) {
                    ns = (nsch != null && (nscw == null || nsch < nscw) ? nsch : nscw);
                    scw = renderedSVG.clientWidth;
                    sch = renderedSVG.clientHeight;
                    nscw = (ns*scw)/100;
                    nsch = (ns*sch)/100;
                    // FIXME: The offset values are a bit off, please send patches/pulls if you have better ones
                    // https://github.com/jumpkick/graphviz-preview/issues/3
                    Yoffset = (sch - nsch) / 2;
                    YoffsetP = (Yoffset*100/vch);
                    Xoffset = (scw - nscw) / 2;
                    XoffsetP = (Xoffset*100/vcw);
                    debug_line("Yoffset: " + Yoffset + " YoffsetP as %: " + YoffsetP);
                    debug_line("ns: " + ns + " nscw: " + nscw + " scw: " + scw + " nsch: " + nsch + " sch: " + sch);
                }
                // If we have a new scale percentage value, apply it to the SVG and reposition the SVG to the top
                if (ns != null) {
                  renderedSVG.style.webkitTransform = "scale(" + ((ns-2) / 100) + ") translate(-"+XoffsetP+"%, -"+YoffsetP+"%)";
                  debug_line("wkt xXy: " + renderedSVG.style.webkitTransform);
                }
            }
          }
        </script>
        </head>
      <body onload="plotGraphviz(src('preview-render'));">
        <textarea id="debug-line" style="position: fixed; top: 1em; right: 1em; z-index: 100; width:40%; visibility: hidden;" rows=10></textarea>
        <script type="text/vnd.graphviz" id="preview-render">
        #{text}
        </script>
        <div id="rendered-graph"></div>
        <div id="error-line" style="visibility: hidden;"></div>
      </body>
    </html>
    """
    iframe = document.createElement("iframe")
    iframe.src = "data:text/html;charset=utf-8,#{encodeURI(text)}"
    @html $ iframe
    # TODO: jump to error line in the editor
    # somehow get rendered HTML from iframe body and extract out error line number
    # if (iframe.innerText)
    # row = extact error line
    # @editor.setCursorBufferPosition([row,Infinity])

    @trigger('graphviz-preview:html-changed')

  getTitle: ->
    if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "HTML Preview"

  getURI: ->
    "html-preview://editor/#{@editorId}"

  getPath: ->
    if @editor?
      @editor.getPath()

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing DOT Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @html $$$ ->
      @div class: 'graphviz-spinner', 'Loading DOT Preview\u2026'
