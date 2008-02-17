# rdot.rb
# 
# $Id$
#
# This is a modified version of dot.rb from Dave Thomas's rdoc project.  I
# renamed it to rdot.rb to avoid collision with an installed rdoc/dot.
#
# It also supports undirected edges.

module DOT
    
  # These glogal vars are used to make nice graph source.

  $tab  = '    '
  $tab2 = $tab * 2
    
  # if we don't like 4 spaces, we can change it any time

  def change_tab (t)
    $tab  = t
    $tab2 = t * 2
  end
    
  # options for node declaration

  NODE_OPTS = [
    # attributes due to
    # http://www.graphviz.org/Documentation/dotguide.pdf
    # March, 26, 2005
    'bottomlabel', # auxiliary label for nodes of shape M*
    'color', # default: black; node shape color
    'comment', # any string (format-dependent)
    'distortion', # default: 0.0; node distortion for shape=polygon
    'fillcolor', # default: lightgrey/black; node fill color
    'fixedsize', # default: false; label text has no affect on node size
    'fontcolor', # default: black; type face color
    'fontname', # default: Times-Roman; font family
    'fontsize', #default: 14; point size of label
    'group', # name of node�s group
    'height', # default: .5; height in inches
    'label', # default: node name; any string
    'layer', # default: overlay range; all, id or id:id
    'orientation', # dafault: 0.0; node rotation angle
    'peripheries', # shape-dependent number of node boundaries
    'regular', # default:  false; force polygon to be regular
    'shape', # default: ellipse; node shape; see Section 2.1 and Appendix E
    'shapefile', # external EPSF or SVG custom shape file
    'sides', # default: 4; number of sides for shape=polygon
    'skew' , # default: 0.0; skewing of node for shape=polygon
    'style', # graphics options, e.g. bold, dotted, filled; cf. Section 2.3
    'toplabel', # auxiliary label for nodes of shape M*
    'URL', # URL associated with node (format-dependent)
    'width', # default: .75; width in inches
    'z', #default: 0.0; z coordinate for VRML output

    # maintained for backward compatibility or rdot internal
    'bgcolor',
    'rank'
  ]
    
  # options for edge declaration

  EDGE_OPTS = [
    'arrowhead', # default: normal; style of arrowhead at head end
    'arrowsize', # default: 1.0; scaling factor for arrowheads
    'arrowtail', # default: normal; style of arrowhead at tail end
    'color', # default: black; edge stroke color
    'comment', # any string (format-dependent)
    'constraint', # default: true use edge to affect node ranking
    'decorate', # if set, draws a line connecting labels with their edges
    'dir', # default: forward; forward, back, both, or none
    'fontcolor', # default: black type face color
    'fontname', # default: Times-Roman; font family
    'fontsize', # default: 14; point size of label
    'headlabel', # label placed near head of edge
    'headport', # n,ne,e,se,s,sw,w,nw
    'headURL', # URL attached to head label if output format is ismap
    'label', # edge label
    'labelangle', # default: -25.0; angle in degrees which head or tail label is rotated off edge
    'labeldistance', # default: 1.0; scaling factor for distance of head or tail label from node
    'labelfloat', # default: false; lessen constraints on edge label placement
    'labelfontcolor', # default: black; type face color for head and tail labels
    'labelfontname', # default: Times-Roman; font family for head and tail labels
    'labelfontsize', # default: 14 point size for head and tail labels
    'layer', # default: overlay range; all, id or id:id
    'lhead', # name of cluster to use as head of edge
    'ltail', # name of cluster to use as tail of edge
    'minlen', # default: 1 minimum rank distance between head and tail
    'samehead', # tag for head node; edge heads with the same tag are merged onto the same port
    'sametail', # tag for tail node; edge tails with the same tag are merged onto the same port
    'style', # graphics options, e.g. bold, dotted, filled; cf. Section 2.3
    'taillabel', # label placed near tail of edge
    'tailport', # n,ne,e,se,s,sw,w,nw
    'tailURL', # URL attached to tail label if output format is ismap
    'weight', # default: 1; integer cost of stretching an edge

    # maintained for backward compatibility or rdot internal
    'id'
  ]
    
  # options for graph declaration

  GRAPH_OPTS = [
    'bgcolor',
    'center', 'clusterrank', 'color', 'concentrate',
    'fontcolor', 'fontname', 'fontsize',
    'label', 'layerseq',
    'margin', 'mclimit',
    'nodesep', 'nslimit',
    'ordering', 'orientation',
    'page',
    'rank', 'rankdir', 'ranksep', 'ratio',
    'size'
  ]
    
  # a root class for any element in dot notation

  class DOTSimpleElement

    attr_accessor :name

    def initialize (params = {})
      @label = params['name'] ? params['name'] : ''
    end

    def to_s
      @name
    end
  end
    
  # an element that has options ( node, edge, or graph )

  class DOTElement < DOTSimpleElement

    # attr_reader :parent
    attr_accessor :name, :options

    def initialize (params = {}, option_list = [])
      super(params)
      @name   = params['name']   ? params['name']   : nil 
      @parent = params['parent'] ? params['parent'] : nil
      @options = {}
      option_list.each{ |i|
        @options[i] = params[i] if params[i]
      }
    end
        
    def each_option
      @options.each{ |i| yield i }
    end

    def each_option_pair
      @options.each_pair{ |key, val| yield key, val }
    end

    #def parent=( thing )
    #    @parent.delete( self ) if defined?( @parent ) and @parent
    #    @parent = thing
    #end

  end
    
    
  # This is used when we build nodes that have shape=record
  # ports don't have options :)

  class DOTPort

    attr_accessor :name, :label, :ports

    def initialize (params = {})
      @name = params['name'] || ''
      @label = params['label'] || ''
      @ports = params['ports'] || []
    end

    def each_port
      @ports.each { |i| yield i }
    end

    def <<(port)
      @ports << port
    end
    alias :push :<<

    def pop
      @ports.pop
    end

    def to_s
      if @ports.empty? then
        name = @name.empty? ? '' : "<#{@name}>"
        name + ((name.empty? or label.empty?) ? '' : ' ') + label
      else
        '{' + @ports.collect {|p| p.to_s}.join(' | ') + '}'
      end
    end
  end
    
  # node element

  class DOTNode < DOTElement

    @ports

    def initialize (params = {}, option_list = NODE_OPTS)
      super(params, option_list)
      @ports = params['ports'] ? params['ports'] : []
    end

    def each_port
      @ports.each { |i| yield i }
    end

    def << (port)
      @ports << port
    end
    alias :push :<<

    def pop
      @ports.pop
    end

    def to_s (t = '')
      label_option = nil
      if @options['shape'] =~ /^M?record$/ && !@ports.empty? then
        # Ignore the given label option in this case since the ports should each
        # provide their own name/label.
        label_option = "label = \"" + @ports.collect { |port| port.to_s }.join(" | ") + "\""
      elsif @options['label'] then
        # Otherwise, use the label when given one.
        label_option = "label = \"#{@options['label']}\""
      end

      # Convert all the options except `label' and options with nil values
      # straight into name = value pairs.  Then toss out any resulting nil
      # entries in the final array.
      stringified_options = @options.collect do |name, val|
        unless name == 'label' || val.nil? then
          "#{name} = #{val}"
        end
      end.compact
      # Append the specially computed label option.
      stringified_options.push(label_option) unless label_option.nil?

      # Put it all together into a single string with indentation and return the
      # result.
      if stringified_options.empty? then
        return t + @name.to_s
      else
        return t + @name.to_s + " [\n" +
          t + $tab + stringified_options.join(",\n" + t + $tab) + "\n" +
          t + "]"
      end
    end

  end		# class DOTNode

  # A subgraph element is the same as graph, but has another header in dot
  # notation with an identifier of 'subgraph' instead of 'graph'.

  class DOTSubgraph < DOTElement

    @nodes
    @dot_string

    def initialize (params = {}, option_list = GRAPH_OPTS)
      super(params, option_list)
      @nodes      = params['nodes'] ? params['nodes'] : []
      @dot_string = 'subgraph'
    end

    def each_node
      @nodes.each{ |i| yield i }
    end

    def << (thing)
      @nodes << thing
    end
       
    def push (thing)
      @nodes.push( thing )
    end

    def pop
      @nodes.pop
    end

    def to_s (t = '')
      hdr = t + "#{@dot_string} #{@name} {\n"

      options = @options.to_a.collect{ |name, val|
        val && name != 'label' ?
          t + $tab + "#{name} = #{val}" :
          name ? t + $tab + "#{name} = \"#{val}\"" : nil
      }.compact.join( "\n" ) + "\n\n"

      nodes = @nodes.collect{ |i|
        i.to_s( t + $tab )
      }.join( "\n\n" ) + "\n"
      hdr + options + nodes + t + "}"
    end

  end		# class DOTSubgraph

  # This is a graph.

  class DOTDigraph < DOTSubgraph

    def initialize (params = {}, option_list = GRAPH_OPTS)
      super(params, option_list)
      @dot_string = 'digraph'
    end

  end		# class DOTDigraph

  # This is an edge.

  class DOTEdge < DOTElement

    attr_accessor :from, :to

    def initialize (params = {}, option_list = EDGE_OPTS)
      super(params, option_list)
      @from = params['from'] ? params['from'] : nil
      @to   = params['to'] ? params['to'] : nil
    end
       
    def edge_link
      '--'
    end

    def to_s (t = '')
      stringified_options = @options.collect do |name, val|
        next if val.nil?
        if name == 'label' then
          "#{name} = \"#{val}\""
        else
          "#{name} = #{val}"
        end
      end.compact

      f_s = @from || ''
      t_s = @to || ''
      if stringified_options.empty? then
        t + f_s + ' ' + edge_link + ' ' + t_s
      else
        t + f_s + ' ' + edge_link + ' ' + t_s + " [\n" +
          t + $tab + stringified_options.join(",\n" + t + $tab) + "\n" +
          t + "]"
      end
    end

  end		# class DOTEdge
          
  class DOTDirectedEdge < DOTEdge

    def edge_link
      '->'
    end

  end                           # class DOTDirectedEdge
end                             # module DOT
