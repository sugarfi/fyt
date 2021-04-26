module Fyt::Error
    def self.error(msg : String)
        STDERR.puts msg
        exit 1
    end
end
