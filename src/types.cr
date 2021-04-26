require "./ast"
require "./error"

module Fyt::Types
    abstract class FytValue
        abstract def format
        abstract def eq(other : FytValue)
        abstract def lt(other : FytValue)
        abstract def add(other : FytValue)
        abstract def sub(other : FytValue)
        abstract def mul(other : FytValue)
        abstract def div(other : FytValue)
        abstract def pow(other : FytValue)
    end

    class FytNumber < FytValue
        getter value : Float32

        def initialize(@value : Float32)
        end

        def format
            "#{@value}"
        end

        def eq(other : FytValue)
            other.value == @value
        end

        def lt(other : FytValue)
            other.is_a?(FytNumber) || Error.error "Attempted to compare number and non-number"
            @value < other.value
        end

        def add(other : FytValue)
            other.is_a?(FytNumber) || Error.error "Attempted to add number and non-number"
            FytNumber.new @value + other.value
        end

        def sub(other : FytValue)
            other.is_a?(FytNumber) || Error.error "Attempted to subtract number and non-number"
            FytNumber.new @value - other.value
        end

        def mul(other : FytValue)
            other.is_a?(FytNumber) || Error.error "Attempted to multiply number and non-number"
            FytNumber.new @value * other.value
        end

        def div(other : FytValue)
            other.is_a?(FytNumber) || Error.error "Attempted to divide number and non-number"
            FytNumber.new @value / other.value
        end

        def pow(other : FytValue)
            other.is_a?(FytNumber) || Error.error "Attempted to pow number and non-number"
            FytNumber.new @value ** other.value
        end
    end

    class FytString < FytValue
        getter value : String

        def initialize(@value : String)
        end

        def format
            @value
        end

        def eq(other : FytValue)
            other.value == @value
        end

        def lt(other : FytValue)
            other.is_a?(FytString) || Error.error "Attempted to compare string and non-string"
            @value.size < other.value.size
        end

        def add(other : FytValue)
            FytString.new "#{@value}#{other.format}"
        end

        def sub(other : FytValue)
            Error.error "Cannot subtract string"
        end

        def mul(other : FytValue)
            other.is_a?(FytNumber) || Error.error "Attempted to multiply string and non-number"
            FytString.new @value * other.value.to_i32
        end

        def div(other : FytValue)
            FytNumber.new @value.count(other.format).to_f32
        end

        def pow(other : FytValue)
            Error.error "Cannot pow string"
        end
    end

    class FytSymbol < FytValue
        getter value : String

        def initialize(@value : String)
        end

        def format
            "!#{@value}"
        end

        def eq(other : FytValue)
            other.value == @value
        end

        def lt(other : FytValue)
            other.is_a?(FytSymbol) || Error.error "Attempted to compare symbol and non-symbol"
            @value.size < other.value.size
        end

        def add(other : FytValue)
            FytSymbol.new "#{@value}#{other.format}"
        end

        def sub(other : FytValue)
            Error.error "Cannot subtract symbol"
        end

        def mul(other : FytValue)
            other.is_a?(FytNumber) || Error.error "Attempted to multiply symbol and non-number"
            FytSymbol.new @value * other.value.to_i32
        end

        def div(other : FytValue)
            FytNumber.new @value.count(other.format).to_f32
        end

        def pow(other : FytValue)
            Error.error "Cannot pow symbol"
        end
    end

    class FytMap < FytValue
        getter value : Hash(FytValue, FytValue)
        
        def initialize(@value : Hash(FytValue, FytValue))
        end

        def get_key(key : FytValue)
            @value.keys.each do |test|
                if test.eq key
                    return @value[test]
                end
            end
        end

        def set_key(key : FytValue, value : FytValue)
            @value.keys.each do |test|
                if test.eq key
                    @value[test] = value
                    return
                end
            end
            @value[key] = value
        end

        def format
            String.build do |s|
                s << "[ "
                @value.each do |k, v|
                    s << "#{k.format} => #{v.format} ";
                end
                s << "]"
            end
        end

        def eq(other : FytValue)
            false
        end

        def lt(other : FytValue)
            Error.error "Cannot compare map"
        end

        def add(other : FytValue)
            other.is_a?(FytMap) || Error.error "Cannot add map and non-map"
            value = FytMap.new @value.dup
            other.value.keys.each do |key|
                value.set_key key, other.get_key(key).as(FytValue)
            end
            value
        end

        def sub(other : FytValue)
            Error.error "Cannot subtract map"
        end

        def mul(other : FytValue)
            Error.error "Cannot multiply map"
        end

        def div(other : FytValue)
            Error.error "Cannot divide map"
        end

        def pow(other : FytValue)
            Error.error "Cannot compare map"
        end
    end

    class FytBlock < FytValue
        getter value : Array(AST::Node)
        getter export : Bool
        getter scope : Hash(String, FytValue)

        def initialize(@value : Array(AST::Node), @export : Bool, @scope : Hash(String, FytValue))
        end

        def format
            "#{@export ? "%e" : ""}<block>"
        end

        def eq(other : FytValue)
            false
        end

        def lt(other : FytValue)
            Error.error "Cannot compare block"
        end

        def add(other : FytValue)
            other.is_a?(FytBlock) || Error.error "Cannot add block and non-block"
            FytBlock.new @value + other.value, @export, @scope.dup
        end

        def sub(other : FytValue)
            Error.error "Cannot subtract block"
        end

        def mul(other : FytValue)
            Error.error "Cannot multiply block"
        end

        def div(other : FytValue)
            Error.error "Cannot divide block"
        end

        def pow(other : FytValue)
            Error.error "Cannot compare block"
        end
    end

    class FytRawFunc < FytValue
        getter value : Proc(Array(FytValue), FytValue?, FytValue)

        def initialize(@value : Proc(Array(FytValue), FytValue?, FytValue))
        end

        def format
            "<rawfunc>"
        end

        def eq(other : FytValue)
            false
        end

        def lt(other : FytValue)
            Error.error "Cannot compare rawfunc"
        end

        def add(other : FytValue)
            Error.error "Cannot add rawfunc"
        end

        def sub(other : FytValue)
            Error.error "Cannot subtract rawfunc"
        end

        def mul(other : FytValue)
            Error.error "Cannot multiply rawfunc"
        end

        def div(other : FytValue)
            Error.error "Cannot divide rawfunc"
        end

        def pow(other : FytValue)
            Error.error "Cannot compare rawfunc"
        end
    end

    ONE = FytNumber.new(1.0)
    ZERO = FytNumber.new(0.0)
end
