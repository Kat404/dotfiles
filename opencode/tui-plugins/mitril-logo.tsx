// @ts-nocheck
/** @jsxImportSource @opentui/solid */
import type { TuiPlugin } from "@opencode-ai/plugin/tui"
import { useTerminalDimensions } from "@opentui/solid"
import { createMemo } from "solid-js"

const id = "mitril-eye-logo"

// Toggle to switch between multi-color and single-color variants.
// multi: per-character fg via <span style={{fg, bg}}>
// mono:  single fg for entire logo (rose-style fallback)
const MODE: "multi" | "mono" = "multi"
const MONO_COLOR = "#a02525" // wine/lava red — fallback fg

// Catppuccin-flavoured ramp — wine red center → grey rings → black background.
const SHADE_COLORS: Record<string, { fg?: string; bg: string }> = {
  " ": { bg: "#11111b" },
  "█": { fg: "#a02525", bg: "#11111b" }, // wine red centre
  "▓": { fg: "#45475a", bg: "#11111b" }, // dark grey rim
  "▒": { fg: "#7f849c", bg: "#11111b" }, // mid grey iris
  "░": { fg: "#a6adc8", bg: "#11111b" }, // light grey sclera
}

// COSMIC — symmetric surveillance eye. 18 lines × 70 cols.
const COSMIC: readonly string[] = [
  "          ▓▒                      ▒▒                      ▒▓          ",
  "   ▓▒     ▒                       ▒▒                       ▒     ▒▓   ",
  "   ▒       ▒▒     ▓▒                              ▒▓     ▒▒       ▒   ",
  "            ░▒▒   ▒       ░░░░░░░░░░░░░░░░░░       ▒   ▒▒░            ",
  "                   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                    ",
  "               ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░               ",
  "            ░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░            ",
  "           ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒░░░░░░░░░           ",
  "          ░░░░░░░░░▒▒▒▒▒▒▒▒▓▓▓▓████████▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░          ",
  "▒░░▒▒▒    ░░░░░░░░▒▒▒▒▒▒▒▒▓▓▓████████████▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░    ▒▒▒░░▒",
  "          ░░░░░░░░░▒▒▒▒▒▒▒▒▓▓▓▓████████▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░          ",
  "           ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒░░░░░░░░░           ",
  "            ░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░            ",
  "               ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░               ",
  "                   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                    ",
  "   ▓▒       ░▒▒           ░░░░░░░░░░░░░░░░░░           ▒▒░       ▒▓   ",
  "   ▒       ▒▒     ▓▒                              ▒▓     ▒▒       ▒   ",
  "          ▓▒      ▒               ▒▒               ▒      ▒▓           ",
]

// MONO — single-color fallback. Identical shape, gradient via char density only.
const MONO: readonly string[] = [
  "          ▓▒                      ▒▒                      ▒▓          ",
  "   ▓▒     ▒                       ▒▒                       ▒     ▒▓   ",
  "   ▒       ▒▒     ▓▒                              ▒▓     ▒▒       ▒   ",
  "            ░▒▒   ▒       ░░░░░░░░░░░░░░░░░░       ▒   ▒▒░            ",
  "                   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                    ",
  "               ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░               ",
  "            ░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░            ",
  "           ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒░░░░░░░░░           ",
  "          ░░░░░░░░░▒▒▒▒▒▒▒▒▓▓▓▓████████▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░          ",
  "▒░░▒▒▒    ░░░░░░░░▒▒▒▒▒▒▒▒▓▓▓████████████▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░    ▒▒▒░░▒",
  "          ░░░░░░░░░▒▒▒▒▒▒▒▒▓▓▓▓████████▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░          ",
  "           ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒░░░░░░░░░           ",
  "            ░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░            ",
  "               ░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░               ",
  "                   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                    ",
  "   ▓▒       ░▒▒           ░░░░░░░░░░░░░░░░░░           ▒▒░       ▒▓   ",
  "   ▒       ▒▒     ▓▒                              ▒▓     ▒▒       ▒   ",
  "          ▓▒      ▒               ▒▒               ▒      ▒▒           ",
]

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
  const _term = dim()

  if (MODE === "mono") {
    // Single fg color — same approach as gentle-ai's rose logo.
    // The <text> element accepts fg directly; bg on text also works.
    return (
      <box flexDirection="column" alignItems="center">
        {MONO.map((line, y) => (
          <text key={y} fg={MONO_COLOR} bg="#11111b">
            {line}
          </text>
        ))}
      </box>
    )
  }

  // Multi-color — per-character fg via <span style={{fg, bg}}>.
  return (
    <box flexDirection="column" alignItems="center">
      {COSMIC.map((line, y) => (
        <text key={y}>
          {splitLine(line).map((run, x) => {
            const c = SHADE_COLORS[run.shade] ?? { bg: "#11111b" }
            return (
              <span key={x} style={{ fg: c.fg, bg: c.bg }}>
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
