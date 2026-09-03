#!/usr/bin/env nu

# antlr-state.nu — Tabular snapshot of ANTLR project state.
# Shows source, generated, compiled, and script files with stale detection
# against the grammar (T.g4).
#
# Usage (from the antlr directory):
#   nu antlr-state.nu              # full native table
#   nu antlr-state.nu --stale      # only stale files (what needs regenerating)
#   nu antlr-state.nu --content    # add T.g4 + input.txt panels below
#   nu antlr-state.nu --json       # structured output for piping
#
# Make executable once:
#   chmod +x antlr-state.nu
#
# Excluded from output:
#   - .interp and .tokens (ANTLR internal metadata, regenerable)
#   - Prog.java (unrelated to ANTLR flow)
#   - *.pdf (class material, not a project file)
#
# Honors NO_COLOR env var (https://no-color.org/).

const SOURCE = "T.g4"
const TRACKED = ["T.g4" "input.txt" "Test.java" "antlr-flow.nu" "TLexer.java" "TParser.java" "TListener.java" "TBaseListener.java"]

# ANSI paint
def paint [code: string, text: string] {
    if "NO_COLOR" in $env { return $text }
    return $"(ansi $code)($text)(ansi reset)"
}

def role-of [file: string] {
    if $file == "T.g4" { return "source" }
    if $file == "input.txt" { return "input" }
    if $file == "Test.java" { return "driver" }
    if $file in ["TLexer.java" "TParser.java" "TListener.java" "TBaseListener.java"] { return "generated" }
    if $file == "antlr-flow.nu" { return "script" }
    if ($file | str ends-with ".class") { return "compiled" }
    "other"
}

def color-for-role [role: string] {
    if $role == "source" { return "cyan_bold" }
    if $role == "input" { return "cyan" }
    if $role == "driver" { return "yellow" }
    if $role == "script" { return "yellow" }
    if $role == "generated" { return "default_dimmed" }
    if $role == "compiled" { return "default_dimmed" }
    "default_dimmed"
}

# Human-friendly age: "30s ago", "5m ago", "2h ago", "3d ago"
def human-age [age: duration] {
    let sec = ($age / 1sec | into int)
    if $sec < 60 { return $"($sec)s ago" }
    if $sec < 3600 { return $"($sec / 60 | into int)m ago" }
    if $sec < 86400 { return $"($sec / 3600 | into int)h ago" }
    $"($sec / 86400 | into int)d ago"
}

def color-for-age [age: duration] {
    let sec = ($age / 1sec | into int)
    if $sec < 300 { return "green" }
    if $sec < 3600 { return "yellow" }
    "default_dimmed"
}

def line-count [file: string] {
    try { (open --raw $file | lines | length) } catch { null }
}

def main [
    --stale      # only stale files
    --content    # add T.g4 + input.txt panels below
    --json       # structured output for piping
] {
    cd $env.FILE_PWD

    if not ("T.g4" | path exists) {
        print --stderr (paint red_bold "error: T.g4 not found in current directory")
        exit 1
    }

    let source_mtime = (ls -la T.g4 | first | get modified)
    let now = (date now)

    let files = (
        $TRACKED ++ ((glob *.class) | path basename)
        | each { |f|
            if not ($f | path exists) { return null }
            let stat = (ls -la $f | first)
            let role = (role-of $f)
            {file: $f, role: $role, size: $stat.size, lines: (line-count $f), mtime: $stat.modified, stale: (($role in ["generated" "compiled"]) and ($stat.modified < $source_mtime))}
        }
        | compact
    )

    if $stale {
        let stale_files = ($files | where stale)
        if ($stale_files | is-empty) {
            print --stderr (paint green "all generated/compiled files are fresh")
            return
        }
        print --stderr (paint red_bold "stale files (need regeneration):")
        $stale_files | each { |row| print --stderr $"  (paint red $row.file)" }
        return
    }

    if $json {
        print ($files | to json --indent 2)
        return
    }

    # Default: native Nushell table (rounded box-drawing borders)
    let rows = ($files | each { |row|
        let age = ($now - $row.mtime)
        let role_color = (color-for-role $row.role)
        let age_color = (color-for-age $age)
        let age_str = (human-age $age)
        let size_str = ($row.size | into string)
        let lines_str = (if $row.lines == null or ($row.role == "compiled") { "-" } else { $row.lines | into string })
        let stale_str = (if $row.stale { (paint red "STALE") } else { "ok" })
        let mod_str = ($row.mtime | format date "%H:%M")
        {
            File: (paint $role_color $row.file),
            Role: (paint default_dimmed $row.role),
            Size: $size_str,
            Lines: $lines_str,
            Mod: $mod_str,
            Age: (paint $age_color $age_str),
            Stale: $stale_str
        }
    })

    print ($rows | table)

    if $content {
        print ""
        print --stderr (paint cyan_bold "─── T.g4 ───")
        print (open --raw T.g4)
        print ""
        print --stderr (paint cyan_bold "─── input.txt ───")
        print (open --raw input.txt)
    }
}
