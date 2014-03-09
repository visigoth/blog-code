#import <Foundation/Foundation.h>
#include <unistd.h>

@interface ThreadedComponent : NSObject
- (void)start;
- (void)stop;
@end

@implementation ThreadedComponent
{
  NSThread *_thread;
  NSCondition *_condition;
}

- (void)start
{
  _thread = [[NSThread alloc] initWithTarget:self
                                    selector:@selector(threadProc:)
                                      object:nil];
  _condition = [[NSCondition alloc] init];

  [_condition lock];
  [_thread start];
  [_condition wait];
  [_condition unlock];

  NSLog(@"thread should have started");
}

- (void)stop
{
  [_condition lock];
  [_thread cancel];
  [self performSelector:@selector(_stop)
               onThread:_thread
             withObject:nil
          waitUntilDone:NO];
  [_condition wait];
  [_condition unlock];

  NSLog(@"thread should have stopped");
}

#pragma mark Private Helpers

static void DoNothingRunLoopCallback(void *info)
{
}

- (void)threadProc:(id)object
{
  @autoreleasepool {
    CFRunLoopSourceContext context = {0};
    context.perform = DoNothingRunLoopCallback;

    CFRunLoopSourceRef source = CFRunLoopSourceCreate(NULL, 0, &context);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);

    [_condition lock];
    [_condition signal];
    NSLog(@"thread has started");
    [_condition unlock];

    while (![[NSThread currentThread] isCancelled]) {
      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                               beforeDate:[NSDate distantFuture]];
    }

    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    CFRelease(source);

    [_condition lock];
    [_condition signal];
    NSLog(@"thread has stopped");
    [_condition unlock];
  }
}

- (void)_stop
{
  CFRunLoopStop(CFRunLoopGetCurrent());
}

@end

int main(int argc, char *argv[])
{
  ThreadedComponent *component = [[ThreadedComponent alloc] init];
  [component start];

  NSLog(@"will stop in 3 seconds");

  sleep(3);
  [component stop];

  return 0;
}
