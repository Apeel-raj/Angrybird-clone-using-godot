# 2D Angry Birds Clone in Godot 4.6

A fully-featured, physics-based 2D puzzle arcade game inspired by Angry Birds, built using **Godot Engine 4.6 (Forward Plus)**. This repository contains the complete source code, custom procedural audio synthesizers, 12 dynamic levels, and keystore-ready Android build presets.

---

## 🎮 Features

- **Stable Stacked Physics**: Built using optimized rigid body parameters for realistic structural toppling, block slide, and impact destruction.
- **Dynamic Launch Mechanics**: Smooth click-and-drag slingshot system with ground queue representation of remaining bird ammo and transition slide-in animations.
- **12 Hand-crafted Levels**: Increasing complexity featuring stacked towers, sky bridges, TNT-loaded fortresses, and multi-tier castles.
- **Interactive Level Selection**: Polished Level Grid Selector showing level completion status.
- **Procedural Sound Synthesis (In-Memory)**: Runs a custom oscillator-based synthesizer that generates all SFX (wood break, ice tinkle, stone crash, launch creaks, explosions, and pops) at startup, requiring zero external sound assets.

---

## 🦅 Playable Birds & Abilities

Left-click while a bird is in flight to trigger its signature special ability:

| Bird Type | Sprite | Ability | Behavior |
| :--- | :--- | :--- | :--- |
| **Red Bird** | 🔴 | **Standard Launch** | Solid, heavy impact properties. |
| **Blue Bird** | 🔵 | **Split Power** | Divides into three smaller, high-speed birds. Perfect for shattering ice! |
| **Yellow Bird** | 🟡 | **Speed Boost** | Speeds up mid-air with an aerodynamic velocity multiply. Penetrates wood! |
| **Bomb Bird** | ⚫ | **Explosion Blast** | Explodes on contact or manual click, clearing a wide radius of heavy blocks. |

---

## 🪵 Block Materials & Properties

Each block type responds differently to impact forces based on its density, friction, and health:

1. **Wood Block** (`wood.tscn` / `box.gd`): Default material. Balanced weight and strength. Plays a resonant, woody cracking sound on breakage.
2. **Ice Block** (`ice.tscn` / `box.gd`): Lightweight and fragile (cyan/semi-transparent). Low friction, making structures slide easily. Plays high-frequency chimes.
3. **Stone Block** (`stone.tscn` / `box.gd`): Extremely heavy and dense (gray granite). Resistant to normal impacts. Requires Yellow bird speed boosts or Bomb explosions to topple. Plays a low-frequency heavy rumble.

---

## 🛠️ Project Structure

Below is the directory map of the primary game components:

```
├── main.tscn             # Main Game Scene (includes Level Selector & UI overlay)
├── main.gd               # Level Database, Win/Loss loops, level loading
├── bird.tscn             # Unified base scene for all bird types
├── bird.gd               # Flight state machines, drag controls, and special powers
├── slingshot.tscn        # Slingshot launcher scene
├── slingshot.gd          # Draw mechanics, elastic constraints, and visual trajectory
├── box.tscn              # Base scene for destroyable structures
├── box.gd                # Damage calculation, particle spawning, and material detection
├── tnt.tscn              # Explosive barrels
├── tnt.gd                # Blast radius physics overrides and particle triggers
├── pig.tscn              # Targets to eliminate
├── pig.gd                # Health tracking and pop logic
├── sound_manager.gd      # Wave-synthesis engine generating all gameplay audio
└── export_presets.cfg    # Android deployment target presets
```

---

## 🚀 Running the Project

### Prerequisites
- [Godot 4.6.x (Stable)](https://godotengine.org/download) installed on your system.

### Steps
1. Clone this repository:
   ```bash
   git clone https://github.com/Apeel-raj/Angrybird-clone-using-godot.git
   ```
2. Open the **Godot Project Manager**.
3. Click **Import**, navigate to the cloned folder, and select `project.godot`.
4. Click **Edit** to open the project in the Godot Editor.
5. Press **F5** (or click the Play button in the top-right corner) to run the game!

---

## 📱 Compiling the Android APK

The project is pre-configured with Android export profiles. To build the `.apk` on your local machine:

1. **Install Prerequisites**:
   - Install **Java JDK 17** (or later) and ensure it's in your system PATH.
   - Install **Android Studio** to set up the Android SDK (usually located at `C:\Users\<Username>\AppData\Local\Android\Sdk`).
2. **Generate a Debug Keystore**:
   Run this command in terminal to create a debug keystore for signing the build:
   ```bash
   keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 365
   ```
3. **Configure Godot Editor Settings**:
   - Go to **Editor** $\rightarrow$ **Editor Settings...** $\rightarrow$ **Export** $\rightarrow$ **Android**.
   - Set **Android Sdk Path** to your local SDK location.
   - Set **Debug Keystore** to the file path of your generated `debug.keystore`.
   - Set **Java Sdk Path** to your Java installation folder (e.g. `C:/Program Files/Java/jdk-24`).
4. **Export**:
   - Go to **Project** $\rightarrow$ **Export...**
   - Select the **Android** preset.
   - Click **Export Project...** at the bottom, choose your target folder, name the file `angrybirds.apk`, and click **Save**.
