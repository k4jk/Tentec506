
/*
<RebelAllianceMod for the TenTec Rebel 506 QRP Tranciever See PROJECT REBEL QRP below>
**This is a modified version of the code released by TenTec.**

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.
 
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.
 
You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/
//  http://groups.yahoo.com/group/TenTec506Rebel/
// !! Disclaimer !!  !! Disclaimer !!  !! Disclaimer !!  !! Disclaimer !!  !! Disclaimer !!
//  Attention ****  Ten-Tec Inc. is not responsile for any modification of Code 
//  below. If code modification is made, make a backup of the original code. 
//  If your new code does not work properly reload the factory code to start over again.
//  You are responsible for the code modifications you make yourself. And Ten-Tec Inc.
//  Assumes NO libility for code modification. Ten-Tec Inc. also cannot help you with any 
//  of your new code. There are several forums online to help with coding for the ChipKit UNO32.
//  If you have unexpected results after writing and programming of your modified code. 
//  Reload the factory code to see if the issues are still present. Before contacting Ten_Tec Inc.
//  Again Ten-Tec Inc. NOT RESPONSIBLE for modified code and cannot help with the rewriting of the 
//  factory code!
/*
/*********  PROJECT REBEL QRP  *****************************
  Program for the ChipKit Uno32
  This is a simple program to demonstrate a 2 band QRP Amateur Radio Transceiver
  Amateur Programmer Bill Curb (WA4CDM).
  This program will need to be cleaned up a bit!
  Compiled using the MPIDE for the ChipKit Uno32.

  Prog for ad9834
  Serial timming setup for AD9834 DDS
  start > Fsync is high (1), Sclk taken high (1), Data is stable (0, or 1),
  Fsync is taken low (0), Sclk is taken low (0), then high (1), data changes
  Sclk starts again.
  Control Register D15, D14 = 00, D13(B28) = 1, D12(HLB) = X,
  Reset goes high to set the internal reg to 0 and sets the output to midscale.
  Reset is then taken low to enable output. 
 ***************************************************/   

  
// various defines
#define SDATA_BIT                           10          //  keep!
#define SCLK_BIT                            8           //  keep!
#define FSYNC_BIT                           9           //  keep!
#define RESET_BIT                           11          //  keep!
#define FREQ_REGISTER_BIT                   12          //  keep!
#define AD9834_FREQ0_REGISTER_SELECT_BIT    0x4000      //  keep!
#define AD9834_FREQ1_REGISTER_SELECT_BIT    0x8000      //  keep!
#define FREQ0_INIT_VALUE                    0x01320000  //  ?

// flashes when button pressed  for testing  keep!
#define led                                 13   

#define Side_Tone                           3           // maybe to be changed to a logic control
                                                        // for a separate side tone gen
#define TX_Dah                              33          //  keep!
#define TX_Dit                              32          //  keep!
#define TX_OUT                              38          //  keep!

#define Band_End_Flash_led                  24          // // also this led will flash every 100/1khz/10khz is tuned
#define Band_Select                         41          // if shorting block on only one pin 20m(1) on both pins 40m(0)
#define Multi_Function_Button               2           //
#define Multi_function_Green                34          // For now assigned to BW (Band width)
#define Multi_function_Yellow               35          // For now assigned to STEP size
#define Multi_function_Red                  36          // For now assigned to USER

#define Select_Button                       5           // 
#define Select_Green                        37          // Wide/100/USER1
#define Select_Yellow                       39          // Medium/1K/USER2
#define Select_Red                          40          // Narrow/10K/USER3

#define Medium_A8                           22          // Hardware control of I.F. filter Bandwidth
#define Narrow_A9                           23          // Hardware control of I.F. filter Bandwidth

#define Wide_BW                             0           // About 2.1 KHZ
#define Medium_BW                           1           // About 1.7 KHZ
#define Narrow_BW                           2           // About 1 KHZ

#define Step_100_Hz                         0
#define Step_1000_hz                        1
#define Step_10000_hz                       2

#define  Other_1_user                       0           // 
#define  Other_2_user                       1           //
#define  Other_3_user                       2           //

//-------------------------------  SET OPTONAL FEATURES HERE  -------------------------------------------------------------
#define FEATURE_DISPLAY              // LCD display support (include one of the interface and model options below)
//#define FEATURE_LCD_4BIT             // Classic LCD display using 4 I/O lines. **Working**
//#define FEATURE_I2C                  // I2C Support
//#define FEATURE_LCD_I2C_SSD1306      // If using an Adafruit 1306 I2C OLED Display. Use modified Adafruit libraries found here: github.com/pstyle/Tentec506/tree/master/lib/display  **Working**
#define FEATURE_LCD_NOKIA5110        // If using a NOKIA5110 Display. Use modified Adafruit libraries found here: github.com/pstyle/Tentec506/tree/master/lib/display  **Working**
//#define FEATURE_LCD_I2C_1602         // 1602 Display with I2C backpack interface. Mine required pull-up resistors (2.7k) on SDA/SCL **WORKING**
//#define FEATURE_CW_DECODER           // Not implemented yet.
#define FEATURE_KEYER                // Keyer based on code from OpenQRP.org. **Working**
#define FEATURE_BEACON               // Use USER Menu 3 to Activate.  Make sure to change the Beacon text below! **Working**
//#define FEATURE_SERIAL               // Enables serial output.  Only used for debugging at this point.  **Working**
#define FEATURE_BANDSWITCH           // Software based Band Switching.  Press FUNCTION > 2 seconds  **Working with additional Hardware**
#define FEATURE_SPEEDCONTROL         //Analog speed control (uses onboard trimpot connected to A7) **Working**
#define FEATURE_CAT_CONTROL           // Enables CAT based on Kenwood All Frequency set and Interogation  FA00007030000; , IF; **Working**
#define FEATURE_FREQANNOUNCE           // Announce Frequency by keying side tone (not TX). Press SELECT > 2 seconds  **Working**

const int RitReadPin        = A0;  // pin that the sensor is attached to used for a rit routine later.
int RitReadValue            = 0;
int RitFreqOffset           = 0;

const int SmeterReadPin     = A1;  // To give a realitive signal strength based on AGC voltage.
int SmeterReadValue         = 0;

const int BatteryReadPin    = A2;  // Reads 1/5 th or 0.20 of supply voltage.
float BatteryReadValue     = 0;
float BatteryVconvert      = 0.01707;  //callibrated on 13.8v ps

const int PowerOutReadPin   = A3;  // Reads RF out voltage at Antenna.
int PowerOutReadValue       = 0;

const int CodeReadPin       = A6;  // Can be used to decode CW. 
int CodeReadValue           = 0;

const int CWSpeedReadPin    = A7;  // To adjust CW speed for user written keyer.
int CWSpeedReadValue        = 0;            
unsigned long       ditTime;                    // No. milliseconds per dit

#ifdef FEATURE_BEACON
// Simple Arduino CW Beacon Keyer
// Written by Mark VandeWettering K6HX
#define     URCALL          ("PA3ANG");  
#define     BEACON          ("VVV")                                              // Beacon text 
#define     CQ              ("CQ CQ CQ DE PA3ANG PA3ANG PA3ANG PSE K")           // CQ text 
#define     CW_SPEED        20                                 // Beacon Speed    
#define     BEACON_DELAY    10                                 // in seconds
#define     N_MORSE  (sizeof(morsetab)/sizeof(morsetab[0]))    // Morse Table
#define     DOTLEN   (1200/CW_SPEED)                           // No. milliseconds per dit
#define     DASHLEN  (3*(1200/CW_SPEED))                       // CW weight  3.5 / 1   !! was 3.5*

unsigned long  beaconStartTime    = 0;
unsigned long  beaconElapsedTime  = 0;

// Morse table
struct t_mtab { char c, pat; } ;
struct t_mtab morsetab[] = {
  	{'.', 106},
	{',', 115},
	{'?', 76},
	{'/', 41},
	{'A', 6},
	{'B', 17},
	{'C', 21},
	{'D', 9},
	{'E', 2},
	{'F', 20},
	{'G', 11},
	{'H', 16},
	{'I', 4},
	{'J', 30},
	{'K', 13},
	{'L', 18},
	{'M', 7},
	{'N', 5},
	{'O', 15},
	{'P', 22},
	{'Q', 27},
	{'R', 10},
	{'S', 8},
	{'T', 3},
	{'U', 12},
	{'V', 24},
	{'W', 14},
	{'X', 25},
	{'Y', 29},
	{'Z', 19},
	{'1', 62},
	{'2', 60},
	{'3', 56},
	{'4', 48},
	{'5', 32},
	{'6', 33},
	{'7', 35},
	{'8', 39},
	{'9', 47},
	{'0', 63}
} ;

#endif  // FEATURE_BEACON

//-----------############  SET CW SPEED HERE (If you dont use the analog control)  #######-------------
int ManualCWSpeed = 15; //  <---- SET MANUAL CW SPEED HERE

