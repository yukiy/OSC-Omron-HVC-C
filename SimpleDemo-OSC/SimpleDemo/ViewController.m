/*
 * Copyright (C) 2014 OMRON Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  ViewController.m
//  SimpleDemo
//

#import "ViewController.h"
#import "VVOSC/include/VVOSC.h"


@interface ViewController ()
{
    int Status;
    HVC_FUNCTION ExecuteFlag;
}
@property HVC_BLE *HvcBLE;

//---OSC
@property(nonatomic, retain) OSCManager *oscManager;
@property(nonatomic, retain) OSCOutPort *outport;
@property(nonatomic, retain) OSCInPort *inport;


@end

@implementation ViewController

@synthesize HvcBLE = _HvcBLE;

- (void)viewDidLoad {
    Status = 0;
    ExecuteFlag = 0;
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.HvcBLE = [[HVC_BLE alloc] init];
    self.HvcBLE.delegateHVC = self;
    
    _ResultTextView.text = @"";


    //---OSC
    //---Send
    self.oscManager = [[OSCManager alloc] init];
    self.oscManager.delegate = self;
    self.outport = [self.oscManager createNewOutputToAddress:@"192.168.0.5" atPort:8000];
    
    
    //---Receive
    self.inport = [self.oscManager createNewInputForPort:6666];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





- (IBAction)pushButton:(UIButton *)sender {
    switch ( Status )
    {
        case 0:
            // disconnect -> connect
            [self.HvcBLE deviceSearch];
            [self.pushbutton setTitle:@"disconnect" forState:UIControlStateNormal ];
            Status = 1;
            break;
        case 1:
            // connect -> disconnect
            [self.HvcBLE disconnect];
            [self.pushbutton setTitle:@"connect" forState:UIControlStateNormal];
            Status = 0;
            return;
        case 2:
            return;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (int i=0; i<10; i++) {
            sleep(1);
        }
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    //dispatch_release(semaphore);
    
    // Make alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connect Device"
                                              message:@"Select HVC"
                                              delegate:self
                                              cancelButtonTitle:@"cancel"
                                              otherButtonTitles:nil];
    
    NSMutableArray *deviseList = [self.HvcBLE getDevices];
    for( int i = 0; i < deviseList.count; i++ )
    {
        NSString *name = ((CBPeripheral *)deviseList[i]).name;
        [alert addButtonWithTitle:name];
    }
    
    // Show alert
    [alert show];
}

// Delegate method of the alert
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        // cancel button
        NSLog(@"push cancel");
        [self.pushbutton setTitle:@"connect" forState:UIControlStateNormal];
        Status = 0;
    } else {
        NSMutableArray *deviseList = [self.HvcBLE getDevices];
        [self.HvcBLE connect:deviseList[buttonIndex-1]];
        [self.pushbutton setTitle:@"disconnect" forState:UIControlStateNormal];
        Status = 1;
    }
}

- (IBAction)btnExecute_click:(UIButton *)sender {
    switch ( Status )
    {
        case 0:
            return;
        case 1:
            [self.btnExecution setTitle:@"stop" forState:UIControlStateNormal];
            Status = 2;
            break;
        case 2:
            [self.btnExecution setTitle:@"start" forState:UIControlStateNormal];
            Status = 1;
            return;
    }
    
    HVC_PRM *param = [[HVC_PRM alloc] init];
    param.face.MinSize = 60;
    param.face.MaxSize = 480;
    
    [self.HvcBLE setParam:param];
}

- (void)onConnected
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SUCCESS" message:@"Connected"
                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}
- (void)onDisconnected
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SUCCESS" message:@"Disconnected"
                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}
- (void)onPostGetDeviceName:(NSData *)value
{
    
}

- (void)onPostSetParam:(HVC_ERRORCODE)err status:(unsigned char)outStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Set Execute Flag
        ExecuteFlag = HVC_ACTIV_BODY_DETECTION | HVC_ACTIV_HAND_DETECTION | HVC_ACTIV_FACE_DETECTION
                        | HVC_ACTIV_FACE_DIRECTION | HVC_ACTIV_AGE_ESTIMATION | HVC_ACTIV_GENDER_ESTIMATION
                        | HVC_ACTIV_GAZE_ESTIMATION | HVC_ACTIV_BLINK_ESTIMATION | HVC_ACTIV_EXPRESSION_ESTIMATION;
        
        HVC_RES *res = [[HVC_RES alloc] init];
        [self.HvcBLE Execute:ExecuteFlag result:res];
    });
}
- (void)onPostGetParam:(HVC_PRM *)param errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus
{
    
}
- (void)onPostGetVersion:(HVC_VER *)ver errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus
{
    
}

-(void) onPostExecute:(HVC_RES *)result errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus
{
    // Receive data of result
    NSString *resStr = @"";

    OSCMessage *message;
    NSString *oscStr;
    
    if((err == HVC_NORMAL) && (outStatus == 0)){
        
        // Human body detection
        resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"Body Detect = %d\n", result.sizeBody]];

        message = [OSCMessage createWithAddress:@"/size/body"];
        [message addInt:result.sizeBody];
        [self.outport sendThisPacket:[OSCPacket createWithContent:message]];

        for(int i = 0; i < result.sizeBody; i++){
            DetectionResult *dt = [result body:i];

            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Body Detection] : size = %d, ", dt.size]];
            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"x = %d, y = %d, ", dt.posX, dt.posY]];
            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"conf = %d\n", dt.confidence]];

            message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/body/%d/size", i]];
            [message addInt:dt.size];
            [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            
            message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/body/%d/position/x", i]];
            [message addInt:dt.posX];
            [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/body/%d/position/y", i]];
            [message addInt:dt.posY];
            [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            
            message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/body/%d/confidence", i]];
            [message addInt:dt.confidence];
            [self.outport sendThisPacket:[OSCPacket createWithContent:message]];

        }
        
        // Hand detection
        resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"Hand Detect = %d\n", result.sizeHand]];

        message = [OSCMessage createWithAddress:@"/size/hand"];
        [message addInt:result.sizeHand];
        [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
        
        for(int i = 0; i < result.sizeHand; i++){
            DetectionResult *dt = [result hand:i];
            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Hand Detection] : size = %d, ", dt.size]];
            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"x = %d, y = %d, ", dt.posX, dt.posY]];
            resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"conf = %d\n", dt.confidence]];

            message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/hand/%d/size", i]];
            [message addInt:dt.size];
            [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            
            message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/hand/%d/position/x", i]];
            [message addInt:dt.posX];
            [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/hand/%d/position/y", i]];
            [message addInt:dt.posY];
            [self.outport sendThisPacket:[OSCPacket createWithContent:message]];

            message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/hand/%d/confidence", i]];
            [message addInt:dt.confidence];
            [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
        
        }

        // Face detection & estimation
        resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"Face Detect = %d\n", result.sizeFace]];

        message = [OSCMessage createWithAddress:@"/size/face"];
        [message addInt:result.sizeFace];
        [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
        
        for(int i = 0; i < result.sizeFace; i++){
            FaceResult *fd = [result face:i];
            // Face detection
            if((result.executedFunc & HVC_ACTIV_FACE_DETECTION) != 0){
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Face Detection] : size = %d, ", fd.size]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"x = %d, y = %d, ", fd.posX, fd.posY]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"conf = %d\n", fd.confidence]];

                message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/face/%d/size", i]];
                [message addInt:fd.size];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/face/%d/position/x", i]];
                [message addInt:fd.posX];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/face/%d/position/y", i]];
                [message addInt:fd.posY];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress: [NSString stringWithFormat:@"/face/%d/confidence", i]];
                [message addInt:fd.confidence];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            
            }
            
            // Face direction estimation
            if((result.executedFunc & HVC_ACTIV_FACE_DIRECTION) != 0){
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Face Direction] : "]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"yaw = %d, ",  fd.dir.yaw]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"pitch = %d, ",fd.dir.pitch]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"roll = %d, ", fd.dir.roll]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"conf = %d\n", fd.dir.confidence]];

                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/direction/yaw", i]];
                [message addInt:fd.dir.yaw];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/direction/position/pitch", i]];
                [message addInt:fd.dir.pitch];

                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/direction/position/roll", i]];
                [message addInt:fd.dir.roll];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/direction/confidence", i]];
                [message addInt:fd.dir.confidence];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            
            }
            
            // Age estimation
            if((result.executedFunc & HVC_ACTIV_AGE_ESTIMATION) != 0){
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Age Estimation] : "]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"age = %d, conf = %d\n", fd.age.age, fd.age.confidence]];

                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/age/age", i]];
                [message addInt:fd.age.age];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/age/confidence", i]];
                [message addInt:fd.age.confidence];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            }
            
            // Gender estimation
            if((result.executedFunc & HVC_ACTIV_GENDER_ESTIMATION) != 0){
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Gender Estimation] : "]];

                NSString *gender;
                if(fd.gen.gender == HVC_GEN_MALE){
                    gender = @"Male";
                }
                else{
                    gender = @"FeMale";
                }
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"gender = %@, conf = %d\n", gender, fd.gen.confidence]];

                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/gender/gender", i]];
                [message addString:gender];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/gender/confidence", i]];
                [message addInt:fd.gen.confidence];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            
            }
            
            // Gaze estimation
            if((result.executedFunc & HVC_ACTIV_GAZE_ESTIMATION) != 0){
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Gaze Estimation] : "]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"LR = %d, UD = %d\n", fd.gaze.gazeLR, fd.gaze.gazeUD]];

                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/gaze/LR", i]];
                [message addInt:fd.gaze.gazeLR];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];

                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/gaze/UD", i]];
                [message addInt:fd.gaze.gazeUD];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            }
            
            // Blink estimation
            if((result.executedFunc & HVC_ACTIV_BLINK_ESTIMATION) != 0){
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Blink Estimation] : "]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"ratioL = %d, ratioR = %d\n", fd.blink.ratioL, fd.blink.ratioR]];

                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/blink/ratioL", i]];
                [message addInt:fd.blink.ratioL];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/blink/ratioR", i]];
                [message addInt:fd.blink.ratioR];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            }
            
            // Expression estimation
            if((result.executedFunc & HVC_ACTIV_EXPRESSION_ESTIMATION) != 0){
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"  [Expression Estimation] : "]];
                
                NSString *expression;
                switch(fd.exp.expression){
                    case HVC_EX_NEUTRAL:
                        expression = @"Neutral";
                        break;
                    case HVC_EX_HAPPINESS:
                        expression = @"Happiness";
                        break;
                    case HVC_EX_SURPRISE:
                        expression = @"Surprise";
                        break;
                    case HVC_EX_ANGER:
                        expression = @"Anger";
                        break;
                    case HVC_EX_SADNESS:
                        expression = @"Sadness";
                        break;
                }
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"expression = %@, ", expression]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"score = %d, ", fd.exp.score]];
                resStr = [resStr stringByAppendingString:[NSString stringWithFormat:@"degree = %d\n", fd.exp.degree]];
                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/expression/expression", i]];
                [message addString:expression];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/expression/score", i]];
                [message addInt:fd.exp.score];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
                
                message = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/face/%d/expression/degree", i]];
                [message addInt:fd.exp.degree];
                [self.outport sendThisPacket:[OSCPacket createWithContent:message]];
            
            }
        }
    }
    _ResultTextView.text = resStr;

    if ( Status == 2 ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.HvcBLE Execute:ExecuteFlag result:result];
        });
    }

    
//    message = [OSCMessage createWithAddress:@"/check"];
//    [message addString:@"--//"];
//    [self.outport sendThisPacket:[OSCPacket createWithContent:message]];

    
}

@end
