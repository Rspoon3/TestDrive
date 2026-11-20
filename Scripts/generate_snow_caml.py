#!/usr/bin/env python3
"""Generates the bundled snow scenes in TestDrive/CAMLSnow.

Each file is a Core Animation Markup Language (.caml) scene: five CAEmitterLayers (one per depth band) with wave and
drag behaviors, authored in a 390 x 844 design space. The numbers come from the same formulas as `SnowFlake` and
`SnowLayerStyle`, so the scenes match the other snow implementations. Sprites are not in the files: the app assigns each
cell's image by name (`flake0` ... `flake4`) after loading.

    python3 Scripts/generate_snow_caml.py
"""
import os

WIDTH, HEIGHT, OVERSHOOT, DRAG = 390.0, 844.0, 20.0, 1.0
BANDS = 5

# name: (flakeCount, speedMultiplier, windStrength, windDrift) -- mirrors SnowfallConfiguration.
CONFIGS = {
    "snow-gentle": (70, 0.7, 20.0, 0.0),
    "snow-medium": (140, 1.0, 40.0, 0.0),
    "snow-blizzard": (700, 2.4, 200.0, 320.0),
}


def bands():
    for i in range(BANDS):
        near, far = i / BANDS, (i + 1) / BANDS
        nb, fb = near * near, far * far
        mid = (nb + fb) / 2
        yield {
            "size": 2 + mid * 12,
            "size_range": (fb - nb) * 12 / 2,
            "speed": 22 + mid * 90,
            "opacity": 0.35 + mid * 0.5 + 0.075,
            "wind": 0.3 + mid * 0.7,
        }


def emitter(index, band, config):
    count, speed_mult, wind_strength, wind_drift = config
    speed = band["speed"] * speed_mult
    travel_height = HEIGHT + OVERSHOOT
    fall_time = travel_height / speed * 1.15
    drift = wind_drift * band["wind"]
    drift_travel = abs(drift) * fall_time
    width = WIDTH + drift_travel
    center_x = WIDTH / 2 - (drift_travel if drift >= 0 else -drift_travel) / 2
    birth_rate = (count / BANDS) * speed / travel_height * width / WIDTH
    # CGImage sprites are 32 pt; the app sets the image, so scale is relative to that.
    scale = band["size"] / 32
    scale_range = band["size_range"] / 32
    sway = wind_strength * band["wind"]
    return f"""      <CAEmitterLayer id="band{index}" name="band{index}" bounds="0 0 {WIDTH:g} {HEIGHT:g}" position="{WIDTH / 2:g} {HEIGHT / 2:g}" emitterShape="line" emitterMode="volume" renderMode="unordered" emitterPosition="{center_x:.3f} -10" emitterSize="{width:.3f} 1">
        <emitterCells>
          <CAEmitterCell name="flake{index}" birthRate="{birth_rate:.4f}" lifetime="{fall_time:.4f}" scale="{scale:.5f}" scaleRange="{scale_range:.5f}" xAcceleration="{drift * DRAG:.4f}" yAcceleration="{speed * DRAG:.4f}">
            <color value="1 1 1" opacity="{band['opacity']:.4f}"/>
          </CAEmitterCell>
        </emitterCells>
        <emitterBehaviors>
          <CAEmitterBehavior behavior="wave" force="{sway:.4f} 0 0" frequency="0.3"/>
          <CAEmitterBehavior behavior="wave" force="{sway * 0.375:.4f} 0 0" frequency="0.9"/>
          <CAEmitterBehavior behavior="drag" drag="{DRAG:g}"/>
        </emitterBehaviors>
      </CAEmitterLayer>"""


def scene(config):
    layers = "\n".join(emitter(i, b, config) for i, b in enumerate(bands()))
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<caml xmlns="http://www.apple.com/CoreAnimation/1.0">
  <CALayer id="root" name="snow" bounds="0 0 {WIDTH:g} {HEIGHT:g}" position="{WIDTH / 2:g} {HEIGHT / 2:g}">
    <sublayers>
{layers}
    </sublayers>
  </CALayer>
</caml>
"""


if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__), "..", "TestDrive", "CAMLSnow")
    os.makedirs(out_dir, exist_ok=True)
    for name, config in CONFIGS.items():
        with open(os.path.join(out_dir, f"{name}.caml"), "w") as handle:
            handle.write(scene(config))
        print("wrote", name)
