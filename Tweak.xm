
#import <iOS/iOS7/SpringBoard/SBUIController.h>

#import <iOS/iOS7/PrivateFrameworks/AppSupport/CPDistributedMessagingCenter.h>
#import <RocketBootstrap/rocketbootstrap.h>
#import <libactivator/LAActivator.h>
#import <libactivator/LAEvent.h>

#import "JumpPointer/JumpPointer.h"
#import "Jump/Jump.h"
#import "SimulateTouch/SimulateTouch.h"
#import "NSObject+Debounce/NSObject+Debounce.h"

#define MAX_FINGER_TIPS_DISTANCE 80.0
#define SWIPE_THRESH 0.7

#define ACTUALLY_DO_THINGS YES

static Jump *myJump;
// static CPDistributedMessagingCenter *messagingCenter;

@interface JumpDelegate : NSObject <JumpDelegate>
{
    BOOL potentialGesture;
    CGRect screenFrame;
    JumpPointer *cursor;
    BOOL clickState;
}
@end

@implementation JumpDelegate
- (id)init
{
    self = [super init];
    if (self) {
        potentialGesture = NO;
        cursor = [[JumpPointer alloc] init];
        [[[%c(SBUIController) sharedInstance] window] addSubview: cursor];
        clickState = NO;
    }
    return self;
}

- (CGPoint)leapFrame:(LeapFrame *)frame pointToScreen:(CGPoint)leapPoint
{
    if (screenFrame.size.width == 0) {
        screenFrame = [UIScreen mainScreen].bounds;
    }
    float left = frame.interactionBox.center.x - frame.interactionBox.size.x/2.0;
    float top = frame.interactionBox.center.z - frame.interactionBox.size.z/2.0;

    float x = leapPoint.x - left;
    float y = leapPoint.y - top;

    // scale to [0..1]
    x = x / frame.interactionBox.size.x;
    y = y / frame.interactionBox.size.z;

    x = x * (float)screenFrame.size.width;
    y = y * (float)screenFrame.size.height - 200.0;

    // NSLog(@"x:%f, y:%f", x, y);

    return CGPointMake(x, y);
}

