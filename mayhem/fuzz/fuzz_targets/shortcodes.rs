#![no_main]
use config::Config;
use libfuzzer_sys::fuzz_target;
use markdown::{RenderContext, render_content};

// Drives zola's markdown+shortcode rendering pipeline over arbitrary input.
// render_content() runs the shortcode parser (parse_for_shortcodes — the code path
// the original `shortcodes` target fuzzed) and the full markdown-to-HTML renderer.
fuzz_target!(|data: &str| {
    let config = Config::default_for_test();
    let context = RenderContext::from_config(&config);
    let _ = render_content(data, &context);
});
