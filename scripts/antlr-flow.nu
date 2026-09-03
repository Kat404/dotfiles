#!/usr/bin/env nu

# antlr-flow.nu — Regenerate ANTLR v4 parser/lexer, recompile, run Test.
# Designed for ANTLR 4.13.x on Arch Linux.
#
# Usage (from the antlr directory):
#   nu antlr-flow.nu                # regenerate + recompile + run against ./input.txt (omits parse tree)
#   nu antlr-flow.nu --debug        # regenerate + recompile + run and print parse tree (tree.toStringTree)
#   nu antlr-flow.nu --no-run       # regenerate + recompile only
#   nu antlr-flow.nu --repl         # regenerate + recompile + drop into a stdin REPL
#
# Make executable once:
#   chmod +x antlr-flow.nu
#   ./antlr-flow.nu
#
# Honors NO_COLOR env var (https://no-color.org/).

const CP = "/usr/share/java/antlr-complete.jar:."

# Paint text with an ANSI color/style code.
# Wraps the text with the code's escape sequence and a reset.
# Skipped when NO_COLOR is set.
# Usage: (paint cyan_bold "[1/3]")
def paint [code: string, text: string] {
    if "NO_COLOR" in $env {
        return $text
    }
    return $"(ansi $code)($text)(ansi reset)"
}

def filter-output [debug: bool] {
    if $debug {
        $in
    } else {
        $in | lines | where { |line| not ($line | str starts-with "(") } | str join (char newline)
    }
}

def main [
    --no-run            # regenerate + compile, skip the run step
    --repl              # regenerate + compile, then read tokens interactively from stdin
    --debug (-d)        # print parse tree (tree.toStringTree)
] {
    cd $env.FILE_PWD

    print --stderr $"(paint cyan_bold '[1/3]') (paint magenta 'regenerating parser from T.g4')"
    ^/usr/bin/antlr4 T.g4

    print --stderr $"(paint cyan_bold '[2/3]') (paint yellow 'cleaning .class and compiling')"
    ^rm -f ...(glob *.class)
    javac -cp $CP T*.java Test.java

    if $no_run {
        print --stderr $"(paint cyan_bold '[3/3]') (paint yellow_dimmed 'skipped (--no-run)')"
        return
    }

    print --stderr $"(paint cyan_bold '[3/3]') (paint green 'running Test')"
    if $repl {
        print --stderr $"      (paint yellow 'reading from stdin (Ctrl-D to finish)')"
        if $debug {
            java -cp $CP Test
        } else {
            java -cp $CP Test | filter-output $debug
        }
        return
    }

    if ("input.txt" | path exists) {
        print --stderr $"      (paint green 'using ') (paint cyan_bold './input.txt')"
        if $debug {
            open --raw input.txt | java -cp $CP Test
        } else {
            open --raw input.txt | java -cp $CP Test | filter-output $debug
        }
    } else {
        print --stderr $"      (paint yellow 'no input.txt found — reading from stdin (Ctrl-D to finish)')"
        if $debug {
            java -cp $CP Test
        } else {
            java -cp $CP Test | filter-output $debug
        }
    }
}
