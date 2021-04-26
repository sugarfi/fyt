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

        eval.set_var "chr", Types::FytRawFunc.new ->(args : Array(Types::FytValue), ctx : Types::FytValue?) {
            (args.size >= 1 && args[0].is_a?(Types::FytNumber)) || Error.error "invalid argument for chr - must be a number"
            Types::FytString.new("#{args[0].value.as(Float32).to_i32.chr}").as(Types::FytValue)
        }

        eval.set_var "ord", Types::FytRawFunc.new ->(args : Array(Types::FytValue), ctx : Types::FytValue?) {
            (args.size >= 1 && args[0].is_a?(Types::FytString) && args[0].as(Types::FytString).value.size >= 1) || Error.error "invalid argument for ord - must be a string"
            Types::FytNumber.new(args[0].as(Types::FytString).value[0].ord.to_f32).as(Types::FytValue)
        }

        eval.set_var "has_key", Types::FytRawFunc.new ->(args : Array(Types::FytValue), ctx : Types::FytValue?) {
            (ctx && ctx.is_a?(Types::FytMap)) || Error.error "invalid context for has_key - must be a map"
            args.size >= 1 || Error.error "1 argument is necessary for has_key";
            (ctx.as(Types::FytMap).get_key(args[0]) ? Types::ONE : Types::ZERO).as(Types::FytValue)
        }

        eval.set_var "chars", Types::FytRawFunc.new ->(args : Array(Types::FytValue), ctx : Types::FytValue?) {
            (args.size >= 1 && args[0].is_a?(Types::FytString)) || Error.error "invalid argument for chars - must be a string"
            chars = {} of Types::FytValue => Types::FytValue
            args[0].as(Types::FytString).value.chars.each_with_index do |c, i|
                chars[Types::FytNumber.new(i.to_f32).as(Types::FytValue)] = Types::FytString.new("#{c}").as(Types::FytValue)
            end
            Types::FytMap.new(chars).as(Types::FytValue)
        }
    end
end
