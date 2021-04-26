require "./ast"
require "./types"
require "./error"

module Fyt
    class Evaluator
        getter scope : Hash(String, Types::FytValue) = {} of String => Types::FytValue

        def initialize(@scope : Hash(String, Types::FytValue) = {} of String => Types::FytValue)
        end

        def eval_node(node : AST::Node)
            case node
            when AST::NumberNode
                Types::FytNumber.new node.value
            when AST::StringNode
                raw = node.value[1..-2]
                value = ""
                esc = false
                raw.chars.each do |c|
                    if esc
                        case c
                        when 'n'
                            value += "\n"
                        when 'r'
                            value += "\r"
                        when 'e'
                            value += "\x1b"
                        when '\\'
                            value += "\\"
                        else
                            Error.error "Invalid escape sequence \\#{c}"
                        end
                        esc = false
                    else
                        if c == '\\'
                            esc = true
                        else
                            value += c
                        end
                    end
                end
                Types::FytString.new value
            when AST::SymbolNode
                Types::FytSymbol.new node.value[1..]
            when AST::MapNode
                new = {} of Types::FytValue => Types::FytValue

                node.value.keys.each do |k|
                    case k
                    when Int32
                        new[Types::FytNumber.new k.to_f32] = eval_node(node.value[k]).as(Types::FytValue)
                    else
                        new[eval_node(k).as(Types::FytValue)] = eval_node(node.value[k]).as(Types::FytValue)
                    end
                end

                Types::FytMap.new new
            when AST::BlockNode
                Types::FytBlock.new node.lines, node.export
            when AST::CallNode
                func = eval_node(node.func).as(Types::FytValue)
                if node.ctx
                    ctx = eval_node(node.ctx.as(AST::ExprNode)).as(Types::FytValue)
                else
                    ctx = nil
                end

                case func
                when Types::FytBlock
                    args = node.args.map { |x| eval_node(x).as(Types::FytValue) }
                    real_args = {} of Types::FytValue => Types::FytValue
                    args.map_with_index do |val, i|
                        real_args[Types::FytNumber.new i.to_f32] = val
                    end

                    eval = Evaluator.new @scope.dup
                    eval.set_var "@", Types::FytMap.new(real_args)
                    if ctx
                        eval.set_var "$", ctx
                    end

                    res = eval.eval func.value

                    if func.export
                        @scope.merge! eval.scope
                    end

                    res
                when Types::FytMap
                    if node.args.size > 1
                        Error.error "Too many arguments for map index."
                    end

                    key = node.args[0]
                    case key
                    when AST::NameNode
                        if get_var(key.value)
                            key = get_var(key.value).as(Types::FytValue)
                        else
                            key = Types::FytSymbol.new key.value
                        end
                    else
                        key = eval_node(key).as(Types::FytValue)
                    end

                    if res = func.get_key key
                        res
                    else
                        Error.error "Key #{key.format} not found."
                    end
                when Types::FytRawFunc
                    args = node.args.map { |x| eval_node(x).as(Types::FytValue) }
                    func.value.call(args, ctx)
                end
            when AST::AssignNode
                name = node.name
                case name
                when AST::NameNode
                    set_var name.value, eval_node(node.value).as(Types::FytValue)
                when AST::MapNode
                    rhs = eval_node(node.value).as(Types::FytValue)
                    unless rhs.is_a?(Types::FytMap)
                        Error.error "Attempted to destructure non-map #{rhs.format}"
                    end

                    name.value.keys.each do |key|
                        if key.is_a? Int32
                            key = Types::FytNumber.new key.to_f32
                        else
                            key = eval_node(key).as(Types::FytValue)
                        end
                        real = rhs.get_key key
                        value = nil
                        name.value.each do |key2, val2|
                            case key2
                            when Int32
                                key2 = Types::FytNumber.new key2.to_f32
                            else
                                key2 = eval_node(key2).as(Types::FytValue)
                            end

                            if key.eq(key2)
                                value = val2
                            end
                        end

                        unless real
                            Error.error "Missing key in destructuring #{key.format}"
                        end

                        unless value.is_a?(AST::NameNode)
                            Error.error "Non name node in destructuring"
                        end

                        set_var value.value, real
                    end

                else
                    Error.error "Invalid left hand side in assignment"
                end
            when AST::NameNode
                if res = get_var node.value
                    res
                else
                    Error.error "Attempted to access non-existent variable #{node.value}"
                end
            when AST::OpNode
                a = eval_node(node.a).as(Types::FytValue)
                b = eval_node(node.b).as(Types::FytValue)

                case node.op
                when AST::Op::Lt
                    a.lt(b) ? Types::ONE : Types::ZERO
                when AST::Op::Gt
                    a.lt(b) ? Types::ZERO : Types::ONE
                when AST::Op::Eq
                    a.eq(b) ? Types::ONE : Types::ZERO
                when AST::Op::Ne
                    a.eq(b) ? Types::ZERO : Types::ONE
                when AST::Op::Add
                    a.add b
                when AST::Op::Sub
                    a.sub b
                when AST::Op::Mul
                    a.mul b
                when AST::Op::Div
                    a.div b
                when AST::Op::Pow
                    a.pow b
                end
            end
        end

        def set_var(name : String, value : Types::FytValue)
            @scope[name] = value
        end

        def get_var(name : String)
            @scope[name]?
        end

        def eval(ast : Array(AST::Node))
            result = nil

            ast.each do |node|
                result = eval_node node
            end

            result
        end
    end
end

