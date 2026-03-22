/*********************************************************************************
 * --- Project: -------- Doppler ultrasound for blood pressure devices
 * --- Authors: -------- Maria N. Petrou
 * --- Description: ---- Pulse Wave Doppler transmitter using the PWM signal
 * --------------------- on an Arduino Nano to time synchronise.
 ******************************************************************************/
#define OUTPUT_PIN 3            // Read generated pulse signal

// Variables
float frequency;        // Desired frequency [Hz]
float gateFreq;         // Desired gate frequency [Hz]
float dutyCycle;        // Desired duty cycle (pulse width) [%]

double period;          // The waveform's period
double offTime;         // Pulse LOW time period
double onTime;          // Pulse HIGH time period
long longOffTime;
long longOnTime;

double noLoops;         // The gate's period 
double periodGate;      // The gate's period 
double gateOffTime;     // Pulse LOW time period
long gateLongOffTime;
int i = 0; 

/// Initialize Serial port and global vars
void setup() {
  Serial.begin(9600);
  while(! Serial)
    ;
  pinMode(OUTPUT_PIN, OUTPUT);

  // Initalize the frequency and the duty cycle. 
  frequency = 10;
  gateFreq = 100;
  dutyCycle = 50;
  calc();
}

void calc() {
    // Calculate the period and the amount of time the output is on for (HIGH) and 
    // off for (LOW).
    period = 1000.0 / frequency;
    offTime = period - (period * (dutyCycle/100.0));
    onTime = period - offTime;
    longOnTime = (long) onTime;
    longOffTime = (long) offTime;
    Serial.print("onTime:");
    Serial.print(longOnTime);
    Serial.print("\noffTime:");
    Serial.print(longOffTime);

    noLoops = gateFreq/frequency;
    periodGate = 1000.0 / frequency;
    gateOffTime = period - (periodGate * (dutyCycle/100.0));
    gateLongOffTime = 10*longOffTime; // (long) gateOffTime;
}

// Main loop
void loop() {  
  // write the generated pulse signal to output pin
  if (i <= noLoops) {
    digitalWrite(OUTPUT_PIN, HIGH);
    delay(longOnTime);
  
    digitalWrite(OUTPUT_PIN, LOW);
    delay(longOffTime);
    i = i+1;
  }
  else {
    digitalWrite(OUTPUT_PIN, LOW);
    delay(gateLongOffTime);
    i = 0;
  }
}
