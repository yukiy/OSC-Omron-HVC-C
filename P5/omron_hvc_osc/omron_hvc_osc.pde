//edited by Yuki based on library example oscP5sendReceive
//http://smash-panic.com/creativenture/mylog/?p=62
/**
 * oscP5sendreceive by andreas schlegel
 * example shows how to send and receive osc messages.
 * oscP5 website at http://www.sojamo.de/oscP5
 */


import oscP5.*;
import netP5.*;
import processing.video.*;

OscP5 oscP5;
NetAddress myRemoteLocation;
Capture cam;
int omronW = 640;
int omronH = 480;

HvcP5 hvc = new HvcP5();

void setup() {
  frameRate(30);
  size(omronW, omronH);
  smooth();
  cam = new Capture(this, width, height);
  cam.start();

  /* start oscP5, listening for incoming messages at port 8000 */
  oscP5 = new OscP5(this, 8000);

  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  myRemoteLocation = new NetAddress("192.168.0.5", 6666);
}


void draw() {
//  background(0);
if(cam.available()){
  cam.read();
  image(cam, 0, 0);
}
  stroke(255, 0, 0);
  noFill();

  for(int i=0; i<hvc.sizeFace; i++){
    int x = hvc.face[i].posX;
    int y = hvc.face[i].posY;
    rect(x, y, hvc.face[i].size, hvc.face[i].size);
    fill(255,0,0);
    text("SEX: " + hvc.face[i].gender, x, y+20);
    text("AGE: " + hvc.face[i].age, x, y+40);
    text("EXP: " + hvc.face[i].expression, x, y+60);
  }  
}

void mousePressed() {
  /* in the following different ways of creating osc messages are shown by example */
  OscMessage myMessage = new OscMessage("/test");
  myMessage.add(123); /* add an int to the osc message */
  /* send the message */
  oscP5.send(myMessage, myRemoteLocation);
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
//  println("### received an osc message.");
  hvc.readOSC(theOscMessage);
}


void printVal(OscMessage theOscMessage) {
  String typetag = theOscMessage.typetag();
  if (typetag.equals("s")) {
    String strVal = theOscMessage.get(0).stringValue();
    println(strVal);
  }
  if (typetag.equals("i")) {
    int intVal = theOscMessage.get(0).intValue();
    println(intVal);
  }
}


