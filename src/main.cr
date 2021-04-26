require "./parser"
require "./eval"
require "./stdlib"

parser = Fyt::Parser.new ARGV[0]? || "STDIN"
eval = Fyt::Evaluator.new global: true
Fyt::Stdlib.load_stdlib eval

if file = ARGV[0]?
    code = File.read file
    ast = parser.parse code
    eval.eval ast
else
    puts "fyt lang"
    puts "by pip"

    loop do
        print "> "
        line = gets
        unless line
            exit 1
        end
        ast = parser.parse "#{line}\n"
        result = eval.eval(ast)
        if result
            puts result.format
        end
    end
end
