module Fyt::Lexer
    enum TokenType
        Number
        String
        Name
        Equals
        Op
        Lpar
        Rpar
        Lbrack
        Rbrack
        Arrow
        Symbol
        Dot
        Lpoint
        Rpoint
        Lbrace
        Rbrace
        Semi
        Qmark
        Export
        Include
        Comment
    end

    TOKENS = {
        /^-?[0-9]+(\.[0-9]+)?/ => TokenType::Number,
        /^"([^"]|\\")*?"/ => TokenType::String,
        /^![a-zA-Z_0-9$@]+/ => TokenType::Symbol,
        /^[a-zA-Z_$@][a-zA-Z_0-9$@]*/ => TokenType::Name,
        /^(%gt|%lt|%eq|%ne|\+|-|\*|\/|\^)/ => TokenType::Op,
        /^\(/ => TokenType::Lpar,
        /^\)/ => TokenType::Rpar,
        /^\[/ => TokenType::Lbrack,
        /^\]/ => TokenType::Rbrack,
        /^=>/ => TokenType::Arrow,
        /^=/ => TokenType::Equals,
        /^\./ => TokenType::Dot,
        /^</ => TokenType::Lpoint,
        /^>/ => TokenType::Rpoint,
        /^\{/ => TokenType::Lbrace,
        /^\}/ => TokenType::Rbrace,
        /^;/ => TokenType::Semi,
        /^\?/ => TokenType::Qmark,
        /^%(export|ex)/ => TokenType::Export,
        /^%(include|in)/ => TokenType::Include,
        /^#.+/ => TokenType::Comment
    }

    WHITESPACE = /^[ \n\t]/

    struct Token
        getter match : String
        getter type : TokenType

        def initialize(@match : String, @type : TokenType)
        end
    end

    def self.lex(text : String)
        tokens = [] of Token

        while m = WHITESPACE.match(text)
            text = text[m[0].size..]
        end

        while text != ""
            matched = false

            TOKENS.each do |regex, type|
                if m = regex.match(text)
                    unless type == TokenType::Comment
                        tokens << Token.new m[0], type
                    end
                    text = text[m[0].size..]
                    matched = true
                end
            end

            unless matched
                return nil
            end

            while m = WHITESPACE.match(text)
                text = text[m[0].size..]
            end
        end

        return tokens
    end
end
