# Rust Embedded Support

This document describes the embedded Rust support provided by
`dev-container-rust`, with PJRC Teensy 4.1 as the first board-specific
workflow.

The image is intentionally split into two levels of support:

1. **Generic Rust embedded targets** for Cortex-M and ARM Linux work.
2. **Board-specific workflow support** for targets that need extra tools,
   linker scripts, BSP crates, and flashing conventions.

Teensy 4.1 is currently the board-specific Rust workflow in this repository.

## Installed Rust Targets

| Rust target | Typical hardware | ABI / runtime | Notes |
|-------------|------------------|---------------|-------|
| `thumbv6m-none-eabi` | Cortex-M0, Cortex-M0+ | Bare metal, no FPU ABI | Small MCU projects, board-specific HAL required. |
| `thumbv7m-none-eabi` | Cortex-M3 | Bare metal, no FPU ABI | Generic Cortex-M3 support, board-specific HAL required. |
| `thumbv7em-none-eabi` | Cortex-M4 / Cortex-M7 | Bare metal, soft-float ABI | Use when the hardware or project intentionally avoids the hard-float ABI. |
| `thumbv7em-none-eabihf` | Cortex-M4F / Cortex-M7F | Bare metal, hard-float ABI | Teensy 4.1 uses this target. |
| `thumbv8m.main-none-eabihf` | Cortex-M33-class MCUs | Bare metal, hard-float ABI | Common for newer TrustZone-capable Cortex-M devices. |
| `armv7-unknown-linux-gnueabihf` | ARMv7 Linux boards | Linux userspace, hard-float ABI | Use for applications running under Linux, not bare metal. |

The `thumb*` targets only provide Rust's core/compiler target support. They do
not, by themselves, provide startup code, a memory map, peripheral access,
board support, or a flashing method. Those come from the board support crate,
linker script, runner, and hardware-specific loader.

## Teensy 4.1 Support Boundary

The Teensy 4.1 workflow targets the PJRC Teensy 4.1 board with the NXP
i.MX RT1062 ARM Cortex-M7 microcontroller. The Rust build uses:

- `thumbv7em-none-eabihf` as the Rust target.
- `teensy4-bsp` for the runtime, memory layout, and board support.
- `cargo-binutils` / `cargo objcopy` to convert the Rust ELF into Intel HEX.
- `teensy_loader_cli` to program the board from systems with USB access.

This support does **not** make arbitrary Cortex-M7 boards Teensy-compatible.
Other i.MX RT1062 boards may share the same CPU but still need their own board
initialization, pin mapping, memory layout validation, and flash procedure.

## Quick Teensy 4.1 Example

Build the included smoke example inside the Rust container:

```bash
cd rust/examples/teensy41_blink
cargo objcopy --release -- -O ihex teensy41_blink.hex
```

The `.cargo/config.toml` in the example selects `thumbv7em-none-eabihf` and
passes the Teensy 4.x linker script:

```toml
[build]
target = "thumbv7em-none-eabihf"

[target.thumbv7em-none-eabihf]
rustflags = ["-C", "link-arg=-Tt4link.x"]
```

Flash the generated HEX when the host can expose the board to the process:

```bash
teensy_loader_cli --mcu=TEENSY41 -w -v teensy41_blink.hex
```

Press the physical Program button when prompted if the board is not already in
bootloader mode.

## Makefile Smoke Test

From the repository root, build the Teensy 4.1 example in a container:

```bash
make -f rust/Makefile test-teensy41
```

Runtime-specific aliases are also available:

```bash
make -f rust/Makefile test-teensy41-docker
make -f rust/Makefile test-teensy41-podman
```

These targets verify that the image has the expected Rust target,
`cargo objcopy`, and `TEENSY41` loader support, then build a non-empty HEX file.
They intentionally do not flash hardware, because CI and many developer
machines cannot safely expose USB devices to the container.

## Shell Helpers

Inside the Rust container, these zsh helpers are available:

```bash
teensy41_template hello-teensy41
teensy41_hex teensy41_blink.hex
teensy41_flash teensy41_blink.hex
teensy41_build_flash teensy41_blink.hex
```

`teensy41_template` bootstraps from the community Teensy 4 Rust template.
Review the generated project before committing it, because templates can evolve
upstream. For Teensy 4.1, ensure the application uses the Teensy 4.1 board
selection path, for example `board::t41`.

## Host and USB Notes

Building and flashing have different portability characteristics.

| Host setup | Build HEX in container | Flash from container | Recommended flash path |
|------------|------------------------|----------------------|------------------------|
| Linux + Docker/nerdctl | Yes | Usually, with USB device mapping and udev rules | Container or host `teensy_loader_cli` |
| Linux + Podman rootless | Yes | Possible, but USB permissions need care | Host `teensy_loader_cli` for simplest setup |
| macOS + Docker Desktop | Yes | Usually no, because USB is behind Docker's Linux VM | Host PJRC Teensy Loader or host `teensy_loader_cli` |
| Windows + Docker Desktop / WSL | Yes | Environment-dependent | Host PJRC Teensy Loader is usually simplest |

For Linux flashing, install PJRC's Teensy udev rules on the host so non-root
processes can access the USB device. If a container cannot see the device,
copy the generated `.hex` to the host and flash there.

## Cargo Cache and User Identity

The image deliberately separates immutable toolchain state from mutable
project state:

- `/opt/rustup` contains the pinned Rust toolchain and installed targets.
- `/opt/cargo/bin` contains image-provided cargo subcommands such as
  `cargo-objcopy`, `cargo-generate`, and `probe-rs`.
- `${HOME}/.cargo` is the runtime `CARGO_HOME` used for crates.io registry
  cache, git checkouts, and user-installed cargo tools.

This keeps the image reproducible while allowing non-root Docker, Podman, and
rootless users to build bind-mounted projects without writing into `/opt`. For
Docker Desktop on macOS, this also ensures generated Cargo cache files are owned
by the adapted host UID rather than by root.

## Common Failure Modes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `cargo: no such command: objcopy` | `cargo-binutils` missing or image is stale | Rebuild/pull the updated Rust image. |
| Cargo fails with `Permission denied` under `/opt/cargo/registry` | Stale image or entrypoint did not set writable runtime `CARGO_HOME` | Rebuild the image and confirm the smoke test prints `CARGO_HOME=/home/<user>/.cargo`. |
| `can't find crate for core` | Rust target not installed | Verify `rustup target list --installed` includes `thumbv7em-none-eabihf`. |
| Linker cannot find `t4link.x` | BSP/runtime feature or dependency issue | Confirm `teensy4-bsp` has the `rt` feature enabled. |
| Loader waits forever | Board is not in bootloader mode or USB is not visible | Press Program button; check cable and USB device access. |
| Program flashes but USB logging is absent | Host has no serial monitor attached, wrong USB mode, or app crashed early | Confirm the example boots and use a known data-capable USB cable. |

## Adding Another Rust Embedded Board

Use the Teensy 4.1 integration as the pattern, but do not copy it blindly.
A new board should add:

1. The Rust compilation target, if not already installed.
2. Any required system packages or cargo tools, pinned in the Dockerfile.
3. A minimal `no_std` smoke example with explicit `.cargo/config.toml`.
4. A Makefile smoke target that builds an artifact without requiring hardware.
5. Documentation that states the CPU target, board support crate, linker script,
   output format, flash method, and host/USB limitations.
6. Clear boundaries between generic CPU support and validated board support.

Prefer build-only CI smoke tests. Hardware flashing should remain an explicit
manual or lab workflow unless a dedicated hardware-in-the-loop setup exists.