#ifdef FEATURE_KEYER
//  keyerControl bit definitions
//
#define     DIT_L      0x01     // Dit latch
#define     DAH_L      0x02     // Dah latch
#define     DIT_PROC   0x04     // Dit is being processed
#define     PDLSWAP    0x08     // 0 for normal, 1 for swap
#define     IAMBICB    0x10     // 0 for Iambic A, 1 for Iambic B
// 
//Keyer Variables

unsigned char       keyerControl;
unsigned char       keyerState;
int ST_key = 0;        //This variable tells TX routine whether to enter use straight key mode
enum KSTYPE {IDLE, CHK_DIT, CHK_DAH, KEYED_PREP, KEYED, INTER_ELEMENT };

#endif // FEATURE_KEYER

#ifdef FEATURE_DISPLAY
		
const char txt0[22]         = "TT Rebel v0.8  K";
const char txt1[22]         = "ReAllMod v0.9";
const char txt3[8]          = "100 HZ ";
const char txt4[8]          = "1 KHZ  ";
const char txt5[8]          = "10 KHZ ";
const char txt52[5]         = " ";
const char txt57[6]         = "FREQ:" ;
const char txt60[6]         = "STEP:";
const char txt62[4]         = "RX:";
const char txt64[5]         = "RIT:";
const char txt65[5]         = "Band";
const char txt66[4]         = "20M";
const char txt67[4]         = "40M";
const char txt68[4]         = "TX:";
const char txt69[3]         = "V:";
const char txt70[3]         = "S:";
const char txt71[5]         = "WPM:";
const char txt72[5]         = "P:";
const char txt73[7]         = "BEACON";
const char txt74[7]         = "BDELAY";
const char txt75[7]         = "CQCQCQ";
const char txt76[7]         = "CQDELY";

String CatStatus            = "#";

#endif  //FEATURE_DISPLAY

#ifdef FEATURE_LCD_4BIT
#include <LiquidCrystal.h>    //  Classic LCD Stuff
LiquidCrystal lcd(26, 27, 28, 29, 30, 31);      //  LCD Stuff
#endif //FEATURE_LCD_4BIT

#ifdef FEATURE_I2C
#include <Wire.h>  //I2C Library
#endif //FEATURE_I2C

#ifdef FEATURE_LCD_I2C_SSD1306  
#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>
#define OLED_RESET 4
Adafruit_SSD1306 display(OLED_RESET);
#endif //SSD1306

#ifdef FEATURE_LCD_NOKIA5110  
#include <Adafruit_GFX.h>
#include <Adafruit_PCD8544.h>

// pin 30 - Serial clock out (SCLK)
// pin 29 - Serial data out (DIN)
// pin 28 - Data/Command select (D/C)
// pin 27 - LCD chip select (CS)
// pin 26 - LCD reset (RST)
Adafruit_PCD8544 display = Adafruit_PCD8544(30, 29, 28, 27, 26);
#endif //NOKIA5110

#ifdef FEATURE_LCD_I2C_1602  
#include <LiquidCrystal_I2C.h>
LiquidCrystal_I2C lcd(0x27,16,2);  // set the LCD address to 0x27 for a 16 chars and 2 line display
#endif //I2C_1602

int TX_key;

int band_sel;                               // select band 40 or 20 meter
int band_set;
int bsm                         = 0;  

int Step_Select_Button          = 0;
int Step_Select_Button1         = 0;
int Step_Multi_Function_Button  = 0;
int Step_Multi_Function_Button1 = 0;

int Selected_BW                 = 0;    // current Band width 
                                        // 0= wide, 1 = medium, 2= narrow
int Selected_Step               = 0;    // Current Step
int Selected_Other              = 0;    // To be used for anything

//--------------------------------------------------------
// Encoder Stuff 
const int encoder0PinA          = 7;
const int encoder0PinB          = 6;

int val; 
int encoder0Pos                 = 0;
int encoder0PinALast            = LOW;
int n                           = LOW;

//------------------------------------------------------------
const long meter_40             = 16.03e6;      // IF + Band frequency, 
long meter_40_memory            = 16.03e6;      // HI side injection 40 meter 
                                                // range 16 > 16.3 mhz
const long meter_20             = 5.06e6;       // Band frequency - IF, LOW 
long meter_20_memory            = 5.06e6;       // side injection 20 meter 
                                                // range 5 > 5.35 mhz
const long Reference            = 49.99975e6;   // for ad9834 this may be 
                                                // tweaked in software to 
                                                // fine tune the Radio

long RIT_frequency;
long RX_frequency;
long TX_frequency;
long save_rec_frequency;
long frequency_step;
long frequency                  = 0;
long frequency_old              = 0;
long frequency_tune             = 0;
long frequency_default          = 0;
long fcalc;
long IF                         = 9.00e6;          //  I.F. Frequency


//------------------------------------------------------------
// Debug Stuff
unsigned long   loopCount       = 0;
unsigned long   lastLoopCount   = 0;
unsigned long   loopsPerSecond  = 0;
unsigned int    printCount      = 0;

unsigned long  loopStartTime    = 0;
unsigned long  loopElapsedTime  = 0;
float          loopSpeed        = 0;

unsigned long LastFreqWriteTime = 0;

#ifdef FEATURE_SERIAL
void    serialDump();
#endif //FEATURE_SERIAL

//------------------------------------------------------------
void Default_frequency();
void AD9834_init();
void AD9834_reset();
void program_freq0(long freq);
void program_freq1(long freq1);  // added 1 to freq
void UpdateFreq(long freq);

void led_on_off();

void Frequency_up();                        
void Frequency_down();                      
void TX_routine();
void RX_routine();
void Encoder();
void AD9834_reset_low();
void AD9834_reset_high();

void Band_Set_40M_20M();
void Band_40M_limits_led();
void Band_20M_limits_led();
void Step_Flash();
void RIT_Read();

void Multi_Function();          //
void Step_Selection();          // 
void Selection();               //
void Step_Multi_Function();     //

void MF_G();                    // Controls Function Green led
void MF_Y();                    // Controls Function Yellow led
void MF_R();                    // Controls Function Red led

void S_G();                     // Controls Selection Green led & 
                                // Band_Width wide, Step_Size 100, Other_1

void S_Y();                     // Controls Selection Green led & 
                                // Band_Width medium, Step_Size 1k, Other_2

void S_R();                     // Controls Selection Green led & 
                                // Band_Width narrow, Step_Size 10k, Other_3

void Band_Width_W();            //  A8+A9 low
void Band_Width_M();            //  A8 high, A9 low
void Band_Width_N();            //  A8 low, A9 high

void Step_Size_100();           //   100 hz step
void Step_Size_1k();            //   1 kilo-hz step
void Step_Size_10k();           //   10 kilo-hz step

void Other_1();                 //   user 1
void Other_2();                 //   user 2
void Other_3();                 //   user 3 


//-------------------------------------------------------------------- 
void clock_data_to_ad9834(unsigned int data_word);

