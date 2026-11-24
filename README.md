# Fluid Lights

Omarchy shell plugin that controls the backlight of Akko / RongYuan
keyboards (USB vendor `3151`) from the top bar, and keeps it in sync with
the active Omarchy theme.

- **Bar icon** tinted with the colour the keyboard is showing.
- **Left click**: picker with the theme's colours, a fixed `#rrggbb` field,
  brightness (1–4) and on/off.
- **Middle click**: backlight on/off. **Wheel**: brightness.
- **Follow theme**: when on, every theme change re-colours the keyboard
  with the chosen theme role (`accent` by default). It runs from Omarchy's
  `theme-set` hook, so it works with `omarchy theme set`, the theme
  switcher and Aether alike.

Tested on the Akko "Multi-modes Keyboard-B" (`3151:4003`). `3151:4002` and
`3151:5002` use the same lighting frame and are enabled but untested.

## Install

```bash
git clone https://github.com/markosAMO/fluid-lights.git
cd fluid-lights
./install.sh
```

`install.sh` asks for sudo once to install
`/etc/udev/rules.d/70-fluid-lights.rules`, which gives the logged-in user
access to the keyboard's hidraw node. Everything else lives under your home.

## CLI

The bar drives `fluid-lights`, which you can also use directly:

```bash
fluid-lights theme            # follow the theme accent
fluid-lights theme magenta    # follow another theme role
fluid-lights set '#ff8800'    # fixed colour
fluid-lights brightness 2     # 0-4, or + / -
fluid-lights off | on | toggle
fluid-lights status           # JSON
```

State is kept in `~/.local/state/fluid-lights/state.json`.

## Protocol

Lighting is a 64-byte HID feature report (report ID 0) sent to the
keyboard's vendor collection (usage page `0xFFFF`), even though that
collection's descriptor only declares an input report:

```
[0x07, mode, 5 - speed, brightness, flags, R, G, B, 0xFF - (sum & 0xFF)]
```

On the `3151:4003`, mode `1` with flags `0x08` is a solid colour and `0x07`
is rainbow. Other boards swap the nibble; override it with
`KBD_COLOR_FLAGS=0x07`. Writes are spaced at least 1 s apart.

Do not send these frames to the keyboard collection (interface 0): the board
stalls its USB control endpoint and ignores every report until it is
unplugged. If `fluid-lights` says the keyboard stopped answering, unplug it,
wait ten seconds and plug it back in.

Protocol notes come from
[sharkfin](https://github.com/dniminenn/sharkfin/blob/master/docs/PROTOCOL.md)
and [akko-5075-rgb](https://github.com/roziscoding/akko-5075-rgb).

## Uninstall

```bash
./uninstall.sh
```
