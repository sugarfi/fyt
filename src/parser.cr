require "./ast"
require "./lexer"

module Fyt
    class Parser
        @file : String
        @line : Int32 = 0
        @buffer : String = ""
        @tokens : Array(Lexer::Token) = [] of Lexer::Token
        @block : Int32 = 0

        def initialize(@file : String)
        end

        def syntax_error
            STDERR.puts "Syntax error at #{@file} line #{@line + 1}:"
            STDERR.puts @buffer
            exit 1
        end

        def accept(type : Lexer::TokenType, n = 0)
            unless @tokens.size > n
                return nil
            end

            if @tokens[n].type == type
                match = @tokens[n].match

                @tokens.delete_at n

                match
            end
        end

        def try(method : ->AST::Node?)
            old = @tokens.dup

            result = method.call

            unless result
                @tokens = old
                return nil
            end

            result
        end

        macro t(f)
            try ->{{ f }}
        end

        def parse_number
            token = accept(Lexer::TokenType::Number) || return nil

            AST::NumberNode.new token.to_f32
        end

        def parse_name
            token = accept(Lexer::TokenType::Name) || return nil

            AST::NameNode.new token
        end

        def parse_symbol
            token = accept(Lexer::TokenType::Symbol) || return nil

            AST::SymbolNode.new token
        end

        def parse_call
            if accept(Lexer::TokenType::Qmark)
                ctx = nil
            else
                accept(Lexer::TokenType::Lpoint) || return nil
                ctx = parse_expr
                accept(Lexer::TokenType::Rpoint) || return nil
            end

            func = parse_expr || return nil

            accept(Lexer::TokenType::Dot) || return nil

            args = [] of AST::ExprNode

            while arg = parse_expr
                args << arg
            end

            AST::CallNode.new func, args, ctx
        end

        def parse_string
            token = accept(Lexer::TokenType::String) || return nil

            AST::StringNode.new token
        end

        def parse_map
            accept(Lexer::TokenType::Lbrack) || return nil

            items = {} of Int32 | AST::ExprNode => AST::ExprNode
            count = 0

            while a = parse_expr
                if accept(Lexer::TokenType::Arrow)
                    b = parse_expr || return nil
                    items[a] = b
                else
                    items[count] = a
                    count += 1
                end
            end

            accept(Lexer::TokenType::Rbrack) || return nil

            AST::MapNode.new items
        end

        def parse_op
            op = accept(Lexer::TokenType::Op) || return nil
            case op
            when "%lt"
                op = AST::Op::Lt
            when "%gt"
                op = AST::Op::Lt
            when "%eq"
                op = AST::Op::Eq
            when "%ne"
                op = AST::Op::Ne
            when "+"
                op = AST::Op::Add
            when "-"
                op = AST::Op::Sub
            when "*"
                op = AST::Op::Mul
            when "/"
                op = AST::Op::Div
            when "^"
                op = AST::Op::Pow
            end

            a = t(parse_expr) || return nil

            b = t(parse_expr) || return nil

            AST::OpNode.new op.as(AST::Op), a, b
        end

        def parse_block
            ex = false
            if accept Lexer::TokenType::Export
                ex = true
            end

            accept(Lexer::TokenType::Lbrace) || return nil

            results = [] of AST::Node

            loop do
                if accept(Lexer::TokenType::Rbrace)
                    return AST::BlockNode.new results, ex
                end
                result = parse_line || return nil
                results << result
            end
        end

        def parse_assign
            name = parse_name || parse_map || return nil

            accept(Lexer::TokenType::Equals) || return nil

            expr = parse_expr || return nil

            AST::AssignNode.new name, expr
        end

        def parse_include
            accept(Lexer::TokenType::Include) || return nil

            path = accept(Lexer::TokenType::String) || return nil

            AST::IncludeNode.new path[1..-2]
        end

        def parse_expr
            if accept(Lexer::TokenType::Lpar)
                body = parse_expr

                accept(Lexer::TokenType::Rpar) || return nil

                body
            else
                t(parse_call) || 
                t(parse_assign) ||
                t(parse_name) || 
                t(parse_symbol) || 
                t(parse_number) || 
                t(parse_string) || 
                t(parse_map) || 
                t(parse_op) || 
                t(parse_block)
            end
        end

        def parse_line : AST::Node?
            result = t(parse_expr) || t(parse_include) || return nil
            accept(Lexer::TokenType::Semi) || return nil
            result
        end

        def parse(line : String)
            results = [] of AST::Node

            tokens = Lexer.lex(line) || syntax_error
            @tokens = tokens.as Array(Lexer::Token)

            while @tokens.size > 0
                result = parse_line || syntax_error
                if result.is_a? AST::IncludeNode
                    match = nil

                    ENV.fetch("FYT_PATH", "~/.fytlib").split(':').each do |part|
                        path = Path[part].join result.path
                        if !match && File.exists?(path)
                            match = path
                        end
                    end

                    unless match
                        if File.exists? result.path
                            match = result.path
                        else
                            Error.error "couldn't find #{result.path}"
                        end
                    end

                    p2 = Parser.new match.to_s
                    results += p2.parse(File.read(match))
                else
                    results << result.as(AST::Node)
                end
            end

            results
        end
    end
end
