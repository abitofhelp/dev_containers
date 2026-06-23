//! Teensy 4.1 Rust smoke example.
//!
//! This is intentionally close to the upstream teensy4-rs template, but it
//! selects `board::t41` instead of the template's default Teensy 4.0 alias.
//! It blinks the onboard LED on pin 13 and emits log messages over USB.

#![no_std]
#![no_main]

use teensy4_panic as _;

#[rtic::app(device = teensy4_bsp, peripherals = true, dispatchers = [KPP])]
mod app {
    use bsp::board;
    use imxrt_log as logging;
    use rtic_monotonics::systick::{Systick, *};
    use teensy4_bsp as bsp;

    // Teensy 4.1 / NXP i.MX RT1062 board resources.
    use board::t41 as my_board;

    #[shared]
    struct Shared {}

    #[local]
    struct Local {
        led: board::Led,
        poller: logging::Poller,
    }

    #[init]
    fn init(cx: init::Context) -> (Shared, Local) {
        let board::Resources {
            mut gpio2,
            pins,
            usb,
            ..
        } = my_board(cx.device);

        let led = board::led(&mut gpio2, pins.p13);
        let poller = logging::log::usbd(usb, logging::Interrupts::Enabled).unwrap();

        Systick::start(
            cx.core.SYST,
            board::ARM_FREQUENCY,
            rtic_monotonics::create_systick_token!(),
        );

        blink::spawn().unwrap();
        (Shared {}, Local { led, poller })
    }

    #[task(local = [led])]
    async fn blink(cx: blink::Context) {
        let mut count = 0u32;

        loop {
            cx.local.led.toggle();
            Systick::delay(500.millis()).await;
            log::info!("Hello from Teensy 4.1 Rust. Count={count}");
            count = count.wrapping_add(1);
        }
    }

    #[task(binds = USB_OTG1, local = [poller])]
    fn log_over_usb(cx: log_over_usb::Context) {
        cx.local.poller.poll();
    }
}
