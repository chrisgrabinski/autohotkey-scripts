#Requires AutoHotkey v2.0

; constants
ELGATO_KEY_LIGHT_IP := "192.168.0.23"
ELGATO_KEY_LIGHT_PORT := "9123"

BRIGHTNESS_STEP := 3
TEMPERATURE_STEP := 5
MIN_BRIGHTNESS := 3
MAX_BRIGHTNESS := 100
MIN_TEMPERATURE := 0
MAX_TEMPERATURE := 344

DEBOUNCE_DELAY := 100

class ElgatoKeyLightController {
    ; Controls Elgato Key Light via HTTP API
    
    __New() {
        ; Initialize light controller with default values
        this.on := 0
        this.brightness := 80
        this.temperature := 170
        this.debounceTimer := 0
    }

    AdjustLight(on := 1) {
        ; Send HTTP request to adjust light settings
        try {
            Run 'curl -X PUT -H "Content-Type: application/json" -d "{\"numberOfLights\": 1, \"lights\": [{\"on\": ' on ', \"brightness\": ' this.brightness ', \"temperature\": ' this.temperature '}]}" http://' ELGATO_KEY_LIGHT_IP ':' ELGATO_KEY_LIGHT_PORT '/elgato/lights',, "Hide"
        } catch Error as e {
            MsgBox "Failed to adjust light: " e.Message
        }
    }

    AdjustLightDebounced() {
        if (this.debounceTimer) {
            SetTimer this.debounceTimer, 0
        }
    
        this.debounceTimer := ObjBindMethod(this, "AdjustLight")
        SetTimer this.debounceTimer, -DEBOUNCE_DELAY
    }

    ToggleOn() {
        this.on := !this.on
        this.AdjustLight(this.on)
    }

    AdjustBrightness(direction) {
        if (direction != "up" && direction != "down") {
            return
        }
    
        if (direction = "up") {
            this.brightness := Min(this.brightness + BRIGHTNESS_STEP, MAX_BRIGHTNESS)
        } else {
            this.brightness := Max(this.brightness - BRIGHTNESS_STEP, MIN_BRIGHTNESS)
        }
    
        this.AdjustLight()
    }
    
    AdjustTemperature(direction) {
        if (direction != "up" && direction != "down") {
            return
        }
    
        if (direction = "up") {
            this.temperature := Min(this.temperature + TEMPERATURE_STEP, MAX_TEMPERATURE)
        } else {
            this.temperature := Max(this.temperature - TEMPERATURE_STEP, MIN_TEMPERATURE)
        }
    
        this.AdjustLight()
    }
}

keyLightController := ElgatoKeyLightController()

#End::keyLightController.ToggleOn()
#Up::keyLightController.AdjustBrightness("up")
#Down::keyLightController.AdjustBrightness("down")
#Left::keyLightController.AdjustTemperature("down")
#Right::keyLightController.AdjustTemperature("up")
