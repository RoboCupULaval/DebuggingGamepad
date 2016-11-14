
import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;
import processing.serial.*;
import static javax.swing.JOptionPane.*;

ControlIO control;
Configuration config;
ControlDevice control_device;
Gamepad gpad;
Serial myPort;  // Create object from Serial class


final int WIN_WIDTH = 400;
final int WIN_HEIGHT = 240;

private int mod(int a, int b){
   return a < 0 ? b + a : a % b;
}

public class Gamepad {
   private ControlDevice device = null;
   public float x;
   public float tempx;
   public float y;
   public float rotate;
   public float rotate_y;
   public boolean kick;
   public int id;
   private final int[] VALID_IDS = { 0, 4 };
   private int id_index = 0;
   
   
   public Gamepad(ControlDevice device){
      this.device = device;
      device.getButton("ID_NEXT").plug(this, "_increase_id", ControlIO.ON_PRESS);
      device.getButton("ID_PREVIOUS").plug(this, "_decrease_id", ControlIO.ON_PRESS);
      device.getButton("KICK").plug(this, "_kick", ControlIO.ON_PRESS);
   }
   
   public void update(){
      x = -device.getSlider("Y").getValue();
      y = -device.getSlider("X").getValue();
      PVector vxy = new PVector(x, y);
      if (vxy.mag() > 1.0) {
       vxy.normalize();
       x = vxy.x;
       y = vxy.y; 
      }
      
      rotate = device.getSlider("ROTATE_X").getValue();
      rotate_y = device.getSlider("ROTATE_Y").getValue();
      PVector vRotate = new PVector(rotate, rotate_y);
      if (vRotate.mag() > 1.0) {
       vRotate.normalize();
       rotate = vRotate.x;
       rotate_y = vRotate.y; 
      }
      rotate = -rotate * 6.28; // scaling a 1 tour/sec
      //rotate_y = rotate_y * 6.28;
      
      kick = device.getButton("KICK").getValue() > 0.0;

   }
   
   public void _kick(){
      println(get_speed_command(1f, 2f, 3f, byte(6)));
   }
   
   public void _increase_id(){
      ++id_index;
      update_id();
   }
   
   public void _decrease_id(){
      --id_index;
      update_id();
   }
   
   private void update_id(){
      id_index = mod(id_index, VALID_IDS.length);
      id = VALID_IDS[id_index];
   }
   
}

String[] get_serial_list(){
  ArrayList<String> result = new ArrayList<String>();
  
  for (int i = 0; i < Serial.list().length; i++){
      String test = Serial.list()[i];
      try{
        Serial testPort = new Serial(this, test, 115200);
        testPort.stop();
        result.add(test);
      }
      catch (Exception e){}
  }
  
  return result.toArray(new String[0]);
}

void select_serial(){
 String COMx = "";
/*
  Other setup code goes here - I put this at
  the end because of the try/catch structure.
*/
  try {
    String[] serial_list = get_serial_list();
    int i = serial_list.length;
    if (i != 0) {
      String portName;
      if (i >= 2) {
        // need to check which port the inst uses -
        // for now we'll just let the user decide
        int com_index = showOptionDialog(null, "Which Serial port is correct?:", "Serial port chooser", YES_NO_CANCEL_OPTION, INFORMATION_MESSAGE, null, serial_list, serial_list[0]);
        portName = serial_list[com_index];
        println(portName);
      }
      else{
        portName = serial_list[0];
      }
      myPort = new Serial(this, portName, 115200);
    }
    else {
      showMessageDialog(frame,"Device is not connected to the PC");
      exit();
    }
  }
  catch (Exception e)
  { //Print the type of error
    showMessageDialog(frame,"COM port is not available (may\nbe in use by another program)");
    println("Error:", e);
    exit();
  } 
}

void settings(){
  size(WIN_WIDTH, WIN_HEIGHT);
}

public void setup() {
  
  select_serial();
  
  // Initialise the ControlIO
  control = ControlIO.getInstance(this);
  // Find a device that matches the configuration file
  control_device = control.getMatchedDevice("madcatz_xbox_gamepad");
  
  if (control_device == null) {
    println("No suitable device configured");
    System.exit(-1); // End the program NOW!
  }
  
  gpad = new Gamepad(control_device);
  
}

public void draw() {
  background(0, 0, 0);
  gpad.update();
  draw_stick_area(0, 0, WIN_WIDTH, int(0.8f * WIN_HEIGHT));
  draw_buttons_area(0, int(0.8f * WIN_HEIGHT), WIN_WIDTH, int(0.2f * WIN_HEIGHT));
  myPort.write(get_speed_command(gpad.x, gpad.y, gpad.rotate, byte(gpad.id)));
}

public void draw_buttons_area(int x, int y, int w, int h){
  float text_height = h*0.75;
  textSize(text_height);
  text("Id: " + str(gpad.id), x, y+text_height);
  
  text("Kick: ", x+int(0.25*w), y+text_height);
  ellipseMode(CENTER);
  if (gpad.kick){
    fill(color(255, 0, 0));
  }
  else{
    fill(color(255, 255, 255));
  }
  strokeWeight(1);
  ellipse(x+w*0.5, y+h/2, text_height*.75, text_height*.75);
}

public void draw_stick_area(int x, int y, int w, int h){
  draw_stick(int(0.25*w) + x, h/2 + y, w/2, h, gpad.x, gpad.y);
  draw_stick(int(0.75*w) + x, h/2 + y, w/2, h, gpad.rotate, gpad.rotate_y);
}

public void draw_stick(int x, int y, int w, int h, float x_coord, float y_coord){
  fill(color(255, 255, 255));
  strokeWeight(2);
  ellipseMode(CENTER);
  ellipse(x, y, w, h);
  strokeWeight(15);
  point(x+(x_coord * (w/2.0)), y+(y_coord * (h/2.0)));
}