//-------------------------------------------------------------------- 
void setup() 
{
    // these pins are for the AD9834 control
    pinMode(SCLK_BIT,               OUTPUT);    // clock
    pinMode(FSYNC_BIT,              OUTPUT);    // fsync
    pinMode(SDATA_BIT,              OUTPUT);    // data
    pinMode(RESET_BIT,              OUTPUT);    // reset
    pinMode(FREQ_REGISTER_BIT,      OUTPUT);    // freq register select

    //---------------  Encoder ------------------------------------
    pinMode (encoder0PinA,          INPUT);     // using optical for now
    pinMode (encoder0PinB,          INPUT);     // using optical for now 

    //--------------------------------------------------------------
    pinMode (TX_Dit,                INPUT);     // Dit Key line 
    pinMode (TX_Dah,                INPUT);     // Dah Key line
    pinMode (TX_OUT,                OUTPUT);
    pinMode (Band_End_Flash_led,    OUTPUT);
    
    //-------------------------------------------------------------
    pinMode (Multi_function_Green,  OUTPUT);    // Band width
    pinMode (Multi_function_Yellow, OUTPUT);    // Step size
    pinMode (Multi_function_Red,    OUTPUT);    // Other
    pinMode (Multi_Function_Button, INPUT);     // Choose from Band width, Step size, Other

    //--------------------------------------------------------------
    pinMode (Select_Green,          OUTPUT);    //  BW wide, 100 hz step, other1
    pinMode (Select_Yellow,         OUTPUT);    //  BW medium, 1 khz step, other2
    pinMode (Select_Red,            OUTPUT);    //  BW narrow, 10 khz step, other3
    pinMode (Select_Button,         INPUT);     //  Selection form the above

    pinMode (Medium_A8,             OUTPUT);    // Hardware control of I.F. filter Bandwidth
    pinMode (Narrow_A9,             OUTPUT);    // Hardware control of I.F. filter Bandwidth
    
    pinMode (Side_Tone,             OUTPUT);    // sidetone enable

    Default_Settings();

    //---------------------------------------------------------------
#ifndef FEATURE_BANDSWITCH
    pinMode (Band_Select,           INPUT);     // Band select via Jumpers.
#endif

#ifdef FEATURE_BANDSWITCH
    pinMode (Band_Select,           OUTPUT);    // Used to control relays connected to fileter lines.
    bsm = 0;                                    // default start is 40 meter 
    frequency = meter_20_memory;                // need to fool BANDSWITCH with 20 meter frequency 
                                                // if bsm = 1 (20 meter) then fool with meter_40_memory
#endif

    AD9834_init();
    AD9834_reset();                             // low to high

    Band_Set_40_20M();
    Default_frequency();                       // what ever default is

    digitalWrite(TX_OUT,            LOW);       // turn off TX

    //--------------------------------------------------------------
    Step_Size_100();   // Change for other Step_Size default!
    for (int i=0; i <= 5e4; i++);  // small delay

    //AD9834_init();
    //AD9834_reset();

    encoder0PinALast = digitalRead(encoder0PinA);  
    //attachInterrupt(encoder0PinA, Encoder, CHANGE);
    //attachInterrupt(encoder0PinB, Encoder, CHANGE);
    attachCoreTimerService(TimerOverFlow);//See function at the bottom of the file.

#ifdef FEATURE_SERIAL
    Serial.begin(115200);
    Serial.println("Rebel Ready:");
#endif

#ifdef FEATURE_LCD_4BIT  //Initialize 4bit Display
//--------------------------------------------------------------
  lcd.begin(20, 4);                           // 20 chars 4 lines
  lcd.setCursor(0, 0);
  lcd.print(txt0); // Rebel text
//--------------------------------------------------------------
#endif

#ifdef FEATURE_LCD_I2C_SSD1306	//Initialize SSD1306 Display
  // by default, we'll generate the high voltage from the 3.3v line internally! (neat!)
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);  // initialize with the I2C addr 0x3C (for the 128x32)
  display.display(); // show splashscreen
  delay(2000);
  display.clearDisplay();   // clears the screen and buffer
#endif

#ifdef FEATURE_LCD_NOKIA5110	//Initialize NOKIA5110 Display
  display.begin();  // init done 
  // you can change the contrast around to adapt the display
  // for the best viewing!
  display.setContrast(45);
  //display.display(); // show splashscreen
  //delay(2000);
  display.clearDisplay();   // clears the screen and buffer
  display.setTextSize(1);
  display.setTextColor(BLACK);
  display.setCursor(0,5);
  display.println("     Rebel");
  display.println(" Alliance Mod");
  display.println("      by");
  display.println(" KD8FJO, K4JK");
  display.println("    PA3ANG");
  display.drawRect(0, 0, display.width(), display.height(), BLACK);
  display.display();       // show splashscreen
  delay(5000);
  
#endif

#ifdef FEATURE_LCD_I2C_1602  //Initialize I2C 1602 Display
  lcd.init();                      // initialize the lcd 
  lcd.backlight();
  lcd.setCursor(4,0);
  lcd.print("TEN-TEC");
  lcd.setCursor(3,1);
  lcd.print("506 REBEL");
  delay(2000);
  lcd.clear();   // Clear Display
#endif

#ifdef FEATURE_KEYER
    keyerState = IDLE;
    keyerControl = IAMBICB;      
    checkWPM();                 // Set default CW Speed 
    
    //See if user wants to use a straight key
    if ((digitalRead(TX_Dah) == LOW) || (digitalRead(TX_Dit) == LOW)) {    //Is a lever pressed?
      ST_key = 1;      //If so, enter straight key mode   
  #ifdef FEATURE_LCD_4BIT
      lcd.setCursor(15, 0);
      lcd.print("S");  //Change K = Keyer to S = Straight key
  #endif
    }
#endif

#ifdef FEATURE_CAT_CONTROL  //Initialize CAT control
    Serial.begin(38400);
#endif

}   //    end of setup



//===================================================================
void Default_Settings()
{
    digitalWrite(Multi_function_Green,  LOW);  // Band_Width
                                                // place control here

    digitalWrite(Multi_function_Yellow, LOW);   //
                                                // place control here

    digitalWrite(Multi_function_Red,    HIGH);   //
                                                // place control here

    digitalWrite(Select_Green,          HIGH);  //  
    Band_Width_N();                             // place control here 

    digitalWrite(Select_Yellow,         LOW);   //
                                                // place control here

    digitalWrite(Select_Green,          LOW);   //
                                                // place control here
    digitalWrite (TX_OUT,               LOW);   

    digitalWrite(FREQ_REGISTER_BIT,     LOW);  //This is set to LOW so RX is not dead on power on        
                                                
    digitalWrite (Band_End_Flash_led,   LOW);

    digitalWrite (Side_Tone,            LOW);    
                                              
}


//======================= Main Part =================================
void loop()     // 
{

    digitalWrite(FSYNC_BIT,             HIGH);  // 
    digitalWrite(SCLK_BIT,              HIGH);  //

    RIT_Read();

    Multi_Function(); 

    Encoder();

    #ifdef FEATURE_CAT_CONTROL
      Serial_Cat();
    #endif

    frequency_tune  = frequency + RitFreqOffset;
    UpdateFreq(frequency_tune);
    
    #ifdef FEATURE_KEYER
    #ifndef FEATURE_SPEEDCONTROL
    
    while ( Selected_Other == 1 && Step_Multi_Function_Button1 == 2)    //Is user in User menu option #2?
    {
        PaddleChangeWPM();      //Run Change Routine
        Multi_Function();       //Must run MultiFunction code to detect when user exits either User mode (right button) or user option 2 (left button)
    }
    #endif
    #endif
    
    TX_routine();
	
    #ifdef FEATURE_BEACON
    if ( Selected_Other == 1 ) 
    {
      beaconElapsedTime = millis() - beaconStartTime; 
      if( (BEACON_DELAY *1000) <= beaconElapsedTime )
      {
        #ifdef FEATURE_LCD_4BIT
          TX_frequency = frequency + IF;
          lcd.setCursor(0,1);
          lcd.print(txt68); // TX
          lcd.setCursor(4,1);
          lcd.print(TX_frequency * 0.001);
          lcd.setCursor(14,1);
          lcd.print(txt75);
        #endif
        #ifdef FEATURE_LCD_NOKIA5110
          Display_Refresh(3);
        #endif
        sendmsg(CQ);
        beaconStartTime = millis();  //Reset the Timer for the beacon loop
        #ifdef FEATURE_LCD_4BIT
          lcd.setCursor(14,1);
          lcd.print(txt76);
        #endif
      }
    }
   if ( Selected_Other == 2 ) 
    {
      beaconElapsedTime = millis() - beaconStartTime; 
      if( (BEACON_DELAY *1000) <= beaconElapsedTime )
      {
        #ifdef FEATURE_LCD_4BIT
          TX_frequency = frequency + IF;
          lcd.setCursor(0,1);
          lcd.print(txt68); // TX
          lcd.setCursor(4,1);
          lcd.print(TX_frequency * 0.001);
          lcd.setCursor(14,1);
          lcd.print(txt73);
        #endif
        #ifdef FEATURE_LCD_NOKIA5110
          Display_Refresh(2);
        #endif
        sendmsg(BEACON);
        beaconStartTime = millis();  //Reset the Timer for the beacon loop
        #ifdef FEATURE_LCD_4BIT
          lcd.setCursor(14,1);
          lcd.print(txt74);
        #endif
      }
    }
    #endif
    
    loopCount++;
    loopElapsedTime    = millis() - loopStartTime;    // comment this out to remove the one second tick
    
    // has 1000 milliseconds elasped?
    if( 1000 <= loopElapsedTime )
    {
        #ifdef FEATURE_KEYER
        checkWPM();
        #endif
      
        #ifdef FEATURE_SERIAL
        serialDump();
        #endif
        
        #ifdef FEATURE_DISPLAY
        Display_Refresh(0); 
        #endif
        loopStartTime   = millis();
    }

}    //  END LOOP

#ifdef FEATURE_SERIAL
//===================================================================
//------------------ Debug data output ------------------------------
void    serialDump()
{
    loopsPerSecond  = loopCount - lastLoopCount;
    loopSpeed       = (float)1e6 / loopsPerSecond;
    lastLoopCount   = loopCount;

    Serial.print    ( "uptime: " );
    Serial.print    ( ++printCount );
    Serial.println  ( " seconds" );

    Serial.print    ( "loops per second:    " );
    Serial.println  ( loopsPerSecond );
    Serial.print    ( "loop execution time: " );
    Serial.print    ( loopSpeed, 3 );
    Serial.println  ( " uS" );

    Serial.print    ( "Freq Rx: " );
    Serial.println  ( frequency_tune + IF );
    Serial.print    ( "Freq Tx: " );
    Serial.println  ( frequency + IF );
    
    #ifdef FEATURE_KEYER
    Serial.print    ( "CW speed:" );
    Serial.println  ( CWSpeedReadValue );
    Serial.println  ();
    #endif
    
} // end serialDump()
#endif //FEATURE_SERIAL

