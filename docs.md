# Gaming Mode HDMI

## Problem

Standalone Gamescope works on the laptop display but produces severe partial-frame corruption and flashing on the Panasonic TV over HDMI. Hyprland drives the same HDMI connection correctly.

The HDMI connector is physically attached to the NVIDIA GeForce RTX 3050 Ti Laptop GPU. Gamescope selects the NVIDIA Vulkan device, `/dev/dri/card1`, `HDMI-A-1`, and a progressive 1920x1080 60 Hz mode. The DRM link reports no transport errors, and the TV does not support VRR.

This points to the NVIDIA DRM/KMS scanout path used by standalone Gamescope rather than the cable, TV mode, Steam rendering, or HDMI link.

## Current HDMI Configuration

The HDMI branch selects the NVIDIA device and output, disables VRR, G-SYNC, asynchronous flips, hardware planes, and direct scanout.

The current configuration uses NVIDIA for both Gamescope rendering and HDMI scanout at 1920x1080 60 Hz. Intel composition was considered but rejected because cross-GPU copies and accidental iGPU game rendering are unacceptable for this gaming session.

The currently installed test combination is Gamescope 3.16.31, NVIDIA 615.71.09, and kernel 7.2.5-3-omarchy. The NVIDIA DKMS module was built for the running kernel and the loaded module reports 615.71.09.

Color management was disabled as an experiment and made no visible difference, so that option was removed.

A 1920x1079 internal render size was tested because similar NVIDIA embedded-mode failures have been fixed by avoiding an exact render/output size match. It made no visible difference and was removed.

The TV reports 1080p50 as its preferred timing. Exact 1920x1080 rendering at 50 Hz produced the same severe corruption and was removed.

Exact 1280x720 rendering at 60 Hz produced the same severe corruption. This rules out 1080p framebuffer dimensions and HDMI bandwidth as the cause.

Disabling Gamescope DRM explicit synchronization made no visible difference and was removed.

Updating Gamescope from 3.16.28 to 3.16.31 while retaining NVIDIA 610.57.04 made no visible difference. Updating the complete NVIDIA package set from 610.57.04 to 615.71.09 while retaining Gamescope 3.16.31 also made no visible difference. The corruption remained the same in both tests.

The TV had 16:9 overscan enabled, which cropped interface elements at the edge of the image. Disabling overscan restored the correct image geometry but did not address the separate flashing problem.

## Evidence

- [Gamescope issue 599](https://github.com/ValveSoftware/gamescope/issues/599) reports NVIDIA embedded-mode flickering when render and output resolutions match. Changing one dimension by one pixel fixed it for multiple users.
- [Gamescope issue 669](https://github.com/ValveSoftware/gamescope/issues/669) reports native-resolution NVIDIA corruption affecting a large portion of the display.
- [Gamescope issue 1964](https://github.com/ValveSoftware/gamescope/issues/1964) reports partial-frame corruption and stale framebuffer content under standalone Gamescope. Forced composition did not reliably fix it.
- [NVIDIA forum report](https://forums.developer.nvidia.com/t/display-modes-above-2560x1440p-120hz-with-hdr-enabled-cause-flickering-corruption-within-gamescope-session/295314) reports clean captures while the physical output is corrupted, placing the failure in or below the NVIDIA KMS scanout path.

## Version Test Results

The two forward-version tests are exhausted:

1. Gamescope 3.16.31 with NVIDIA 610.57.04 produced the same corruption.
2. Gamescope 3.16.31 with NVIDIA 615.71.09 produced the same corruption.

The matching NVIDIA package set was changed together, including `nvidia-open-dkms`, `nvidia-utils`, and `lib32-nvidia-utils`. The DKMS build completed successfully and the loaded module version was verified after reboot.

The Omarchy stable mirror still offered Gamescope 3.16.28 and NVIDIA 610.57.04 during these tests. Gamescope 3.16.31 and NVIDIA 615.71.09 were installed explicitly from the Arch Linux Archive.

The repository installer requires an interactive terminal because it uses `sudo`:

```bash
./install-gaming.sh
sudo systemctl restart sddm
```

Restarting SDDM immediately terminates the current graphical session.

## Remaining Options

The session must remain standalone Gamescope. A nested Gamescope session under Hyprland was previously tested and rejected because it behaved like a desktop monitor rather than a console-style gaming session. Do not propose it again.

Remaining experiments, in order of usefulness:

1. Test the mature NVIDIA 580.119.02 package set with Gamescope 3.16.31.
2. Test standalone Gamescope on another HDMI display to determine whether the Panasonic EDID or timing triggers the NVIDIA KMS bug.
3. Report the reproducible failure upstream with the tested version matrix and existing session logs.
4. Start Gaming Mode directly after a cold boot with the TV connected and powered on, without switching virtual terminals, suspending, or reconnecting HDMI.

Do not continue adding launcher flags. Gamescope 3.16.28 and 3.16.31, NVIDIA 610.57.04 and 615.71.09, multiple output modes, and the major scanout controls all produce the same failure. The evidence continues to point to an incompatibility in standalone Gamescope's NVIDIA DRM/KMS scanout path rather than defective TV or HDMI hardware.

Forcing linear DRM modifiers or disabling atomic modesetting is not recommended. Gamescope has no supported legacy-KMS mode, and upstream reports show that forced linear buffers can make this corruption worse.