- (void)jump:(Jump *)jump gotFrame:(LeapFrame *)frame
{
    if (!ACTUALLY_DO_THINGS) {
        return;
    }

    static float initialClickPosition;

    // CURSOR
    LeapVector *cursorV = nil;
    if ([frame.pointables count] == 1) {
        cursorV = [(LeapPointable *)frame.pointables[0] tipPosition];
    } else if ([frame.hands count] > 0) {
        cursorV = [(LeapHand *)frame.hands[0] palmPosition];
    }

    CGPoint cursorPoint = CGPointMake(0, 0);
    if (cursorV) {
        cursorPoint = [self leapFrame:frame pointToScreen:CGPointMake(cursorV.x, cursorV.z)];
        cursor.frame = CGRectMake(cursorPoint.x, cursorPoint.y, 10, 10);
    }

    if (clickState) {
        // send move event to location
        [cursor move];
        // check for moving behind thresh
        if (cursorV.y >= initialClickPosition) {
            // send let up
            clickState = NO;
            [cursor up];
            NSLog(@"UNCLICK");
        }
    }


    if ([frame.gestures count] > 0) {
        LeapGesture *g = (LeapGesture *)frame.gestures[0];
        if ([frame.pointables count] == 1 && [g type] == LEAP_GESTURE_TYPE_KEY_TAP && [g state] == LEAP_GESTURE_STATE_STOP) {
            [cursor click];
        } else if ([frame.pointables count] >= 4 && [g type] == LEAP_GESTURE_TYPE_SWIPE && [g state] == LEAP_GESTURE_STATE_STOP) {
            LeapSwipeGesture *gesture = frame.gestures[0];
            JumpGestureDirection direction = [self getDirection: [gesture direction]];
            switch (direction) {
                case JumpGestureDirectionUp:
                    [self debounce:@selector(switcher) delay:0.1];
                    break;

                case JumpGestureDirectionDown:
                    [self debounce:@selector(homeButton) delay:0.1];
                    break;

                case JumpGestureDirectionOut:
                    [self debounce:@selector(swipeUp) delay:0.1];
                    break;

                case JumpGestureDirectionIn:
                    [self debounce:@selector(swipeDown) delay:0.1];
                    break;

                case JumpGestureDirectionLeft:
                    [self debounce:@selector(swipeLeft) delay:0.1];
                    break;

                case JumpGestureDirectionRight:
                    [self debounce:@selector(swipeRight) delay:0.1];
                    break;

                default:
                    break;
            }
        }// else if ([frame.pointables count] == 1 && [g type] == LEAP_GESTURE_TYPE_CIRCLE && [g state] == LEAP_GESTURE_STATE_STOP) {
        //     LeapCircleGesture *gesture = frame.gestures[0];
        //     LeapVector *normal = [gesture normal];
        //     LeapPointable *p = frame.pointables[0];
        //     if ([p.direction dot:normal] > 0) {
        //         // clickwise
        //         [self debounce:@selector(notificationCenter) delay:0.1];
        //     } else {
        //         [self debounce:@selector(controlCenter) delay:0.1];
        //     }
        // }
    } else if ([frame.pointables count] == 1) {
        // LOOK FOR HOLD
        LeapPointable *p = frame.pointables[0];
        if ([p tipVelocity].y < -1100) {
            NSLog(@"x:%f, y:%f, z:%f", p.tipVelocity.x, p.tipVelocity.y, p.tipVelocity.z);
            [self debounce:@selector(downClick) delay: 0.2];
            initialClickPosition = [p tipPosition].y;
        }
    }






    // if ([frame.gestures count] > 0) {
    //     // NUMBER OF FINGERS
    //     switch ([frame.pointables count]) {
    //         case 2: {
    //             LeapGesture *baseGesture = frame.gestures[0];
    //             switch (baseGesture.type) {
    //                 // GESTURE TYPE
    //                 case LEAP_GESTURE_TYPE_SWIPE: {
    //                     LeapSwipeGesture *gesture = frame.gestures[0];
    //                     JumpGestureDirection direction = [self getDirection:gesture.direction];
    //                     // GESTURE STATE
    //                     switch (baseGesture.state) {
    //                         case LEAP_GESTURE_STATE_START: {
    //                             // start the touches based on direction
    //                             NSLog(@"New Gesture...");
    //                             switch (direction) {
    //                                 case JumpGestureDirectionUp:
    //                                     // start at bottom
    //                                     initialPoint = CGPointMake(screenFrame.size.width/2, screenFrame.size.height - 5);
    //                                     break;

    //                                 case JumpGestureDirectionLeft:
    //                                     // start at right side
    //                                     initialPoint = CGPointMake(screenFrame.size.width + 5, screenFrame.size.height/2);
    //                                     break;

    //                                 case JumpGestureDirectionRight:
    //                                     // start left
    //                                     initialPoint = CGPointMake(5, screenFrame.size.height/2);
    //                                     break;

    //                                 case JumpGestureDirectionDown:
    //                                     initialPoint = CGPointMake(screenFrame.size.width/2, 5);
    //                                     break;

    //                                 default:
    //                                     break;
    //                             }
    //                             NSLog(@"Initial Point: %@", NSStringFromCGPoint(initialPoint));
    //                             [SimulateTouch simulateTouch:0 atPoint:initialPoint withType: STTouchMove];

    //                             break;
    //                         }

    //                         case LEAP_GESTURE_STATE_STOP:
    //                             NSLog(@"End Gesture.");
    //                             // stop touches based on direction
    //                             // I guess don't do anything?
    //                             break;

    //                         default:
    //                             //  get translation
    //                             float translation = [gesture.startPosition distanceTo:gesture.position];
    //                             CGPoint newPoint;
    //                             switch (direction) {
    //                                 case JumpGestureDirectionUp:
    //                                     // only care about y axis delt
    //                                     newPoint = CGPointMake(initialPoint.x, initialPoint.y - translation);
    //                                     break;

    //                                 case JumpGestureDirectionDown:
    //                                     newPoint = CGPointMake(initialPoint.x, initialPoint.y + translation);
    //                                     break;

    //                                 case JumpGestureDirectionLeft:
    //                                     newPoint = CGPointMake(initialPoint.x - translation, initialPoint.y);
    //                                     break;

    //                                 case JumpGestureDirectionRight:
    //                                     newPoint = CGPointMake(initialPoint.x + translation, initialPoint.y);
    //                                     break;

    //                                 default:
    //                                     break;
    //                             }
    //                             NSLog(@"New Point: %@", NSStringFromCGPoint(newPoint));
    //                             [SimulateTouch simulateTouch:0 atPoint:newPoint withType: STTouchMove];

    //                             break;
    //                     }
    //                     break;
    //                 }

    //                 default:

    //                     break;
    //             }
    //             break;
    //         }
    //     }
    // }

}

