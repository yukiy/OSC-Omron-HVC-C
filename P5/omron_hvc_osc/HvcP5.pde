class HvcP5 {
  int sizeBody = 0;
  int sizeHand = 0;
  int sizeFace = 0;
  
  int faceSize = 0;
  int facePosX = 0;
  int facePosY = 0;
  
  Body[] body = new Body[35];
  Hand[] hand = new Hand[35];
  Face[] face = new Face[35];

  HvcP5() {
    for(int i=0; i<35; i++){
      body[i] = new Body();
      hand[i] = new Hand();
      face[i] = new Face();
    }
    
    this.init();
  }
  
  void init(){
    this.sizeBody = 0;
    this.sizeHand = 0;
    this.sizeFace = 0;
    this.faceSize = 0;
    this.facePosX = 0;
    this.facePosY = 0;
    for(int i=0; i<35; i++){
      body[i].init();
      hand[i].init();
      face[i].init();
    }
  }

  void readOSC(OscMessage theOscMessage) {
    String addr = theOscMessage.addrPattern();
    String typetag = theOscMessage.typetag();
    //println(addr);
    if (addr.equals("/size/body")) {
      this.sizeBody = theOscMessage.get(0).intValue();
    }
    if (addr.equals("/size/hand")) {
      this.sizeHand = theOscMessage.get(0).intValue();
    }
    if (addr.equals("/size/face")) {
      this.sizeFace = theOscMessage.get(0).intValue();
    }


    for(int i=0; i<this.sizeBody; i++){
      if (addr.equals("/body/"+i+"/size")) {
        this.body[i].size = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/body/"+i+"/position/x")) {
        this.body[i].posX = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/body/"+i+"/position/y")) {
        this.body[i].posY = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/body/"+i+"/confidence")) {
        this.body[i].conf = theOscMessage.get(0).intValue();
      }
    }
    
    for(int i=0; i<this.sizeHand; i++){
      if (addr.equals("/hand/"+i+"/size")) {
        this.hand[i].size = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/hand/"+i+"/position/x")) {
        this.hand[i].posX = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/hand/"+i+"/position/y")) {
        this.hand[i].posY = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/hand/"+i+"/confidence")) {
        this.hand[i].conf = theOscMessage.get(0).intValue();
      }
    }

    for(int i=0; i<this.sizeFace; i++){
      if (addr.equals("/face/"+i+"/size")) {
        this.face[i].size = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/position/x")) {
        this.face[i].posX = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/position/y")) {
        this.face[i].posY= theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/confidence")) {
        this.face[i].conf = theOscMessage.get(0).intValue();
      }

      if (addr.equals("/face/"+i+"/direction/yaw")) {
        this.face[i].yaw = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/direction/pitch")) {
        this.face[i].pitch = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/direction/roll")) {
        this.face[i].roll= theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/direction/confidence")) {
        this.face[i].directionConf = theOscMessage.get(0).intValue();
      }

      if (addr.equals("/face/"+i+"/age/age")) {
        this.face[i].age = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/age/confidence")) {
        this.face[i].ageConf = theOscMessage.get(0).intValue();
      }

      if (addr.equals("/face/"+i+"/gender/gender")) {
        this.face[i].gender = theOscMessage.get(0).stringValue();
      }
      if (addr.equals("/face/"+i+"/gender/confidence")) {
        this.face[i].genderConf = theOscMessage.get(0).intValue();
      }

      if (addr.equals("/face/"+i+"/gaze/LR")) {
        this.face[i].gazeLR = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/gaze/UD")) {
        this.face[i].gazeUD = theOscMessage.get(0).intValue();
      }

      if (addr.equals("/face/"+i+"/blink/ratioL")) {
        this.face[i].blinkL = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/blink/ratioR")) {
        this.face[i].blinkR = theOscMessage.get(0).intValue();
      }    

      if (addr.equals("/face/"+i+"/expression/expression")) {
        this.face[i].expression = theOscMessage.get(0).stringValue();
      }
      if (addr.equals("/face/"+i+"/expression/score")) {
        this.face[i].score = theOscMessage.get(0).intValue();
      }
      if (addr.equals("/face/"+i+"/expression/degree")) {
        this.face[i].degree = theOscMessage.get(0).intValue();
      }
    }

  }


  class Body {
    int size;
    int posX;
    int posY;
    int conf;
    Body(){}
    void init(){
      this.size = 0;
      this.posX = 0;
      this.posY = 0;
      this.conf = 0;
    }
  }

  class Hand {
    int size;
    int posX;
    int posY;
    int conf;
    Hand(){}
    void init(){
      this.size = 0;
      this.posX = 0;
      this.posY = 0;
      this.conf = 0;
    }

  }

  class Face {
    int size;
    int posX;
    int posY;
    int conf;
    int yaw;
    int pitch;
    int roll;
    int directionConf;
    int age;
    int ageConf;
    String gender;
    int genderConf;
    int gazeLR;
    int gazeUD;
    int blinkL;
    int blinkR;
    String expression;
    int score;
    int degree;
    Face(){}
    void init(){
      this.size = 0;
      this.posX = 0;
      this.posY = 0;
      this.conf = 0;
      this.yaw = 0;
      this.pitch = 0;
      this.roll = 0;
      this.directionConf = 0;
      this.age = 0;
      this.ageConf = 0;
      this.gender = "";
      this.genderConf = 0;
      this.gazeLR = 0;
      this.gazeUD = 0;
      this.blinkL = 0;
      this.blinkR = 0;
      this.expression = "";
      this.score = 0;
      this.degree = 0;
    }

  }


}




