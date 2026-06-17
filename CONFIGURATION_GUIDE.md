# Configuring a Greenhouse — Step‑by‑Step Guide

This guide explains how to set up a greenhouse so it measures and controls its
environment correctly. Read it once before your first configuration; after that
the worked examples at the end are usually all you need.

---

## The three building blocks

Configuration has three parts. They build on each other, so set them up **in
this order**:

| # | Part | Answers the question | Where in the app |
|---|------|----------------------|------------------|
| 1 | **Parameters** | *What do I want to measure or control?* (e.g. temperature) | Control Panel → *Add parameter* |
| 2 | **Devices** | *What hardware is physically attached?* (e.g. a DHT22 sensor on pin 12, a heater on pin 0) | Greenhouse menu → *Configure devices* |
| 3 | **Mappings** | *How do the devices keep a parameter at its target?* (e.g. "use the DHT22 to read temperature and the heater to raise it") | Greenhouse menu → *Configure mappings* |

A simple way to remember it:

> **Parameter** = the *goal*  ·  **Device** = the *hardware*  ·  **Mapping** = the *rule* that connects them.

After changing devices or mappings you must **Save & Push**. The board saves the
new file and **reboots** to apply it (this takes a few seconds), then comes back
online.

---

## Step 1 — Define your parameters

A parameter is one thing you care about: `temperature`, `humidity`,
`soil_moisture`, `light`, …

When you add a parameter you set:

| Field | Meaning | Example |
|-------|---------|---------|
| **Name** | A unique label within its scope | `temperature` |
| **Type** | `VALUE` (a number, e.g. degrees) or `TOGGLE` (on/off, e.g. a lamp) | `VALUE` |
| **Unit** | Display unit (free text) | `°C` |
| **Min / Max** | The range you are allowed to *request*. This is also the safe range the board clamps to. | `10` / `40` |
| **Mutable** | On if you can control it (it has an actuator). Off for read‑only sensors. | on |

> **Tip:** set Min/Max to the real‑world range you want to operate in (e.g.
> 10–40 °C). These are the same units you'll use everywhere else for this
> parameter — including hysteresis (see Step 3).

Parameters can live at three **scopes**: the whole greenhouse, a single zone, or
a single flowerpot. Pick the scope that matches where the thing is measured.

---

## Step 2 — Add your devices

A device is one piece of physical hardware wired to the board. List every sensor
and actuator you have.

| Field | Meaning | Example |
|-------|---------|---------|
| **Name** | A label so you recognise it later (purely for display) | `Air DHT22` |
| **Driver** | How the board talks to it: `digital` (relays, simple sensors, actuators), `dht22` (temp/humidity sensor), `muxAnalog` (analog sensor behind a multiplexer) | `dht22` |
| **Type** | For digital devices: `value` (a sensor/regulated output) or `toggle` (simple on/off) | `value` |
| **Pin** | The GPIO pin it's wired to | `12` |
| **Min / Max** *(optional)* | Informational only | — |

When you **Save & Push**, the server assigns each device a stable **id** and
sends the list back to the app. Mappings reference devices by this id, so:

> **Always Save & Push your devices before creating mappings.** A device only
> becomes selectable in a mapping after it has been saved (that's when it gets
> its id). You can rename a device later without breaking any mapping — the link
> is the id, not the name.

---

## Step 3 — Create mappings (the control rules)

A mapping ties **one parameter** to the hardware that reads and/or drives it, and
defines the control behaviour. A mapping has up to three sections.

### 3a. Parameter (required)
Choose the **scope** (greenhouse / zone / flowerpot), then the **parameter**
this rule controls.

### 3b. Read sensor (optional)
Turn this on if a sensor measures the parameter.

| Field | Meaning |
|-------|---------|
| **Device** | The sensor device (from Step 2) |
| **Mux channel / Selector pins** | Only for `muxAnalog` devices — which channel on the multiplexer this sensor uses, and the selector GPIOs |

> A mapping with **no read sensor** is *open‑loop*: the board can't measure the
> value, so it just applies your requested setting directly (e.g. a lamp you
> turn on/off manually).

### 3c. Write actuator (optional)
Turn this on if a device acts to change the parameter.

| Field | Meaning | Typical value |
|-------|---------|---------------|
| **Device** | The actuator (a `digital` device) | `Main Heater` |
| **Direction** | `increase` = the actuator *raises* the value (heater, humidifier). `decrease` = it *lowers* the value (fan, cooler). | `increase` |
| **Hysteresis** | Dead‑band around the target, **in the parameter's own units** (see below) | `2` (= 2 °C) |
| **Active low** | On if the relay turns the device ON with a LOW signal (common for relay boards) | off |
| **Output mode** | `binary` (plain on/off) or `pwm` (proportional speed/power) | `binary` |
| **Min on / Min off (ms)** | Anti‑short‑cycle: the minimum time the device must stay on/off before switching again. Protects compressors/pumps. | `60000` (= 60 s) |

