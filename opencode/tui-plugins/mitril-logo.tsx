// @ts-nocheck
/** @jsxImportSource @opentui/solid */
import type { TuiPlugin } from "@opencode-ai/plugin/tui"
import { useTerminalDimensions } from "@opentui/solid"
import { createMemo } from "solid-js"

const id = "mitril-eye-logo"

// Catppuccin Mocha — 5-step halftone ramp mapped to shade characters.
// Darker pixels → cooler/darker greys; lighter pixels → Catppuccin accents.
const SHADE_COLORS: Record<string, { fg?: string; bg: string }> = {
  " ": { bg: "#11111b" },                 // pupil → Crust (deep void)
  "█": { fg: "#45475a", bg: "#11111b" },  // pupil rim → Surface1 (dark grey)
  "▓": { fg: "#89b4fa", bg: "#11111b" },  // inner iris → Blue (Catppuccin accent)
  "▒": { fg: "#b4befe", bg: "#11111b" },  // mid iris → Lavender
  "░": { fg: "#cdd6f4", bg: "#11111b" },  // outer sclera → Text (lightest glow)
}

// COSMIC — central surveillance eye + scattered constellation of micro-eyes.
// 18 lines × 70 cols — fits in most TUI splash areas.
const COSMIC: readonly string[] = [
  "          ▓▒                       ▒                      ▓▒          ",
  "   ▓▒     ▒           ▓▒           ▓              ▓▒      ▒           ",
  "   ▒       ░    ▓▒    ▒ ▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒▒▒   ▒        ░      ▓▒",
  "            ▒▓  ▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒   ▓▒       ▒   ",
  "    ▓▒      ▒▒▓▒░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒ ▓▒        ",
  "    ▒    ▒▒▒░░▒░░░▒▒▒▒▓▒▒▒▓▒▒▒▓▒▒▒▓▓▓▓▓▓▓▓▓▒▒▒▒▓▒▒▒▓▒░░░░░▒▒▒    ▓▒  ",
  "       ▒▒░░░░░░▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒░░░░░░▒▒  ▒   ",
  "      ▒▒░░░░░▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░▒▒     ",
  "     ▒▒░░░░░▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓████       ████▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒░░░░░▒▒    ",
  "▒▓▓▓ ▒▒░░░░▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓███           ███▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░▒▒ ▓▓▓  ",
  "     ▒▒░░░░░▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓████       ████▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒░░░░░▒▒    ",
  "      ▒▒░░░░░▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░▒▒     ",
  "   ▓▒  ▒▒░░░░░░▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▓▒▒▒▒▒░░░░░░▒▒  ▓▒  ",
  "   ▒     ▒▒▒░░░░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▓▒▒▒    ▒   ",
  "          ▓▒▒▒▒░▒░░░░░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒       ▓▒  ",
  "          ▒ ▒▓   ▒▒▒░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒   ▓▒       ▒   ",
  "     ▓▒    ░    ▓▒      ▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒▒▒     ▓▒     ░          ",
  "     ▒          ▒                  ▓                ▒         ▓▒      ",
]

// Split a line into runs of contiguous same-shade characters so each run
// becomes a single <span> with its own fg/bg color inside the parent <text>.
function splitLine(line: string): Array<{ shade: string; text: string }> {
  const runs: Array<{ shade: string; text: string }> = []
  let cur = ""
  let curShade = ""
  for (const ch of line) {
    if (curShade !== "" && ch === curShade) {
      cur += ch
    } else {
      if (cur) runs.push({ shade: curShade, text: cur })
      curShade = ch
      cur = ch
    }
  }
  if (cur) runs.push({ shade: curShade, text: cur })
  return runs
}

const Logo = () => {
  const dim = useTerminalDimensions()
  // No text fallback — always render the eye. Will visibly clip on tiny terminals,
  // but the user has already chosen visual fidelity over a generic compact glyph.
  const _term = dim()
  return (
    <box flexDirection="column" alignItems="center">
      {COSMIC.map((line, y) => (
        <text key={y}>
          {splitLine(line).map((run, x) => {
            const c = SHADE_COLORS[run.shade] ?? { bg: "#11111b" }
            return (
              <span key={x} fg={c.fg} bg={c.bg}>
                {run.text}
              </span>
            )
          })}
        </text>
      ))}
    </box>
  )
}

const tui: TuiPlugin = async (api) => {
  api.slots.register({
    id,
    order: 100,
    slots: {
      home_logo() {
        return <Logo />
      },
    },
  })
}

const plugin = { id: "mitril-eye-logo", tui }
export default plugin
