use CX::Red::Bool;

=head2 Red::AST

unit role Red::AST;
#has Red::AST $.next;

#multi method add(Red::AST:D: Red::AST:D $next) { if $!next { $!next.add: $next } else { $!next = $next } }
#multi method add(Red::AST:U: Red::AST:D $next) { $next }

#method gist { ... }
method find-column-name { ... }

#method should-set($class       --> Hash()) { ... }
#method should-validate(%values --> Bool()) { ... }

method gist { self.^name ~ ":\n" ~ $.args.map(*.gist).join("\n").indent: 4 }

#| Returns the nagation of the AST.
method not { die "not on { self.^name } must be implemented" }

method args { ... }
method returns { ... }

#| If inside of a block for ResultSeq mothods throws a control exception
#| and populates all possibilities
method Bool(--> Bool()) {
    return True unless %*VALS.defined;
    %*VALS{self} = False if %*VALS{self}:!exists;
    CX::Red::Bool.new(:ast(self), :value(%*VALS{self})).throw;
    %*VALS{self}
}

method Str { self }

#| Transposes the AST tree running the function.
method transpose(::?CLASS:D: &func) {
    die self unless self.^can: "args";
    for self.args.grep: Red::AST -> $arg {
        .transpose: &func with $arg
    }
    func self;
}

#| Returns a list with all the tables used on the AST
method tables(::?CLASS:D:) {
    my @tables;
    self.transpose: {
        if .^name eq "Red::Column" {
            @tables.push: .class
        }
    }
    |@tables.grep(-> \v { v !=:= Nil }).unique
}

multi method WHICH(::?CLASS:D:) {
    ValueObjAt.new: "{ self.^name }|{ $.args>>.WHICH.join: "|" }"
}

multi method WHICH(::?CLASS:U:) {
    ValueObjAt.new: "{ self.^name }"
}