#ifdef FEATURE_CAT_CONTROL
// CAT interface based on Kenwood CAT protocal IF; and FA commands.
// Tested with Logger32 @ 38400 Bd and 500mS polling
void Serial_Cat() {
  int digits;
  String command;
  int value = 0;
  char encodeFreqChar;
  // Expects (and wait for) 3 or 22 characters (IF; or FR0;FAxxxxxxxxxxx;MD3;)
  if (Serial.available() > 0) {
     // Read
    do
    {
      digits = Serial.available();
    } while (digits < 3); 
    for (int i=0; i<digits; i++)
    {
      encodeFreqChar = Serial.read();
      command += encodeFreqChar;
    }
    if (command == "IF;") {
      // info asked from Rebel
      #ifdef FEATURE_LCD_4BIT
        lcd.setCursor(16,2);
        lcd.print("T");
      #endif
      #ifdef FEATURE_LCD_NOKIA5110
          CatStatus  =  "T";
      #endif
      // send data only when you receive data:
      // data should be IFfffffffffffxxxxxrrrrrxxxmm00xx00xxx;
      #ifndef FEATURE_BANDSWITCH
        bsm = digitalRead(Band_Select); 
      #endif
      if ( bsm == 1 ) // 20 meter
      { 
        Serial.print("IF000");
      }
      else 
      { 
        Serial.print("IF0000");
      }
      TX_frequency = frequency + IF;
      Serial.print(TX_frequency);
      Serial.println("xxxxx-0000xxx0000xx00xxx;");
    }
    else
    {
      //expecting frequency
      do
    {
      digits = Serial.available();
    } while (digits < 19); 
    for (int i=0; i<digits; i++)
    {
      encodeFreqChar = Serial.read();
      if (i > 5 && i <13 ) {
        #ifdef FEATURE_LCD_4BIT
          lcd.setCursor(16,2);
          lcd.print("R");
        #endif
      #ifdef FEATURE_LCD_NOKIA5110
          CatStatus  =  "R";
      #endif
        value *= 10;
        value += (encodeFreqChar - '0');
      }
    }
    #ifndef FEATURE_BANDSWITCH
      if ( ((value > 700000 && value < 730000) && bsm == 0) || ((value > 1400000 && value < 1435000) && bsm == 1) )
    #endif
    #ifdef FEATURE_BANDSWITCH
      if ( (value > 700000 && value < 730000) || (value > 1400000 && value < 1435000)  )
    #endif
    {
    #ifdef FEATURE_BANDSWITCH
      if ( (value > 700000 && value < 730000) && bsm == 1)
      {
        bsm = 0;
        Band_Set_40_20M();
      }
      if ( (value > 1400000 && value < 1430000) && bsm == 0)
      {
        bsm = 1;
        Band_Set_40_20M();
      }   
    #endif
    frequency = value*10 -IF;
    }
    }
  }
}
#endif  // FEATURE_CAT_INPUT

#ifndef FEATURE_BANDSWITCH
//------------------ Band Select ------------------------------------
void Band_Set_40_20M()
{
    bsm = digitalRead(Band_Select); 

    //  select 40 or 20 meters 1 for 20 0 for 40
    if ( bsm == 1 ) 
    { 
        frequency_default = meter_20;
    }
    else 
    { 
        frequency_default = meter_40; 
        IF *= -1;               //  HI side injection
    }

    Default_frequency();
}

#endif

#ifdef FEATURE_BANDSWITCH
//------------------ Software Band Select ------------------------------------

void Band_Set_40_20M()
{
     

    //  select 40 or 20 meters 1 for 20 0 for 40
    if ( bsm == 1 ) 
    { 
        meter_40_memory = frequency;
        frequency_default = meter_20_memory;
        if ( IF < 0 ) { IF *= -1; }
        digitalWrite(Band_Select,LOW);
    }
    else 
    { 
        meter_20_memory = frequency;
        frequency_default = meter_40_memory; 
        if ( IF > 0 ) { IF *= -1; }               //  HI side injection
        digitalWrite(Band_Select,HIGH);
    }

    Default_frequency();
    // flash Ten-Tec led
    for (int t=0; t < (4-(bsm*2));) {
      Step_Flash(); 
      for (int i=0; i <= 200e3; i++); 
      t++;
    }

}

#endif

//--------------------------- Encoder Routine ----------------------------  
void Encoder()
{  
    n = digitalRead(encoder0PinA);
    if ((encoder0PinALast == LOW) && (n == HIGH)) 
    {
        if (digitalRead(encoder0PinB) == LOW) 
        {
            Frequency_down();    //encoder0Pos--;
        } else 
        {
            Frequency_up();       //encoder0Pos++;
        }
    } 
    encoder0PinALast = n;
}
//----------------------------------------------------------------------
void Frequency_up()
{ 
    frequency = frequency + frequency_step;
    
    Step_Flash();
    
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif

     if ( bsm == 1 ) { Band_20_Limit_High(); }
     else if ( bsm == 0 ) {  Band_40_Limit_High(); }
 
}

//------------------------------------------------------------------------------  
void Frequency_down()
{ 
    frequency = frequency - frequency_step;
    
    Step_Flash();
    
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif

     if ( bsm == 1 ) { Band_20_Limit_Low(); }
     else if ( bsm == 0 ) {  Band_40_Limit_Low(); }
 
}
//-------------------------------------------------------------------------------
void UpdateFreq(long freq)
{
    long freq1;
//  some of this code affects the way to Rit responds to being turned
    if (LastFreqWriteTime != 0)
    { if ((millis() - LastFreqWriteTime) < 100) return; }
    LastFreqWriteTime = millis();

    if(freq == frequency_old) return;

    //Serial.print("Freq: ");
    //Serial.println(freq);

    program_freq0( freq  );
            
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif
    
    freq1 = freq - RitFreqOffset;  //  to get the TX freq

    program_freq1( freq1 + IF  );
  
    frequency_old = freq;
}


#ifndef FEATURE_KEYER
//---------------------  TX Routine  ------------------------------------------------  
void TX_routine()
{
    TX_key = digitalRead(TX_Dit);
    if ( TX_key == LOW)         // was high   
    {
        //   (FREQ_REGISTER_BIT, HIGH) is selected   
        do
        {
            digitalWrite(FREQ_REGISTER_BIT, HIGH);
            digitalWrite(TX_OUT, HIGH);
            digitalWrite(Side_Tone, HIGH);
            #ifdef FEATURE_LCD_4BIT
              TX_frequency = frequency + IF;
              lcd.setCursor(0,1);
              lcd.print(txt68); // TX
              lcd.setCursor(4,1);
              lcd.print(TX_frequency * 0.001);
              Display_RIT(1);
              loopStartTime = millis();//Reset the Timer for this loop
            #endif
            TX_key = digitalRead(TX_Dit);
        } while (TX_key == LOW);   // was high 
        //PowerOutReadValue = analogRead(PowerOutReadpin); 
        digitalWrite(TX_OUT, LOW);  // trun off TX
        for (int i=0; i <= 10e3; i++); // delay for maybe some decay on key release

        digitalWrite(FREQ_REGISTER_BIT, LOW);
        digitalWrite(Side_Tone, LOW);
    }
}
#endif

#ifdef FEATURE_KEYER
//---------------------  TX Routine  ------------------------------------------------  
// Will detect straight key at startup.
// James - K4JK

