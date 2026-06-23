# Teensy 4.1 Rust Blink Example

This example targets the PJRC Teensy 4.1 / NXP i.MX RT1062 ARM Cortex-M7 board.
It uses Rust `no_std`, `teensy4-bsp`, RTIC, USB logging, and the
`thumbv7em-none-eabihf` Rust target.

The example is intentionally small enough to act as a container smoke test, but
it is also a useful first hardware check: it toggles the onboard LED on pin 13
and emits log messages over USB.

## Build a HEX File

From this directory, inside the Rust container:

```bash
cargo objcopy --release -- -O ihex teensy41_blink.hex
```

This produces `teensy41_blink.hex` from the release ELF.

You can also run the repository-level smoke test from the repository root:

```bash
make -f rust/Makefile test-teensy41
```

The smoke test verifies the installed Rust target, `cargo objcopy`, loader MCU
support for `TEENSY41`, and that the example produces a non-empty HEX file.
It does not flash hardware.

## Flash the Board

When the board is visible to the process running the loader:

```bash
teensy_loader_cli --mcu=TEENSY41 -w -v teensy41_blink.hex
```

Press the Teensy Program button when prompted if the board is not already in
bootloader mode.

Host expectations:

| Host setup | Recommended flash path |
|------------|------------------------|
| Linux with USB device access | Container or host `teensy_loader_cli` |
| macOS with Docker Desktop | Build in the container; flash from macOS with PJRC Teensy Loader or host `teensy_loader_cli` |
| Windows / WSL | Build in the container; flash from Windows with PJRC Teensy Loader unless USB passthrough is known-good |

On Linux hosts, install PJRC's Teensy udev rules so non-root processes can
access the USB device. Use a data-capable USB cable; charge-only cables are a
common source of confusing loader failures.

## Project Configuration

`.cargo/config.toml` selects the Teensy 4.1 Rust target and linker script:

```toml
[build]
target = "thumbv7em-none-eabihf"

[target.thumbv7em-none-eabihf]
rustflags = ["-C", "link-arg=-Tt4link.x"]
```

`Cargo.toml` enables the `teensy4-bsp` runtime feature so the linker script and
startup path are available.

## Generate a Fresh Upstream Project

Inside the Rust container:

```bash
teensy41_template hello-teensy41
cd hello-teensy41
# For Teensy 4.1, ensure the board selection uses board::t41.
teensy41_build_flash hello-teensy41.hex
```

Review generated template projects before committing them. The template is a
community-maintained starting point and may evolve independently of this
container repository.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `cargo: no such command: objcopy` | Old Rust image or missing `cargo-binutils` | Rebuild or pull the updated Rust image. |
| `can't find crate for core` | Target not installed | Check `rustup target list --installed` for `thumbv7em-none-eabihf`. |
| Linker cannot find `t4link.x` | BSP runtime feature missing | Ensure `teensy4-bsp` has feature `rt` enabled. |
| Loader waits forever | Board not in bootloader mode or USB not visible | Press Program; check host USB access and cable. |
| Flash succeeds but no logs appear | No USB serial monitor, wrong cable, or early panic | Try the LED first, then inspect USB serial/log setup. |
