; =============================================================================
; Elgato Key Light Controller for AutoHotkey v2.0
; =============================================================================
; 
; Description: Controls Elgato Key Light devices via HTTP API
; Author: Chris Grabiński
; Repository: https://github.com/chrisgrabinski/autohotkey-scripts
; Version: 1.0.0
; 
; Prerequisites:
; - AutoHotkey v2.0 or later
; - Elgato Key Light device on the same network
; - curl command available in system PATH
; - Network access to the device's IP address and port
;
; Usage:
; - Windows + End: Toggle light on/off
; - Windows + Up/Down: Adjust brightness
; - Windows + Left/Right: Adjust color temperature
; =============================================================================

#Requires AutoHotkey v2.0

; =============================================================================
; NETWORK CONFIGURATION
; =============================================================================
; Configure your Elgato Key Light device IP address and port
; Default port is typically 9123, but may vary by device
ELGATO_KEY_LIGHT_IP := "192.168.0.0"  ; Replace with your device's actual IP
ELGATO_KEY_LIGHT_PORT := "9123"        ; Replace if using non-standard port

; =============================================================================
; BRIGHTNESS CONFIGURATION
; =============================================================================
; Brightness values range from 3-100 (3 = very dim, 100 = maximum brightness)
; Step size determines how much brightness changes per key press
BRIGHTNESS_STEP := 3      ; Brightness increment/decrement per adjustment
MIN_BRIGHTNESS := 3        ; Minimum brightness level (very dim)
MAX_BRIGHTNESS := 100      ; Maximum brightness level (full brightness)

; =============================================================================
; COLOR TEMPERATURE CONFIGURATION
; =============================================================================
; Temperature values range from 0-344 (0 = cool white, 344 = warm white)
; Step size determines how much temperature changes per key press
TEMPERATURE_STEP := 5      ; Temperature increment/decrement per adjustment
MIN_TEMPERATURE := 0       ; Coolest white (7000K)
MAX_TEMPERATURE := 344     ; Warmest white (2900K)

; =============================================================================
; DEBOUNCE CONFIGURATION
; =============================================================================
; Prevents rapid-fire API calls when holding down keys
; Delay in milliseconds before executing the actual light adjustment
DEBOUNCE_DELAY := 100      ; 100ms delay to prevent excessive API calls

; =============================================================================
; ELGATO KEY LIGHT CONTROLLER CLASS
; =============================================================================
; This class manages communication with the Elgato Key Light device via HTTP API.
; It handles light state, brightness, color temperature, and implements
; debouncing to prevent excessive network requests.
class ElgatoKeyLightController {
    
    ; =========================================================================
    ; CONSTRUCTOR
    ; =========================================================================
    ; Initializes a new light controller instance with default values
    ; Defaults: Light off, 50% brightness, neutral temperature (170)
    __New() {
        this.on := 0                    ; Light state: 0 = off, 1 = on
        this.brightness := 50           ; Default brightness: 50%
        this.temperature := 170         ; Default temperature: neutral white
        this.debounceTimer := 0         ; Timer reference for debouncing
    }

    ; =========================================================================
    ; CORE LIGHT ADJUSTMENT METHOD
    ; =========================================================================
    ; Sends HTTP PUT request to the Elgato Key Light device
    ; 
    ; Parameters:
    ;   on (optional): Light state - 1 to turn on, 0 to turn off
    ;                  If omitted, uses current state
    ;
    ; HTTP Request Format:
    ;   PUT /elgato/lights
    ;   Content-Type: application/json
    ;   Body: {"numberOfLights": 1, "lights": [{"on": 1, "brightness": 50, "temperature": 170}]}
    ;
    ; Error Handling: Displays message box if HTTP request fails
    AdjustLight(on := 1) {
        try {
            ; Construct JSON payload for the Elgato API
            jsonPayload := '{\"numberOfLights\": 1, \"lights\": [{\"on\": ' on ', \"brightness\": ' this.brightness ', \"temperature\": ' this.temperature '}]}'
            
            ; Send HTTP PUT request using curl
            Run 'curl -X PUT -H "Content-Type: application/json" -d "' jsonPayload '" http://' ELGATO_KEY_LIGHT_IP ':' ELGATO_KEY_LIGHT_PORT '/elgato/lights',, "Hide"
        } catch Error as e {
            ; Display error message if request fails
            MsgBox "Failed to adjust light: " e.Message
        }
    }