void TX_routine()
{

 if (ST_key == 1) { // is ST_Key is set to YES? Then use Straight key mode
 
   TX_key = digitalRead(TX_Dit);
    if ( TX_key == LOW)         // was high   
    {
        //   (FREQ_REGISTER_BIT, HIGH) is selected      
        
        do
        {
            digitalWrite(FREQ_REGISTER_BIT, HIGH);
            digitalWrite(TX_OUT, HIGH);
            digitalWrite(Side_Tone, HIGH);
             #ifdef FEATURE_LCD_4BIT
              TX_frequency = frequency + IF;
              lcd.setCursor(0,1);
              lcd.print(txt68); // TX
              lcd.setCursor(4,1);
              lcd.print(TX_frequency * 0.001);
              Display_RIT(1);
              loopStartTime = millis();//Reset the Timer for this loop
            #endif
            #ifdef FEATURE_LCD_NOKIA5110
              Display_Refresh(1);
            #endif
           TX_key = digitalRead(TX_Dit);
        } while (TX_key == LOW);   // was high 

        digitalWrite(TX_OUT, LOW);  // turn off TX
        for (int i=0; i <= 10e3; i++); // delay for maybe some decay on key release
        digitalWrite(FREQ_REGISTER_BIT, LOW);
        digitalWrite(Side_Tone, LOW);
        loopStartTime = millis();//Reset the Timer for this loop
    }
 } 
   else {    //If ST_key is not 1, then use IAMBIC
  
  static long ktimer;
  
  // Basic Iambic Keyer
  // keyerControl contains processing flags and keyer mode bits
  // Supports Iambic A and B
  // State machine based, uses calls to millis() for timing.
  // Code adapted from openqrp.org
 
  switch (keyerState) {
    case IDLE:
        // Wait for direct or latched paddle press
        if ((digitalRead(TX_Dit) == LOW) ||
                (digitalRead(TX_Dah) == LOW) ||
                    (keyerControl & 0x03)) {
            update_PaddleLatch();
            keyerState = CHK_DIT;
        }
        break;

    case CHK_DIT:
        // See if the dit paddle was pressed
        if (keyerControl & DIT_L) {
            keyerControl |= DIT_PROC;
            ktimer = ditTime;
            keyerState = KEYED_PREP;
        }
        else {
            keyerState = CHK_DAH;
        }
        break;
        
    case CHK_DAH:
        // See if dah paddle was pressed
        if (keyerControl & DAH_L) {
            ktimer = ditTime*3;
            keyerState = KEYED_PREP;
        }
        else {
            keyerState = IDLE;
        }
        break;
        
    case KEYED_PREP:
        // Assert key down, start timing, state shared for dit or dah
        digitalWrite(FREQ_REGISTER_BIT, HIGH);
        digitalWrite(TX_OUT, HIGH);         // key the line
        digitalWrite(Side_Tone, HIGH);      // Tone
        #ifdef FEATURE_LCD_4BIT
          TX_frequency = frequency + IF;
          lcd.setCursor(0,1);
          lcd.print(txt68); // TX
          lcd.setCursor(4,1);
          lcd.print(TX_frequency * 0.001);
          Display_RIT(1);
          loopStartTime = millis();//Reset the Timer for this loop
        #endif
        #ifdef FEATURE_LCD_NOKIA5110
          Display_Refresh(1);
        #endif
        ktimer += millis();                 // set ktimer to interval end time
        keyerControl &= ~(DIT_L + DAH_L);   // clear both paddle latch bits
        keyerState = KEYED;                 // next state
        break;
        
    case KEYED:
        // Wait for timer to expire
        if (millis() > ktimer) {            // are we at end of key down ?
            digitalWrite(TX_OUT, LOW);      // turn the key off
            for (int i=0; i <= 10e3; i++); // delay for maybe some decay on key release
            digitalWrite(FREQ_REGISTER_BIT, LOW);
            digitalWrite(Side_Tone, LOW);
            ktimer = millis() + ditTime;    // inter-element time
            keyerState = INTER_ELEMENT;     // next state
        }
        else if (keyerControl & IAMBICB) {
            update_PaddleLatch();           // early paddle latch in Iambic B mode
        }
        break; 
 
    case INTER_ELEMENT:
        // Insert time between dits/dahs
        update_PaddleLatch();               // latch paddle state
        if (millis() > ktimer) {            // are we at end of inter-space ?
            if (keyerControl & DIT_PROC) {             // was it a dit or dah ?
                keyerControl &= ~(DIT_L + DIT_PROC);   // clear two bits
                keyerState = CHK_DAH;                  // dit done, check for dah
            }
            else {
                keyerControl &= ~(DAH_L);              // clear dah latch
                keyerState = IDLE;                     // go idle
                loopStartTime = millis();//Reset the Timer for this loop
            }
        }
        break;
  }
 }

}

///////////////////////////////////////////////////////////////////////////////
//
//    Latch dit and/or dah press
//
//    Called by keyer routine
//
///////////////////////////////////////////////////////////////////////////////
 
void update_PaddleLatch()
{
    if (digitalRead(TX_Dit) == LOW) {
        keyerControl |= DIT_L;
    }
    if (digitalRead(TX_Dah) == LOW) {
        keyerControl |= DAH_L;
    }
}
 
///////////////////////////////////////////////////////////////////////////////
//
//    Calculate new time constants based on wpm value
//
///////////////////////////////////////////////////////////////////////////////
#endif

void loadWPM(int wpm)
{
    ditTime = 1200/wpm;
}

#ifdef FEATURE_SPEEDCONTROL
void checkWPM() //Checks the Keyer speed Pot and updates value
{
   CWSpeedReadValue = analogRead(CWSpeedReadPin);
   CWSpeedReadValue = map(CWSpeedReadValue, 0, 1024, 5, 45);
   loadWPM(CWSpeedReadValue);
}
#endif

#ifndef FEATURE_SPEEDCONTROL
void checkWPM() //Assign Speed manually
{
  CWSpeedReadValue =  ManualCWSpeed;
  loadWPM(CWSpeedReadValue);
}
#endif


//Routine to change CW speed when User mode option #2 is selected. Dit will increase speed, dah will decrease. 
//Either can be held down for rapid change. This is called from main loop() function.

void PaddleChangeWPM()                                
{
  if (digitalRead(TX_Dit) == LOW)      //Dit?
  {
    ManualCWSpeed ++;                  //Increase
    digitalWrite(Side_Tone, HIGH);     //Some side tone to let user know it's working
    delay(ditTime);                    //Make dit length normal
    digitalWrite(Side_Tone, LOW);      //Stop tone
    checkWPM();                        //Call function that updates key speed
    #ifdef FEATURE_DISPLAY
      Display_Refresh();               //Refresh display if enabled to show that speed is changing
    #endif
    delay(ditTime * 3);                //Delay between elements in case key is held down
  }
  else if (digitalRead(TX_Dah) == LOW)    //Dah?
  {
    ManualCWSpeed --;                     //Decrease
    digitalWrite(Side_Tone, HIGH);        //Some side tone to let user know it's working
    delay(ditTime * 3);                   //Make dah length normal
    digitalWrite(Side_Tone, LOW);         //Stop tone
    checkWPM();                           //Call function that updates key speed
    #ifdef FEATURE_DISPLAY
      Display_Refresh();                  //Refresh display if enabled to show that speed is changing
    #endif
    delay(ditTime * 3);                   //Delay between elements in case key is held down
  }
}


#ifdef FEATURE_BEACON

// CW generation routines for Beacon and Memory 
void key(int LENGTH) {
  digitalWrite(FREQ_REGISTER_BIT, HIGH);
  digitalWrite(TX_OUT, HIGH);          // key the line
  digitalWrite(Side_Tone, HIGH);       // Tone
  #ifdef FEATURE_LCD_4BIT
    TX_frequency = frequency + IF;
    lcd.setCursor(0,1);
    lcd.print(txt68); // TX
    lcd.setCursor(4,1);
    lcd.print(TX_frequency * 0.001);
    Display_RIT(1);
    loopStartTime = millis();//Reset the Timer for this loop
  #endif
  delay(LENGTH);
  digitalWrite(TX_OUT, LOW);           // turn the key off
  //for (int i=0; i <= 10e3; i++);       // delay for maybe some decay on key release
  digitalWrite(FREQ_REGISTER_BIT, LOW);
  digitalWrite(Side_Tone, LOW);
  delay(DOTLEN) ;
}

void send(char c) {
  int i ;
  if (c == ' ') {
    delay(7*DOTLEN) ;
    return ;
  }
  if (c == '+') {
    delay(4*DOTLEN) ; 
    key(DOTLEN);
    key(DASHLEN);
    key(DOTLEN);
    key(DASHLEN);
    key(DOTLEN);
    delay(4*DOTLEN) ; 
    return ;
  }    
    
  for (i=0; i<N_MORSE; i++) {
    if (morsetab[i].c == c) {
      unsigned char p = morsetab[i].pat ;
      while (p != 1) {
          if (p & 1)
            key(DASHLEN) ;
          else
            key(DOTLEN) ;
          p = p / 2 ;
          }
      delay(2*DOTLEN) ;
      return ;
      }
  }
}

void sendmsg(char *str) {
  while (*str) {
    if (digitalRead(TX_Dit) == LOW || digitalRead(TX_Dah) == LOW ) 
  {
  // stop automatic transmission Beacon and CQ
  Selected_Other = Other_1_user;
  return;
  }
    send(*str++) ;
  }  
}

#endif FEATURE_BEACON

#ifdef FEATURE_FREQANNOUNCE
void announce(char *str) {
  while (*str) 
    key_announce(*str++); 
}
void beep(int LENGTH) {
    digitalWrite(Side_Tone, HIGH);
    delay(LENGTH);
    digitalWrite(Side_Tone, LOW);
    delay(DOTLEN) ;
}

void key_announce(char c) {
  for (int i=0; i<N_MORSE; i++) {
    if (morsetab[i].c == c) {
      unsigned char p = morsetab[i].pat ;
      while (p != 1) {
          if (p & 1)
            beep(DASHLEN) ;
          else
            beep(DOTLEN) ;
          p = p / 2 ;
          }
      delay(2*DOTLEN) ;
      return ;
      }
  }
}

