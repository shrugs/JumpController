@implementation NSObject (Debounce)

- (void)debounce:(SEL)action delay:(NSTimeInterval)delay
{
  id weakSelf = self;
  [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:action object:nil];
  [weakSelf performSelector:action withObject:nil afterDelay:delay];
}

@end