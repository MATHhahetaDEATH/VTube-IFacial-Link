# VTube-IFacial-Link

A **VTube Studio** plugin that bridging facial tracking from **iFacialMocap** (IOS), enabling full apple ARKit facial tracking features. 

Ported to Swift using Gemini(Antigravity). 

The original python files are kept and Swift files are in the 'Macapp' folder. 

![Screenshot](imgs/screenshot.png)

## Quick Start Guide

1. Ensure **"Start API (allow plugins)"** is enabled in VTube Studio settings (default port: 8001).
2. Enter the IP address provided by **iFacialMocap** on your iPhone.
3. Toggle the connection switches for both iFacialMocap and VTube Studio. Green indicators signify a successful connection (red indicates disconnected). Remember to click "Allow" in VTube Studio if it prompts.

## Tips on Background Service

Once the window opens, flipping either the UDP or VTS switch to "ON" will automatically launch the resident service in the background silently. You will see the indicator at the bottom say "Background Service Running". Even if you then close the Terminal or the App Window, as long as it's running, the service stays alive. (If you need to kill it later, you can open the UI and click the red "Force Stop Service" button).

## Build from Source

We have provided a packaging script to create a standalone `.app` bundle.

### 1. Build the App Bundle

Run the following command in the `MacApp` directory:

```bash
./build_app.sh
```

This will create `build/VTube-IFacial-Link.app`.

### 2. Launching

You can open the app directly:

```bash
open build/VTube-IFacial-Link.app
```

Or find it in Finder at `MacApp/build/VTube-IFacial-Link.app`.


## Supported Parameters

### VTube Studio Default

- FacePositionX
- FacePositionY
- FacePositionZ
- FaceAngleX
- FaceAngleY
- FaceAngleZ
- MouthSmile
- MouthOpen
- Brows
- TongueOut
- EyeOpenLeft
- EyeOpenRight
- EyeLeftX
- EyeLeftY
- EyeRightX
- EyeRightY
- CheekPuff
- FaceAngry
- BrowLeftY
- BrowRightY
- MouthX

### Custom Parameters (ARKit)

- EyeBlinkLeft
- EyeLookDownLeft
- EyeLookInLeft
- EyeLookOutLeft
- EyeLookUpLeft
- EyeSquintLeft
- EyeWideLeft
- EyeBlinkRight
- EyeLookDownRight
- EyeLookInRight
- EyeLookOutRight
- EyeLookUpRight
- EyeSquintRight
- EyeWideRight
- JawForward
- JawLeft
- JawRight
- JawOpen
- MouthClose
- MouthFunnel
- MouthPucker
- MouthLeft
- MouthRight
- MouthSmileLeft
- MouthSmileRight
- MouthFrownLeft
- MouthFrownRight
- MouthDimpleLeft
- MouthDimpleRight
- MouthStretchLeft
- MouthStretchRight
- MouthRollLower
- MouthRollUpper
- MouthShrugLower
- MouthShrugUpper
- MouthPressLeft
- MouthPressRight
- MouthLowerDownLeft
- MouthLowerDownRight
- MouthUpperUpLeft
- MouthUpperUpRight
- BrowDownLeft
- BrowDownRight
- BrowInnerUp
- BrowOuterUpLeft
- BrowOuterUpRight
- CheekPuff
- CheekSquintLeft
- CheekSquintRight
- NoseSneerLeft
- NoseSneerRight
- TongueOut