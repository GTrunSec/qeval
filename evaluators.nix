{ pkgs, prepareJob }:
with pkgs;

let
  self = {
    perl = prepareJob {
      name = "perl";
      mem = 50;
      aliases = [ "pl" ];
      storeDrives.perl = [ pkgsCross.musl64.perl ];
      preCommand = ''
        perl -e 'print "Hello world!"'
      '';

      command = ''
        perl "$1"
      '';

      testInput = "print \"success\"";
    };

    rust =
      let
        opts = lib.concatStringsSep " " [
          "--color never"
          "-C opt-level=0"
          "-C prefer-dynamic"
          "-C debuginfo=0"
          "-v" "--error-format short"
          "-C codegen-units=1"
        ];
      in prepareJob {
        name = "rust";
        aliases = [ "rs" ];
        mem = 200;
        storeDrives.rust = [
          (rustChannelOf {
            channel = "nightly";
            date = "2018-08-06";
          }).rust
          gcc
        ];

        preCommand = ''
          echo 'fn main() {}' > /tmp/sample
          rustc ${opts} -o /tmp/sample.out /tmp/sample
          /tmp/sample.out
          rm /tmp/sample /tmp/sample.out
        '';

        command = ''
          mv "$1" /input.raw
          cat > /input <<EOF
            #![allow(unreachable_code, dead_code)]
            fn main() {
              println!("{:?}", {
                $(cat /input.raw)
              })
            }
          EOF
          rustc ${opts} -o /input.out /input && /input.out
        '';

        testInput = "\"success\"";
        testOutput = "\"success\"";
      };

    go = prepareJob {
      name = "go";
      mem = 100;
      storeDrives.go = [ go ];

      command = ''
        mv "$1" /input.raw
        cat > /input.go <<EOF
          package main
          import "fmt"
          func main() {
            fmt.Println($(cat /input.raw))
          }
        EOF
        go run /input.go
      '';

      testInput = ''"success"'';
    };

    c = prepareJob {
      name = "c";
      mem = 100;
      aliases = [ "gcc" ];
      storeDrives.gcc = [ gcc ];
      preCommand = ''
        echo 'int main() { return 0; }' > /tmp/sample
        gcc -x c -o /tmp/sample.out /tmp/sample
        /tmp/sample.out
      '';

      command = ''
        gcc -x c -o /input.out -w -fdiagnostics-color=never "$1" && /input.out
      '';

      testInput = ''
        void main() { printf("success\n"); }
      '';
    };

    cpp = prepareJob {
      name = "cpp";
      mem = 100;
      storeDrives.gcc = [ gcc ];

      command = ''
        mv "$1" /input.raw
        cat > /input <<EOF
          #include <iostream>
          using namespace std;
          int main() {
            $(cat /input.raw)
            return 0;
          };
        EOF
        g++ -x 'c++' -o /input.out /input && /input.out
      '';
    
      testInput = "cout << \"success\" << endl;";
    };

    tcc = prepareJob {
      name = "tcc";
      mem = 50;
      storeDrives.tcc = [ tinycc ];
      preCommand = ''
        echo 'int main() { return 0; }' > /tmp/sample
        tcc -run /tmp/sample
      '';

      command = ''
        tcc -run "$1" 2>/dev/null
      '';

      testInput = ''
        void main() { printf("success\n"); }
      '';
    };

    java = prepareJob rec {
      name = "java";
      mem = 150;

      storeDrives.jdk = [ openjdk ];

      preCommand = ''
        cat > /tmp/Main.java <<EOF
          ${testInput}
        EOF
        javac /tmp/Main.java
        cd /tmp && java Main
      '';

      command = ''
        mv "$1" /Main.java
        javac Main.java && java Main
      '';

      # TODO: multi-line tests/input
      testInput = ''
        public class Main { public static void main(String... args) { System.out.println("success"); } }
      '';
    };

    kotlin = prepareJob rec {
      name = "kotlin";
      mem = 300;
      storeDrives.kotlin = [ kotlin ];

      preCommand = ''
        cat > /tmp/Main.kts <<EOF
          ${testInput}
        EOF
        kotlinc -script /tmp/Main.kts
      '';

      command = ''
        mv "$1" /input.kts
        kotlinc -script /input.kts
      '';

      testInput = ''println("success")'';
    };

    python = prepareJob {
      name = "python";
      aliases = [ "python3" "py" "py3" ];
      mem = 75;
      storeDrives.python = [ python3 ];
      preCommand = ''
        ${python3}/bin/python3 -c "print(42)"
      '';

      command = ''
        ${python3}/bin/python3 "$1"
      '';

      testInput = "print(\"success\")";
    };

    ruby = prepareJob {
      name = "ruby";
      aliases = [ "rb" ];
      mem = 100;
      storeDrives.ruby = [ ruby_2_5 ];

      preCommand = ''
        echo 42 | ruby
      '';

      command = ''
        ruby "$1"
      '';

      testInput = "puts \"success\"";
    };

    sh = prepareJob {
      name = "bash";
      aliases = [ "shell" "sh" ];
      mem = 60;
      storeDrives.bash = [ bash coreutils gnused gnugrep gawk file bsdgames ];

      command = ''
        bash "$1"
      '';

      testInput = "echo success";
    };

    ash = prepareJob {
      name = "ash";
      command = ''
        /bin/sh "$1"
      '';

      testInput = "echo success";
    };

    nodejs = prepareJob {
      name = "nodejs";
      aliases = [ "node" "js" ];
      mem = 100;
      storeDrives.node = [ nodejs ];

      preCommand = ''
        node -e "console.log(42)"
      '';

      command = ''
        node -p "$(cat "$1")" | tr -s '\n ' ' '
      '';
      /*
        mv "$1" /input.raw
        cat > /input <<EOF
          function debug(val) {
            return require("util").inspect(val, { depth: 1, colors: false })
              .replace(/\s+/g, ' ')
          }
          console.log(debug($(cat /input.raw)))
        EOF

        node /input
      '';*/

      testInput = "'success'";
      testOutput = "success ";
    };

    lua = prepareJob {
      name = "lua";
      mem = 50;
      storeDrives.lua = [ lua5_3 ];

      command = ''
        lua "$1"
      '';

      testInput = "print(\"success\")";
    };

    brainfuck = prepareJob {
      name = "brainfuck";
      aliases = [ "bf" ];
      storeDrives.brainfuck = [
        (runCommand "just-brainfuck" {} ''
          mkdir -p $out/bin
          cp ${haskellPackages.brainfuck}/bin/bf $out/bin/
        '')
      ];

      preCommand = ''
        echo '+[-[<<[+[--->]-[<<<]]]>>>-]>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.' > /tmp/sample
        bf < /tmp/sample
      '';

      command = ''
        bf < "$1"
      '';

      testInput = "+[-[<<[+[--->]-[<<<]]]>>>-]>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.";
      testOutput = "hello world";
    };

    php = prepareJob {
      name = "php";
      mem = 100;
      storeDrives.php = [ php ];

      command = ''
        php -r "$(cat "$1")"
      '';

      testInput = ''echo "success";'';
    };

    racket = prepareJob {
      name = "racket";
      aliases = [ "rkt" "r" ];
      mem = 200;
      storeDrives.racket = [ racket ];

      preCommand = ''
        racket -e '(+ 40 2)'
      '';

      command = ''
        ( echo "#lang racket"
          cat "$1"
        ) | racket /proc/self/fd/0
      '';

      testInput = "(displayln 'success)";
    };

    guile = prepareJob {
      name = "guile";
      mem = 100;
      storeDrives.guile = [ guile ];

      command = ''
        guile --no-auto-compile -s "$1"
      '';

      testInput = ''(display "success")'';
    };

    haskell = prepareJob {
      name = "haskell";
      aliases = [ "hask" "hs" "h" ];
      mem = 200;
      storeDrives.ghc = [ ghc ];

      preCommand = ''
        echo '"foo":[]:[]' > /tmp/sample
        ghci -v0 < /tmp/sample
      '';

      command = ''
        ghci -v0 < "$1"
      '';

      testInput = "putStrLn \"success\"";
    };

    listAll = with self; [
      ash
      sh
      python
      ruby
      perl
      lua
      nodejs 
      haskell
      rust
      c tcc
      cpp
      java
      # kotlin
      racket
      guile
      brainfuck
      php
      go
    ];

    all = symlinkJoin {
      name = "all-evaluators";
      paths = self.listAll;
    };

    apparmorAll = map (p: p.apparmor) self.listAll;
  };
in self