#endif

//----------------------------------------------------------------------------
void RIT_Read()
{
    int RitReadValueNew =0 ;


    RitReadValueNew = analogRead(RitReadPin);
    RitReadValue = (RitReadValueNew + (7 * RitReadValue))/8;//Lowpass filter

    if(RitReadValue < 500) 
        RitFreqOffset = RitReadValue-500;
    else if(RitReadValue < 523) 
        RitFreqOffset = 0;//Deadband in middle of pot
    else 
        RitFreqOffset = RitReadValue - 523;

}

//-------------------------------------------------------------------------------

 void  Band_40_Limit_High()
    {
         if ( frequency < 16.3e6 )
    { 
         stop_led_off();
    } 
    
    else if ( frequency >= 16.3e6 )
    { 
       frequency = 16.3e6;
         stop_led_on();    
    }
    }
//-------------------------------------------------------    
 void  Band_40_Limit_Low()
    {
        if ( frequency <= 16.0e6 )  
    { 
        frequency = 16.0e6;
        stop_led_on();
    } 
    
    else if ( frequency > 16.0e6 )
    { 
       stop_led_off();
    } 
    }
//---------------------------------------------------------    
 void  Band_20_Limit_High()
    {
         if ( frequency < 5.35e6 )
    { 
         stop_led_off();
    } 
    
    else if ( frequency >= 5.35e6 )
    { 
       frequency = 5.35e6;
         stop_led_on();    
    }
    }
//-------------------------------------------------------    
 void  Band_20_Limit_Low()
    {
        if ( frequency <= 5.0e6 )  
    { 
        frequency = 5.0e6;
        stop_led_on();
    } 
    
    else if ( frequency > 5.0e6 )
    { 
        stop_led_off();
    } 
    }

//--------------------Default Frequency-----------------------------------------
void Default_frequency()
{
    frequency = frequency_default;
    UpdateFreq(frequency);

    //*************************************************************************
}   //  end   Default_frequency


#ifdef FEATURE_LCD_4BIT
//------------------------Display Stuff below-----------------------------------

void Display_Refresh()  //LCD_4Bit Version - Cleaned up, added more Info and tested. - K4JK
{
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif
//BAND Info top line
    if ( bsm == 1 ) 
    {
        lcd.setCursor(17, 0);
        lcd.print(txt66);
    }
    else 
    {
        lcd.setCursor(17, 0);
        lcd.print(txt67);
    } 
//QSX    
    RX_frequency = frequency_tune + IF;
    TX_frequency = frequency + IF;
    //lcd.clear();   // Clear Display
    lcd.setCursor(0,1);
    lcd.print(txt62); // RX
    lcd.setCursor(4,1);
    lcd.print(RX_frequency * 0.001);
    lcd.print(" ");
//RIT
    Display_RIT(0);
// 3rd line, BW, STEP, S, Cat Status (T / R), SPEED
    lcd.setCursor(0,2);
    if (Selected_BW == 0) lcd.print("W");
    if (Selected_BW == 1) lcd.print("M");
    if (Selected_BW == 2) lcd.print("N");
    lcd.setCursor(2,2);
    if (Selected_Step == 0) lcd.print("100");
    if (Selected_Step == 1) lcd.print("1K ");
    if (Selected_Step == 2) lcd.print("10K");
//S Meter 
    lcd.setCursor(6,2);
    lcd.print("S"); // S
    SmeterReadValue = analogRead(SmeterReadPin);
    SmeterReadValue = map(SmeterReadValue, 0, 180, 0, 9);
    //lcd.print(SmeterReadValue);  
    lcd.setCursor(7,2);
    lcd.print("-        ");  // clear meter bar area
    for (int i=1; i < SmeterReadValue; i++) {
      lcd.setCursor(6+i,2); 
      if ( i == 5 || i == 9 )
      {
        lcd.print(i);
      }  
      else
      {
        lcd.print(255, BYTE); 
      }
    }
/*
// DC Volts In
    lcd.setCursor(0,2);
    lcd.print(txt69); // V
    BatteryReadValue = analogRead(BatteryReadPin)* BatteryVconvert;
    lcd.setCursor(4,2);
    lcd.print(BatteryReadValue);
//S Meter 
    lcd.setCursor(0,3);
    lcd.print(txt70); // S
    SmeterReadValue = analogRead(SmeterReadPin);
    SmeterReadValue = map(SmeterReadValue, 0, 180, 0, 9);
    lcd.setCursor(4,3);
    lcd.print(SmeterReadValue);
// CW Speed - Moved this over past the S meter on the fourth line
    #ifdef FEATURE_KEYER //Did user enable keyer function?
      if(ST_key == 0) {  //Did they also plug a paddle in? (or at least NOT plug in a straight key?)
      lcd.setCursor(11,3);	
      lcd.print(txt71); // WPM
      lcd.setCursor(15,3);
      lcd.print(CWSpeedReadValue);
      }
    #endif
   */
 // CW Speed - Moved this over past the S meter on the fourth line
    #ifdef FEATURE_KEYER //Did user enable keyer function?
      if(ST_key == 0) {  //Did they also plug a paddle in? (or at least NOT plug in a straight key?)
      lcd.setCursor(18,2);
      lcd.print(CWSpeedReadValue);
      }
    #endif
}

void Display_RIT(int z)
{
    lcd.setCursor(14, 1);
    lcd.print("      ");  // clear 6 last characters on line 1
    int noritinfo = 0;
    #ifdef FEATURE_BEACON
      if ( Selected_Other == 2 )
      {
      lcd.setCursor(14, 1);
      lcd.print(txt74); // BDELAY
      noritinfo = 1;
      }
    #endif
    if ( !noritinfo && !z )
    {
      if (RitFreqOffset < 0) {
        lcd.setCursor(14, 1);
      } else {
        lcd.setCursor(15, 1);
      }      
      lcd.print(RitFreqOffset);
    }  
}
#endif //FEATURE_LCD_4BIT

#ifdef FEATURE_LCD_I2C_SSD1306  
//------------------------Display Stuff below-----------------------------------
void Display_Refresh()  //SSD1306 I2C OLED Version
{
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif
     
    RX_frequency = frequency_tune + IF;
    TX_frequency = frequency + IF;
    display.clearDisplay();   // clears the screen and buffer
    display.setTextSize(.);
    display.setTextColor(WHITE);
    display.setCursor(3,3);
    display.print(txt62); // RX
    display.setCursor(20,3);
    display.print(RX_frequency * 0.001);
	
    display.setCursor(3,12);	
    display.print(txt68); // TX
    display.setCursor(20,12);
    display.print(TX_frequency * 0.001);
      
    display.setCursor(75,12);
    display.print(txt69); // V
    BatteryReadValue = analogRead(BatteryReadPin)* BatteryVconvert;
    display.setCursor(88,12);
    display.print(BatteryReadValue);

    display.setCursor(75,3);
    display.print(txt70); // S
    SmeterReadValue = analogRead(SmeterReadPin);
    SmeterReadValue = map(SmeterReadValue, 0, 180, 0, 9);
    display.setCursor(88,3);
    display.print(SmeterReadValue);
    
    display.drawRect(0, 0, display.width(), display.height(), WHITE);
    
    #ifdef FEATURE_KEYER  //Did user enable keyer function?
      if(ST_key == 0) {   //Did they also plug a paddle in? (or at least NOT plug in a straight key?)
    display.setCursor(3,21);
    display.print(txt71); // WPM
    display.setCursor(30,21);
    display.print(CWSpeedReadValue);
      }
    #endif

  //  display.setCursor(45,21);	
  //  display.print(txt72); // PWR
  //  display.setCursor(70,21);
  //  display.print(PowerOutReadValue);
    
    display.display();
 }
#endif

