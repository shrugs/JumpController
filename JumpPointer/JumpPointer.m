#import "JumpPointer.h"
#import "../SimulateTouch/SimulateTouch.h"

#define CURSOR_WIDTH 10
#define CURSOR_HEIGHT 10

@implementation JumpPointer
{
    int lastPath;
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(100, 100, CURSOR_WIDTH, CURSOR_HEIGHT)];
    if (self) {
        self.backgroundColor = [UIColor redColor];
    }
    return self;
}

- (void)click
{
    int r = [SimulateTouch simulateTouch:0 atPoint:self.frame.origin withType: STTouchDown];
    [SimulateTouch simulateTouch:r atPoint:self.frame.origin withType: STTouchUp];
}

- (void)down
{
    lastPath = [SimulateTouch simulateTouch:0 atPoint:self.frame.origin withType: STTouchDown];
}

- (void)up
{
    [SimulateTouch simulateTouch:lastPath atPoint:self.frame.origin withType: STTouchUp];
}

- (void)move
{
    [SimulateTouch simulateTouch:lastPath atPoint:self.frame.origin withType: STTouchMove];
}

@end