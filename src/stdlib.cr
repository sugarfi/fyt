require "./eval"
require "./types"
require "./error"

module Fyt::Stdlib
    macro v(x)
        {{ x }}.as(Types::FytValue)
    end

    def self.load_stdlib(eval : Evaluator)
        eval.set_var "$BASED", Types::FytNumber.new(1.0)
        eval.set_var "put", Types::FytRawFunc.new ->(args : Array(Types::FytValue), ctx : Types::FytValue?) {
            print args.map(&.format).join(" ")
            v Types::ZERO
        }

        eval.set_var "get", Types::FytRawFunc.new ->(args : Array(Types::FytValue), ctx : Types::FytValue?) {
            input = gets || Error.error "could not read input"
            v Types::FytString.new(input)
        }

        eval.set_var "if", Types::FytRawFunc.new ->(args : Array(Types::FytValue), ctx : Types::FytValue?) {
            (ctx && ctx.is_a?(Types::FytNumber)) || Error.error "invalid context for if - must be a number"
            args.size >= 2 || Error.error "2 arguments are necessary for if";
            ctx.eq(Types::ZERO) ? args[1] : args[0]
        }
    end
end