- (void)swipeDown
{
    [SimulateTouch simulateSwipeFromPoint:CGPointMake(screenFrame.size.width/2, 100) toPoint:CGPointMake(screenFrame.size.width/2, screenFrame.size.height - 100) duration:0.3];
}

- (void)swipeUp
{
    [SimulateTouch simulateSwipeFromPoint:CGPointMake(screenFrame.size.width/2, screenFrame.size.height - 100) toPoint:CGPointMake(screenFrame.size.width/2, 100) duration:0.3];
}

- (void)downClick
{
    NSLog(@"CLICK");
    [cursor down];
    clickState = YES;
}

- (void)switcher
{
    [[LAActivator sharedInstance] sendEvent:[LAEvent eventWithName:@"blah"] toListenerWithName: @"libactivator.system.activate-switcher"];
}

- (void)controlCenter
{
    [[LAActivator sharedInstance] sendEvent:[LAEvent eventWithName:@"blah"] toListenerWithName: @"libactivator.system.activate-control-center"];
}

- (void)homeButton
{
    [[LAActivator sharedInstance] sendEvent:[LAEvent eventWithName:@"test"] toListenerWithName: @"libactivator.system.homebutton"];
}

- (void)notificationCenter
{
    [[LAActivator sharedInstance] sendEvent:[LAEvent eventWithName:@"blah"] toListenerWithName: @"libactivator.system.activate-notification-center"];
}

- (void)swipeLeft
{
    [SimulateTouch simulateSwipeFromPoint:CGPointMake(screenFrame.size.width - 5, screenFrame.size.height/2) toPoint:CGPointMake(5, screenFrame.size.height/2) duration:0.3];
}

- (void)swipeRight
{

    [SimulateTouch simulateSwipeFromPoint:CGPointMake(5, screenFrame.size.height/2) toPoint:CGPointMake(screenFrame.size.width - 5, screenFrame.size.height/2) duration:0.3];
}

- (JumpGestureDirection)getDirection:(LeapVector *)vector
{
    NSLog(@"x:%f, y:%f, z:%f", vector.x, vector.y, vector.z);
    if (vector.x > SWIPE_THRESH) {
        return JumpGestureDirectionRight;
    } else if (vector.x < -SWIPE_THRESH) {
        return JumpGestureDirectionLeft;
    } else if (vector.y > SWIPE_THRESH) {
        return JumpGestureDirectionUp;
    } else if (vector.y < -SWIPE_THRESH) {
        return JumpGestureDirectionDown;
    } else if (vector.z < -0.5) {
        return JumpGestureDirectionOut;
    } else if (vector.z > SWIPE_THRESH) {
        return JumpGestureDirectionIn;
    } else {
        return JumpGestureDirectionNone;
    }
}

@end

%hook SBUIController

- (void)finishLaunching
{
    %orig;
    NSLog(@"PAY ATTENTION BELOW ME");
    if (!myJump) {
        myJump = [[Jump alloc] init];
        [myJump setDelegate:[[JumpDelegate alloc] init]];
        [myJump jump];
    }
    // Create Messaging Center for disributing Leap Events to applications
    // messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.shrugs.jumpcontroller"];
    // rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
    // [messagingCenter runServerOnCurrentThread];

    // @TODO(Shrugs) pipe information over messaging center to apps so they can handle it if necessary

    // @TODO(Shrugs) also set up handles for springboard (touching, switcher activation, notification center, etc)
    // [messagingCenter registerForMessageName:@""
    //                                    target:self
    //                                  selector:@selector(mb_handleMessageBoxMessage:withUserInfo:)];
}


%end