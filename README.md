
# Zoltan's Datapixx helper functions

Most of these are compatible with other [VPixx](http://vpixx.com) devices, such as the Datapixx and the VIEWPixx. These functions are mainly involved with handling the touch panel and the response box. They may not all be suitable for your experiment, so please do feel free and recycle them as much as you deem fit. Please cite the origin!

In addition to this 'documentation', there is additional information added to the help of the functions, and there are comments in the code that may be helpful to understand what's going on.


# Touch panel: the functions

These functions handle the resistive touch panel. I have tested this on a VIEWPixx/TOUCHPixx combo, so you may have to adapt it if you use it as a touch panel, you may need modifications.

## `calibration_matrix = Datapixx_calibrate_touchpixx([OPTIONAL]display_number)`

This function executes a five-point linear touch calibration operation. It is similar to old Palm and Windows CE devices: hit the crosses on the screen, and it calculates what corrections are needed for the touch coordinates to correspond with the pixel coordinates. The red feedback dot is the uncorrected touch panel data scaled to the monitor (note that the Y axis is inverted). Once the calibration is done, you can try it out three times. The green feedback dot shows the corrected touch data.  
You can use it stand-alone, and then it will create its own graphics window using Psychtoolbox, or you can use it in your existing Psychtoolbox code.
The output of this function is the `calibration_matrix`, which you will need for the other touch functions.  
For multi-monitor set-ups, you can specify which display to use. It defaults to the highest one.

## `[screen_is_touched, touch_coordinates] = Datapixx_get_touch_coordinates(calibration_matrix, [OPTIONAL]display_resolution)`

This function returns whether the screen is touched, and if so, the touch coordinates in pixels one frame after it was called. You need to call this function repeatedly in a render loop for example.
Also, this function will need the `calibration_matrix` you generated before calling this function using `Datapixx_calibrate_touchpixx()`, and if you are running this with something exotic, you can set the screen resolution too. By default, it is set to `[1920, 1080]`, but if you want it to return relative coordinates, call it this way:
```
    relative_coordinates = Datapixx_get_touch_coordinates(calibration_matrix, [1, 1]);
```

If you don't give a calibration matrix, the function will still work, but it will give you a warning.

## `[x, y] = Datapixx_wait_for_touch_coordinates(calibration_matrix)`

This function holds code execution and waits until the screen is touched, and returns the touch coordinates. This is useful when you don't update the screen every frame, and you want your code to continue only after the screen was touched. The input arguments are the `calibration_matrix` which you need to generate prior to calling this function using `Datapixx_calibrate_touchpixx()`. The optional second argument is the `screen_resolution`, which is a two element array. By default, it is set to `[1920, 1080]`, but if you want it to return relative coordinates, but if you want the function to return relative coordinates, set the second input argument to `[1, 1]`.

**This function is NOT interchangeable with `Datapixx_get_touch_coordinatges()`!**

# Touch panel: the calibration algorithm

When I was much younger, I used to calibrate my resistive touch screens manually, using a scale an offset. I had to make sure that my touch panel is perfectly aligned with the screen. Then, many many years later, I came across a brilliant application note by Texas Instruments, which handles rotations too, making it pretty flexible. I don't include the link here, but you can look it up using the following information:
```
Fang, W. & Chang, T. (2007 Q3). Calibration in touch-screen systems.
Analog Application Journal, (3), 5-9, Texas Instruments
```

This in itself started this sub-project which resulted in these functions.  
If you are interested on how it works, read the document, but in a nutshell:  
In `Datapixx_calibrate_touchpixx()`, from section 4 (around Line 136 or so), I am following their algorithm, literally by the letter:  
So I got a bunch of test display points, which are converted to relative coordinates. We then sample the raw touch data, which are known to correspond to these test display points. These raw touch points are organised to a two-columns matrix. Then, we add an other column, consisting of ones, which becomes the `A_matrix`. The calibration matrix is calculated by this line:

```
    calibration_matrix(:, 1) = (A_matrix' * A_matrix)^(-1) * A_matrix' * x_display_normalised_coordinates;
    calibration_matrix(:, 2) = (A_matrix' * A_matrix)^(-1) * A_matrix' * y_display_normalised_coordinates;
```
Column 1 is for the X coordinates, and column 2 is for the Y coordinates.  

Then, you can calculate the correct coordinates, like so:

```
    touch_coordinates(1) = calibration_matrix(1, 1) * touch_raw_data(1) + calibration_matrix(2, 1) * touch_raw_data(1) + calibration_matrix(3, 1);
    touch_coordinates(2) = calibration_matrix(1, 2) * touch_raw_data(2) + calibration_matrix(2, 2) * touch_raw_data(2) + calibration_matrix(3, 2);
```

I scaled this back to screen coordinates by default, but you can change it, according to taste.

# Touch panel: pointer test

The directory `touch_panel_test` includes a simple test utility written in Matlab for your touch screen. I have also included the required functions, so you won't have to add anything to your path, and you can just simply run `touch_panel_test.m`. If the graphics don't appear on the correct monitor in your set-up, adjust the variable `display_number` accordingly.  

The corrected display coordinates are displayed in an infinite loop, and visible only when the screen is touched. I guess it can be used to search for touch panel defects, which are going to appear as non-linearities or bad touch detection.

# Touch panel: use with display with humans

The TOUCHPixx is a resistive touch panel. It works by the detection of two transparent conducting layers physically pressed together. However, it's so precisely made, that it's very difficult to feel the gap between these conductive layers, and I have noticed that young people who grew up using capacitive touch screens will not apply enough force for the touch to be detected when they use fingertips. If this happens, the reported touch coordinate might not correspond to the actual touch location, even if the display was properly calibrated before. A remedy to this to set a minimum time the touch panel is touched before the system can report valid coordinates.  

For this reason, it's advisable to use this line, which tends to minimise garbage data.
```
    Datapixx('SetTouchpixxStabilizeDuration', 0.01); % 10 ms.
```

# RepsonsePixx: functions

## `[is_the_button_pressed] = Datapixx_check_button_status(din_number)`

This function does a bitwise and operation on the DIN (actually, GPIO) lines. With the RESPONSEPixx, when you press a button, you are pulling the corresponding line to the ground, so the selected line will be a logic zero.

This function on the other hand, returns `1` if the button is pressed, and `0` if the button is not pressed. This way, you can just use this function directly in if statements, and its use is more self-explanatory.  
The corresponding numbers are:  

- 0: Red button  
- 1: Yellow button  
- 2: Green button  
- 3: Blue button  
- 4: White button  

...but you can pretty much wire everything everywhere. So if you decide to make your own hardware, use a different number and update this function accordingly!

## `Datapixx_set_led_status(din_number, value)`

This function sets the digital value of pins that are previously declared as outputs. the first input argument is the line number you want to change value of, and the second one is the digital value of said line.

For the RESPONSEPixx, the LEDs are wired to:

- 16: Red
- 17: Yellow
- 18: Green
- 19: White

...but again, you can pretty much wire everything everywhere. The outputs are 5V TTL compatible.  
Note that the LEDs may not be bright enough to be visible in well-lit environments.