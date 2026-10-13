# tuios-omalauncher

An agent multiplexer for [omalauncher](https://github.com/SimonSchubert/omarchy-widgets)'s home screen,
built on [tuios](https://github.com/Gaurav-Gosain/tuios). One tile runs Claude Code, Oh My Pi or any
other agent in tabs that keep running, with an inbox of every agent and Android notifications.

- **Tabs** for each agent in `~/.config/omalauncher/agents.conf` (`name = command` per line). **+** opens
  another (two Claude sessions side by side), **×** closes one, asking first when it runs something.
  Each tab is a tuios window on its own workspace, so switching tabs never stops anything.
- **Sessions survive the tile.** The widget starts the tuios daemon from the launcher's own long-lived
  shell; the tile's terminal only attaches. Restarting or editing the tile keeps every session.
- **Inbox:** every agent tuios sees, in every session, with its state (working, needs you, done,
  errored) and its last message. Tap one to jump to its tab.
- **Notifications:** tuios's `after-agent-state` hook reaches the widget through `owl-send`, and the
  widget posts an Android notification when an agent needs you, errors or finishes.
- **Scrolling:** drag up or down on the terminal (sideways drags are left alone), or **▲ ▼ ⤓**. These
  press tuios's shift+up/down, which scroll the pane's history and never reach the program as text.
  **☰ read** swaps in a native, swipeable copy of the last 200 lines.
- **⧉** moves a Claude session out of the tile into its own window (`claude --resume` there).
- **⚙ settings:** the tuios version with check and update buttons, notifications on or off, and the
  agents list.

## Install

In omalauncher's Linux terminal:

```sh
git clone https://github.com/nkapila6/tuios-omalauncher
cd tuios-omalauncher && ./install.sh
```

It installs tuios's latest release (checked against the release's checksums) into `~/.local/bin`,
`tuios-omalauncher` beside it, the widget as `~/.config/omalauncher/widgets/36-tuios.owl`, a starter
`agents.conf`, and the notification hook in `~/.config/tuios/config.toml`.

## How it works

`bin/tuios-omalauncher` is the Linux side; the widget calls it for everything (`start`, `tab`, `close`,
`scroll`, `read`, `status`, `inbox`, `port`, `update`, `notify-hook`). Run it with no arguments for
the list.

omalauncher runs each terminal tile, and each widget command, in its own proot sandbox, and stops a
tile's terminal while the tile is hidden. tuios suits that: its daemon's socket is guarded by file
permissions, which every sandbox passes, and a daemon started from the launcher's command shell lives
as long as the launcher. (tmux checks the connecting process's real uid instead, which differs across
sandboxes, so a tile's tmux could only be driven from inside its own sandbox.)

Claude Code runs with `--settings '{"tui":"default"}'`: its fullscreen renderer takes the mouse and
does its own scrolling, which a tile can't reach.

## License

MIT
