# Gaming Mode HDMI

## Problem

Standalone Gamescope works on the laptop display but produces severe partial-frame corruption and flashing on the Panasonic TV over HDMI. Hyprland drives the same HDMI connection correctly.

The HDMI connector is physically attached to the NVIDIA GeForce RTX 3050 Ti Laptop GPU. Gamescope selects the NVIDIA Vulkan device, `/dev/dri/card1`, `HDMI-A-1`, and a progressive 1920x1080 60 Hz mode. The DRM link reports no transport errors, and the TV does not support VRR.

This points to the NVIDIA DRM/KMS scanout path used by standalone Gamescope rather than the cable, TV mode, Steam rendering, or HDMI link.

## Current HDMI Configuration

The HDMI branch selects the NVIDIA device and output, disables VRR, G-SYNC, asynchronous flips, hardware planes, and direct scanout.

The physical output remains 1920x1080. The internal Gamescope render size is 1920x1079. This one-pixel mismatch avoids an NVIDIA embedded-mode failure reported when the internal render size exactly matches the output size. Gamescope scales the internal image to the physical 1920x1080 output.

Color management was disabled as an experiment and made no visible difference, so that option was removed.

## Evidence

- [Gamescope issue 599](https://github.com/ValveSoftware/gamescope/issues/599) reports NVIDIA embedded-mode flickering when render and output resolutions match. Changing one dimension by one pixel fixed it for multiple users.
- [Gamescope issue 669](https://github.com/ValveSoftware/gamescope/issues/669) reports native-resolution NVIDIA corruption affecting a large portion of the display.
- [Gamescope issue 1964](https://github.com/ValveSoftware/gamescope/issues/1964) reports partial-frame corruption and stale framebuffer content under standalone Gamescope. Forced composition did not reliably fix it.
- [NVIDIA forum report](https://forums.developer.nvidia.com/t/display-modes-above-2560x1440p-120hz-with-hdr-enabled-cause-flickering-corruption-within-gamescope-session/295314) reports clean captures while the physical output is corrupted, placing the failure in or below the NVIDIA KMS scanout path.

## Next Test

Install the repository configuration, restart SDDM, enter Gaming Mode with HDMI connected, and check whether the corruption is gone.

The repository installer requires an interactive terminal because it uses `sudo`:

```bash
./install-gaming.sh
sudo systemctl restart sddm
```

Restarting SDDM immediately terminates the current graphical session.

## Fallbacks

If the 1920x1079 workaround fails, the preferred fallback is a dedicated minimal Hyprland session running fullscreen Gamescope with the Wayland backend. Hyprland would own the known-good NVIDIA HDMI scanout path while Gamescope would continue to own Steam and games.

Other experiments, in order of usefulness:

1. Start Gaming Mode directly after a cold boot with the TV connected and powered on, without first entering Hyprland, switching virtual terminals, suspending, or reconnecting HDMI.
2. Test a compatible Gamescope and NVIDIA driver version matrix. The current versions are Gamescope 3.16.28 and NVIDIA 610.57.04.
3. Investigate Gamescope DRM explicit synchronization only if logs report flip timeouts, sync-FD semaphore failures, or related NVIDIA DRM errors.

Forcing linear DRM modifiers or disabling atomic modesetting is not recommended. Gamescope has no supported legacy-KMS mode, and upstream reports show that forced linear buffers can make this corruption worse.