#ifdef FEATURE_LCD_NOKIA5110  
//------------------------Display Stuff below-----------------------------------
void Display_Refresh(int z)  //NOKIA5110  Version
{

    int s;
    int line1 = 3;
    int line2 = 18;
    int line3 = 38;
    int line4 = 28;
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif
     
    RX_frequency = frequency_tune + IF;
    TX_frequency = frequency + IF;
    display.clearDisplay();   // clears the screen and buffer
    display.setTextSize(1);
    display.setTextColor(BLACK);
    display.setCursor(3,line1);
    display.print(txt1); // line 1
    display.drawLine(2, 12, 80, 12, BLACK);
     
    display.setCursor(5,line2);
    display.setTextSize(1);
    if ( !z ) {	
    display.print(txt62); // RX
    display.print(RX_frequency * 0.001);
    display.setCursor(73,line2);
    if (RitFreqOffset < -20 ) { 
      display.print("-");
    }
    if (RitFreqOffset > 20 ) { 
      display.print("+");
    }
    }
    else
    {
    display.print(txt68); // TX
    display.print(TX_frequency * 0.001);
    }
    
    display.setTextSize(1);
    display.setTextColor(BLACK);
    display.setCursor(3,line3);
    if (Selected_BW == 0) display.print("W");
    if (Selected_BW == 1) display.print("M");
    if (Selected_BW == 2) display.print("N");
    display.setCursor(13,line3);
    if (Selected_Step == 0) display.print("100");
    if (Selected_Step == 1) display.print("1K ");
    if (Selected_Step == 2) display.print("10K");

    if ( !z ) {
    display.setCursor(63,line3);
    display.print(txt70); // S
    SmeterReadValue = analogRead(SmeterReadPin);
    SmeterReadValue = map(SmeterReadValue, 0, 170, 0, 9);
    display.setCursor(75,line3);
    display.print(SmeterReadValue);
    }
    else
    {
    display.setCursor(63,line3);
    display.print(txt72); // P
    PowerOutReadValue = analogRead(PowerOutReadPin);
    PowerOutReadValue = map(PowerOutReadValue, 0, 1023, 0, 9);
    display.setCursor(75,line3);
    display.print(PowerOutReadValue);
    }
    //display.setCursor(3,21);
    //display.print(txt69); // V
    //BatteryReadValue = analogRead(BatteryReadPin)* BatteryVconvert;
    //display.setCursor(15,21);
    //display.print(BatteryReadValue);
    
    display.drawRect(0, 0, display.width(), display.height(), BLACK);
    
    #ifdef FEATURE_KEYER  //Did user enable keyer function?
      if(ST_key == 0) {   //Did they also plug a paddle in? (or at least NOT plug in a straight key?)
    //display.setCursor(3,21);
    //display.print(txt71); // WPM
    display.setCursor(36,line3);
    display.print(CWSpeedReadValue);
      }
      else
      {
    display.setCursor(36,line3);
    display.print("ST");
      }       
    #endif
    
    #ifdef FEATURE_CAT_CONTROL
      display.setCursor(53,line3);
      display.print(CatStatus);
    #endif


    display.setTextSize(1);
    display.setTextColor(BLACK);
    #ifdef FEATURE_BEACON
      display.setCursor(25,line4);
      if ( z == 3 ) {
        display.print(txt75);
      }    
      if ( Selected_Other == 1 && z != 3 ) {
        display.print(txt76);
      }    
      if ( z == 2 ) {
        display.print(txt73);
      }    
      if ( Selected_Other == 2 && z != 2 ) {
        display.print(txt74);
      }    
     #endif
    display.display();
 }
#endif

#ifdef FEATURE_LCD_I2C_1602

//------------------------Display Stuff below-----------------------------------

void Display_Refresh()  //LCD_I2C_1602 version
{
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif
//QSX    
    RX_frequency = frequency_tune + IF;
    TX_frequency = frequency + IF;
    //lcd.clear();   // Clear Display
    lcd.setCursor(0,0);
    lcd.print("R:"); // RX
    lcd.setCursor(2,0);
    lcd.print(RX_frequency * 0.001);
//QRG
    lcd.setCursor(0,1);	
    lcd.print("T:"); // TX
    lcd.setCursor(2,1);
    lcd.print(TX_frequency * 0.001);
// DC Volts In
    lcd.setCursor(10,0);
    lcd.print(txt69); // V
    BatteryReadValue = analogRead(BatteryReadPin)* BatteryVconvert;
    lcd.setCursor(12,0);
    lcd.print(BatteryReadValue);
//S Meter 
    lcd.setCursor(10,1);
    lcd.print("S"); // S
    SmeterReadValue = analogRead(SmeterReadPin);
    SmeterReadValue = map(SmeterReadValue, 0, 180, 0, 9);
    lcd.setCursor(11,1);
    lcd.print(SmeterReadValue);
// CW Speed - Moved this over past the S meter on the 2nd line
    #ifdef FEATURE_KEYER //Did user enable keyer function?
      if(ST_key == 0) {  //Did they also plug a paddle in? (or at least NOT plug in a straight key?)
      lcd.setCursor(13,1);	
      lcd.print("W"); // WPM
      lcd.setCursor(14,1);
      lcd.print(CWSpeedReadValue);
      }
    #endif
 
 }
#endif //FEATURE_LCD_I2C_1602

//--------------------------------------------------------------------------  

void Step_Flash()
{
    stop_led_on();
    
    for (int i=0; i <= 25e3; i++); // short delay 
    
    stop_led_off();   
}

//-----------------------------------------------------------------------------
void stop_led_on()
{
    digitalWrite(Band_End_Flash_led, HIGH);
}

//-----------------------------------------------------------------------------
void stop_led_off()
{
    digitalWrite(Band_End_Flash_led, LOW);
}

//===================================================================
void Multi_Function() // The right most pushbutton for BW, Step, Other
{
    Step_Multi_Function_Button = digitalRead(Multi_Function_Button);
    if (Step_Multi_Function_Button == HIGH) 
    {  
       // Debounce start
       unsigned long time;
       unsigned long start_time;
       #ifdef FEATURE_BANDSWITCH
         unsigned long long_time;
         long_time = millis();
       #endif
      
       time = millis();
       while( digitalRead(Multi_Function_Button) == HIGH ){ 
         
         #ifdef FEATURE_BANDSWITCH
           // function button is pressed longer then 2 seconds
           if ( (millis() - long_time) > 2000 && (millis() - long_time) < 2010 ) { 
             // change band and load default frequency
             if ( bsm == 1 )
             {
               bsm = 0;
               Band_Set_40_20M();
             }
             else
             {
               bsm = 1;
               Band_Set_40_20M();
             }   
        
             // wait for button release
             while( digitalRead(Multi_Function_Button) == HIGH ){ 
             }   
             return;        
           } 
         #endif
         
         start_time = time;
         while( (time - start_time) < 7) {
           time = millis();
         }
       } // Debounce end

        Step_Multi_Function_Button1 = Step_Multi_Function_Button1++;
        if (Step_Multi_Function_Button1 > 2 ) 
        { 
            Step_Multi_Function_Button1 = 0; 
        }
    }
    Step_Function();
}


//-------------------------------------------------------------  
void Step_Function()
{
    switch ( Step_Multi_Function_Button1 )
    {
        case 0:
            MF_G();
            Step_Select_Button1 = Selected_BW; // 
            Step_Select(); //
            Selection();
// no longer needed            for (int i=0; i <= 255; i++); // short delay

            break;   //

        case 1:
            MF_Y();
            Step_Select_Button1 = Selected_Step; //
            Step_Select(); //
            Selection();
// no longer needed            for (int i=0; i <= 255; i++); // short delay

            break;   //

        case 2: 
            MF_R();
            Step_Select_Button1 = Selected_Other; //
            Step_Select(); //
            Selection();
// no longer needed            for (int i=0; i <= 255; i++); // short delay

            break;   //  
    }
}


//===================================================================
void  Selection()
{
    Step_Select_Button = digitalRead(Select_Button);
    if (Step_Select_Button == HIGH) 
    {   
       // Debounce start
       unsigned long time;
       unsigned long start_time;
       #ifdef FEATURE_FREQANNOUNCE
         unsigned long long_time;
         long_time = millis();
       #endif
       
       time = millis();
       while( digitalRead(Select_Button) == HIGH ){ 
         
         #ifdef FEATURE_FREQANNOUNCE
           // function button is pressed longer then 2 seconds
           if ( (millis() - long_time) > 2000 && (millis() - long_time) < 2010 ) { 
             // announce frequency
             TX_frequency = (frequency + IF)/100;
             char buffer[8];
             ltoa(TX_frequency, buffer, 10);
             announce(buffer);
        
             // wait for button release
             while( digitalRead(Select_Button) == HIGH ){ 
             }   
             return;        
           } 
         #endif

         start_time = time;
         while( (time - start_time) < 7) {
           time = millis();
         }
       } // Debounce end

        Step_Select_Button1 = Step_Select_Button1++;
        if (Step_Select_Button1 > 2 ) 
        { 
            Step_Select_Button1 = 0; 
        }
    }
    Step_Select(); 
}


//-----------------------------------------------------------------------  
void Step_Select()
{
    switch ( Step_Select_Button1 )
    {
        case 0: //   Select_Green   could place the S_G() routine here!
            S_G();
            break;

        case 1: //   Select_Yellow  could place the S_Y() routine here!
            S_Y();
            break; 

        case 2: //   Select_Red    could place the S_R() routine here!
            S_R();
            break;     
    }
}



//----------------------------------------------------------- 
void MF_G()    //  Multi-function Green 
{
    digitalWrite(Multi_function_Green, HIGH);    
    digitalWrite(Multi_function_Yellow, LOW);  // 
    digitalWrite(Multi_function_Red, LOW);  //
// no longer needed    for (int i=0; i <= 255; i++); // short delay   
}