### 3d. Analog scaling (optional)
Only needed for raw analog sensors (e.g. `muxAnalog`) whose readings aren't
already in real units. It linearly converts the raw reading into the
parameter's units.

| Field | Meaning |
|-------|---------|
| **Raw min / Raw max** | The raw range the sensor produces (e.g. `0` … `1024`) |
| **Display min / Display max** | The real‑world range it corresponds to (e.g. `0` … `100` %) |

Raw and display ranges may be **inverted**. Example: a dry soil probe reads
`1024` when dry and `0` when wet, but you want `0 %`…`100 %`, so you set
Raw min = `1024`, Raw max = `0`, Display min = `0`, Display max = `100`.

> DHT22 and other digital sensors already report real units — leave scaling
> **off** for them.

---

## Hysteresis — what value, and in which units?

**Hysteresis is always expressed in the parameter's real (mapped/display) units —
never in the raw sensor range.**

Here's why. On every cycle the board does this in order:

1. Reads the raw sensor value (e.g. `512`).
2. **Applies your analog scaling** → converts it to real units (e.g. `25 °C`).
3. Stores that as the *current value* and compares it to your *requested value*:
   `error = requested − current` (both in °C).
4. Compares that error against **hysteresis** (so hysteresis must be in °C too).

So for your example — a sensor that reads 0–1024, scaled to 10–40 °C —
**hysteresis is in degrees.** `hysteresis: 2` = a 2 °C dead‑band.

### What it does
With a heater (`direction: increase`), target `25 °C`, hysteresis `2`:

- Current drops **below 23 °C** (error > +2) → heater turns **ON**
- Current rises **above 27 °C** (error < −2) → heater turns **OFF**
- Between 23 and 27 °C → no change

That 4 °C window (target ± hysteresis) stops the relay from chattering on and off
around the setpoint.

### Choosing a value
- **Too small** (e.g. `0.1`) → the device switches constantly (rapid cycling).
- **Too large** (e.g. `10`) → the value drifts far from target before correcting.
- **Good starting points:** temperature `1`–`2` °C, humidity `3`–`5` %,
  soil moisture `5`–`10` %.
- Leave it blank to use the board default of **0.5** (in the parameter's units).

### When hysteresis is *not* used
- **TOGGLE** parameters: simply on when requested > 0.5, off otherwise.
- **PWM** output mode: uses proportional control (power scales with the error),
  not a dead‑band.

---

## Worked examples

### A. Temperature regulated by a heater
- **Parameter:** `temperature`, VALUE, unit `°C`, min `10`, max `40`, mutable.
- **Devices:** `Air DHT22` (dht22, pin 12); `Main Heater` (digital, value, pin 0).
- **Mapping:** scope zone → `temperature`
  - Read: `Air DHT22` (no scaling — DHT22 is already in °C)
  - Write: `Main Heater`, direction `increase`, hysteresis `2`,
    min on/off `60000` each.
- **Result:** request 25 °C → heater holds the air between 23 and 27 °C.

### B. Soil moisture (raw analog sensor, read‑only display)
- **Parameter:** `soil_moisture`, VALUE, unit `%`, min `0`, max `100`,
  *not* mutable.
- **Device:** `Soil Mux` (muxAnalog, pin 17).
- **Mapping:** scope flowerpot → `soil_moisture`
  - Read: `Soil Mux`, mux channel `0`, selector pins `14,4,5`
  - Scaling: Raw min `1024`, Raw max `0`, Display min `0`, Display max `100`
  - Write: off (nothing to actuate)
- **Result:** the dry/wet raw value is shown as 0–100 %.

### C. A lamp you switch manually
- **Parameter:** `light`, TOGGLE, mutable.
- **Device:** `Light` (digital, toggle, pin 16).
- **Mapping:** scope zone → `light`
  - Read: off
  - Write: `Light`, output mode `binary`, active low off.
- **Result:** toggling the parameter turns the lamp on/off (no hysteresis, no sensor).

---

## Quick checklist

1. ☐ Add parameters (set realistic Min/Max in real units).
2. ☐ Add every device, then **Save & Push** (wait for the reboot).
3. ☐ Create mappings referencing those devices; set direction + hysteresis in the
   parameter's units; add scaling only for raw analog sensors.
4. ☐ **Save & Push** mappings (wait for the reboot).
5. ☐ Push the model, then set your requested values from the Control Panel.
