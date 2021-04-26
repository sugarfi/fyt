module Fyt::AST
    abstract class Node
    end

    abstract class ExprNode < Node
    end

    class NumberNode < ExprNode
        getter value : Float32

        def initialize(@value : Float32)
        end
    end

    class StringNode < ExprNode
        getter value : String

        def initialize(@value : String)
        end
    end

    class NameNode < ExprNode
        getter value : String

        def initialize(@value : String)
        end
    end

    class SymbolNode < ExprNode
        getter value : String

        def initialize(@value : String)
        end
    end

    class MapNode < ExprNode
        getter value : Hash(Int32 | ExprNode, ExprNode)

        def initialize(@value : Hash(Int32 | ExprNode, ExprNode))
        end
    end

    class CallNode < ExprNode
        getter func : ExprNode
        getter args : Array(ExprNode)
        getter ctx : ExprNode?

        def initialize(@func : ExprNode, @args : Array(ExprNode), @ctx : ExprNode?)
        end
    end

    enum Op
        Lt
        Gt
        Eq
        Ne
        Add
        Sub
        Mul
        Div
        Pow
    end

    class OpNode < ExprNode
        getter op : Op
        getter a : ExprNode
        getter b : ExprNode

        def initialize(@op : Op, @a : ExprNode, @b : ExprNode)
        end
    end

    class AssignNode < ExprNode
        getter name : ExprNode
        getter value : ExprNode

        def initialize(@name : ExprNode, @value : ExprNode)
        end
    end

    enum DeclareScope
        My
        Our
    end

    class BlockNode < ExprNode
        getter lines : Array(Node)
        getter export : Bool

        def initialize(@lines : Array(Node), @export : Bool)
        end
    end

    class IncludeNode < Node
        getter path : String

        def initialize(@path : String)
        end
    end
end