    ; =========================================================================
    ; DEBOUNCED LIGHT ADJUSTMENT
    ; =========================================================================
    ; Implements debouncing to prevent rapid API calls when keys are held down
    ; Cancels any pending timer and sets a new one with the specified delay
    ; This ensures only one API call is made after the user stops pressing keys
    AdjustLightDebounced() {
        ; Cancel any existing timer
        if (this.debounceTimer) {
            SetTimer this.debounceTimer, 0
        }
    
        ; Create new timer that will call AdjustLight after the debounce delay
        this.debounceTimer := ObjBindMethod(this, "AdjustLight")
        SetTimer this.debounceTimer, -DEBOUNCE_DELAY
    }

    ; =========================================================================
    ; LIGHT TOGGLE METHOD
    ; =========================================================================
    ; Toggles the light between on and off states
    ; Updates internal state and immediately sends adjustment command
    ToggleOn() {
        this.on := !this.on            ; Flip current state
        this.AdjustLight(this.on)      ; Apply the new state
    }

    ; =========================================================================
    ; BRIGHTNESS ADJUSTMENT METHOD
    ; =========================================================================
    ; Adjusts brightness up or down by the configured step size
    ; Respects minimum and maximum brightness limits
    ;
    ; Parameters:
    ;   direction: "up" to increase brightness, "down" to decrease
    ;              Invalid values are ignored
    ;
    ; Brightness Range: MIN_BRIGHTNESS (3) to MAX_BRIGHTNESS (100)
    AdjustBrightness(direction) {
        ; Validate direction parameter
        if (direction != "up" && direction != "down") {
            return
        }
    
        ; Adjust brightness within valid bounds
        if (direction = "up") {
            this.brightness := Min(this.brightness + BRIGHTNESS_STEP, MAX_BRIGHTNESS)
        } else {
            this.brightness := Max(this.brightness - BRIGHTNESS_STEP, MIN_BRIGHTNESS)
        }
    
        ; Apply the new brightness setting
        this.AdjustLight()
    }
    
    ; =========================================================================
    ; COLOR TEMPERATURE ADJUSTMENT METHOD
    ; =========================================================================
    ; Adjusts color temperature up or down by the configured step size
    ; Respects minimum and maximum temperature limits
    ;
    ; Parameters:
    ;   direction: "up" to increase temperature (warmer white), 
    ;              "down" to decrease temperature (cooler white)
    ;              Invalid values are ignored
    ;
    ; Temperature Range: MIN_TEMPERATURE (0 = cool) to MAX_TEMPERATURE (344 = warm)
    AdjustTemperature(direction) {
        ; Validate direction parameter
        if (direction != "up" && direction != "down") {
            return
        }
    
        ; Adjust temperature within valid bounds
        if (direction = "up") {
            this.temperature := Min(this.temperature + TEMPERATURE_STEP, MAX_TEMPERATURE)
        } else {
            this.temperature := Max(this.temperature - TEMPERATURE_STEP, MIN_TEMPERATURE)
        }
    
        ; Apply the new temperature setting
        this.AdjustLight()
    }
}

; =============================================================================
; INSTANCE CREATION
; =============================================================================
; Create a global instance of the light controller
keyLightController := ElgatoKeyLightController()

; =============================================================================
; HOTKEY MAPPINGS
; =============================================================================
; Windows key combinations for controlling the light
; All hotkeys use the global keyLightController instance
;
; Windows + End:   Toggle light on/off
; Windows + Up:    Increase brightness
; Windows + Down:  Decrease brightness  
; Windows + Left:  Decrease temperature (cooler white)
; Windows + Right: Increase temperature (warmer white)
#End::keyLightController.ToggleOn()
#Up::keyLightController.AdjustBrightness("up")
#Down::keyLightController.AdjustBrightness("down")
#Left::keyLightController.AdjustTemperature("down")
#Right::keyLightController.AdjustTemperature("up")