void MF_Y()   //  Multi-function Yellow
{
    digitalWrite(Multi_function_Green, LOW);    
    digitalWrite(Multi_function_Yellow, HIGH);  // 
    digitalWrite(Multi_function_Red, LOW);  //
// no longer needed    for (int i=0; i <= 255; i++); // short delay 
}



void MF_R()   //  Multi-function Red
{
    digitalWrite(Multi_function_Green, LOW);
    digitalWrite(Multi_function_Yellow, LOW);  // 
    digitalWrite(Multi_function_Red, HIGH);
// no longer needed    for (int i=0; i <= 255; i++); // short delay  
}


//============================================================  
void S_G()  // Select Green 
{
    digitalWrite(Select_Green, HIGH); 
    digitalWrite(Select_Yellow, LOW);  // 
    digitalWrite(Select_Red, LOW);  //
    if (Step_Multi_Function_Button1 == 0)  
        Band_Width_W(); 
    else if (Step_Multi_Function_Button1 == 1)  
        Step_Size_100(); 
    else if (Step_Multi_Function_Button1 == 2)  
        Other_1(); 

// no longer needed    for (int i=0; i <= 255; i++); // short delay   
}



void S_Y()  // Select Yellow
{
    digitalWrite(Select_Green, LOW); 
    digitalWrite(Select_Yellow, HIGH);  // 
    digitalWrite(Select_Red, LOW);  //
    if (Step_Multi_Function_Button1 == 0) 
    {
        Band_Width_M();
    } 
    else if (Step_Multi_Function_Button1 == 1) 
    {
        Step_Size_1k(); 
    }
    else if (Step_Multi_Function_Button1 == 2) 
    {
        Other_2();
    }

// no longer needed    for (int i=0; i <= 255; i++); // short delay   
}



void S_R()  // Select Red
{
    digitalWrite(Select_Green, LOW);   //
    digitalWrite(Select_Yellow, LOW);  // 
    digitalWrite(Select_Red, HIGH);    //
    if (Step_Multi_Function_Button1 == 0) 
    {
        Band_Width_N();
    } 
    else if (Step_Multi_Function_Button1 == 1) 
    {
        Step_Size_10k(); 
    }
    else if (Step_Multi_Function_Button1 == 2) 
    {
        Other_3(); 
    }

// no longer needed    for (int i=0; i <= 255; i++); // short delay
}

//----------------------------------------------------------------------------------
void Band_Width_W()
{
    digitalWrite( Medium_A8, LOW);   // Hardware control of I.F. filter shape
    digitalWrite( Narrow_A9, LOW);   // Hardware control of I.F. filter shape
    Selected_BW = Wide_BW; 
}


//----------------------------------------------------------------------------------  
void Band_Width_M()
{
    digitalWrite( Medium_A8, HIGH);  // Hardware control of I.F. filter shape
    digitalWrite( Narrow_A9, LOW);   // Hardware control of I.F. filter shape
    Selected_BW = Medium_BW;  
}


//----------------------------------------------------------------------------------  
void Band_Width_N()
{
    digitalWrite( Medium_A8, LOW);   // Hardware control of I.F. filter shape
    digitalWrite( Narrow_A9, HIGH);  // Hardware control of I.F. filter shape
    Selected_BW = Narrow_BW; 
}


//---------------------------------------------------------------------------------- 
void Step_Size_100()      // Encoder Step Size 
{
    frequency_step = 100;   //  Can change this whatever step size one wants
    Selected_Step = Step_100_Hz; 
}


//----------------------------------------------------------------------------------  
void Step_Size_1k()       // Encoder Step Size 
{
    frequency_step = 1e3;   //  Can change this whatever step size one wants
    Selected_Step = Step_1000_hz; 
}


//----------------------------------------------------------------------------------  
void Step_Size_10k()      // Encoder Step Size 
{
    frequency_step = 10e3;    //  Can change this whatever step size one wants
    Selected_Step = Step_10000_hz; 
}


//---------------------------------------------------------------------------------- 
void Other_1()      //  User Defined Control Software 
{
    Selected_Other = Other_1_user; 
}


//----------------------------------------------------------------------------------  
void Other_2()      //  User Defined Control Software
{
    #ifdef FEATURE_BEACON
      // Start CQ after 2 seconds
      if ( Selected_Other != 1 ) 
      {
      beaconStartTime = millis() - ((BEACON_DELAY-2)*1000);  
      }
    #endif
    
    Selected_Other = Other_2_user; 
}

//----------------------------------------------------------------------------------  
void Other_3()       //  User Defined Control Software
{
    #ifdef FEATURE_BEACON
      // Start Beacon after 2 seconds
      if ( Selected_Other != 2 ) 
      {
      beaconStartTime = millis() - ((BEACON_DELAY-2)*1000);  
      }
    #endif
	
    Selected_Other = Other_3_user;
}

//-----------------------------------------------------------------------------
uint32_t TimerOverFlow(uint32_t currentTime)
{

    return (currentTime + CORE_TICK_RATE*(1));//the Core Tick Rate is 1ms

}

//-----------------------------------------------------------------------------
// ****************  Dont bother the code below  ******************************
// \/  \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/
//-----------------------------------------------------------------------------
void program_freq0(long frequency)
{
    AD9834_reset_high();  
    int flow,fhigh;
    fcalc = frequency*(268.435456e6 / Reference );    // 2^28 =
    flow = fcalc&0x3fff;              //  49.99975mhz  
    fhigh = (fcalc>>14)&0x3fff;
    digitalWrite(FSYNC_BIT, LOW);  //
    clock_data_to_ad9834(flow|AD9834_FREQ0_REGISTER_SELECT_BIT);
    clock_data_to_ad9834(fhigh|AD9834_FREQ0_REGISTER_SELECT_BIT);
    digitalWrite(FSYNC_BIT, HIGH);
    AD9834_reset_low();
}    // end   program_freq0

//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  
void program_freq1(long frequency)
{
    AD9834_reset_high(); 
    int flow,fhigh;
    fcalc = frequency*(268.435456e6 / Reference );    // 2^28 =
    flow = fcalc&0x3fff;              //  use for 49.99975mhz   
    fhigh = (fcalc>>14)&0x3fff;
    digitalWrite(FSYNC_BIT, LOW);  
    clock_data_to_ad9834(flow|AD9834_FREQ1_REGISTER_SELECT_BIT);
    clock_data_to_ad9834(fhigh|AD9834_FREQ1_REGISTER_SELECT_BIT);
    digitalWrite(FSYNC_BIT, HIGH);  
    AD9834_reset_low();
}  

//------------------------------------------------------------------------------
void clock_data_to_ad9834(unsigned int data_word)
{
    char bcount;
    unsigned int iData;
    iData=data_word;
    digitalWrite(SCLK_BIT, HIGH);  //portb.SCLK_BIT = 1;  
    // make sure clock high - only chnage data when high
    for(bcount=0;bcount<16;bcount++)
    {
        if((iData & 0x8000)) digitalWrite(SDATA_BIT, HIGH);  //portb.SDATA_BIT = 1; 
        // test and set data bits
        else  digitalWrite(SDATA_BIT, LOW);  
        digitalWrite(SCLK_BIT, LOW);  
        digitalWrite(SCLK_BIT, HIGH);     
        // set clock high - only change data when high
        iData = iData<<1; // shift the word 1 bit to the left
    }  // end for
}  // end  clock_data_to_ad9834

//-----------------------------------------------------------------------------
void AD9834_init()      // set up registers
{
    AD9834_reset_high(); 
    digitalWrite(FSYNC_BIT, LOW);
    clock_data_to_ad9834(0x2300);  // Reset goes high to 0 the registers and enable the output to mid scale.
    clock_data_to_ad9834((FREQ0_INIT_VALUE&0x3fff)|AD9834_FREQ0_REGISTER_SELECT_BIT);
    clock_data_to_ad9834(((FREQ0_INIT_VALUE>>14)&0x3fff)|AD9834_FREQ0_REGISTER_SELECT_BIT);
    clock_data_to_ad9834(0x2200); // reset goes low to enable the output.
    AD9834_reset_low();
    digitalWrite(FSYNC_BIT, HIGH);  
}  //  end   init_AD9834()

//----------------------------------------------------------------------------   
void AD9834_reset()
{
    digitalWrite(RESET_BIT, HIGH);  // hardware connection
    for (int i=0; i <= 2048; i++);  // small delay

    digitalWrite(RESET_BIT, LOW);   // hardware connection
}

//-----------------------------------------------------------------------------
void AD9834_reset_low()
{
    digitalWrite(RESET_BIT, LOW);
}

//..............................................................................     
void AD9834_reset_high()
{  
    digitalWrite(RESET_BIT, HIGH);
}
//^^^^^^^^^^^^^^^^^^^^^^^^^  DON'T BOTHER CODE ABOVE  ^^^^^^^^^^^^^^^^^^^^^^^^^ 
//=============================================================================
