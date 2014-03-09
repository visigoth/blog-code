#import <Foundation/Foundation.h>
#include <mach/thread_act.h>
#include <pthread.h>
#include <unistd.h>

@interface ThreadedComponent : NSObject
- (void)start;
- (void)stop;
- (void)threadProc:(id)object;
@end

static void *ThreadProc(void *arg)
{
  ThreadedComponent *component = (__bridge_transfer ThreadedComponent *)arg;
  [component threadProc:nil];
  return NULL;
}

@implementation ThreadedComponent
{
  pthread_t _pthread;
  NSThread *_thread;
  NSCondition *_condition;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _condition = [[NSCondition alloc] init];
  }

  return self;
}

- (void)dealloc
{
  [self stop];
}

- (void)start
{
  if (_thread) {
    return;
  }

  if (pthread_create_suspended_np(&_pthread, NULL, &ThreadProc, (__bridge_retained void *)self) != 0) {
    return;
  }

  [_condition lock];
  mach_port_t mach_thread = pthread_mach_thread_np(_pthread);
  thread_resume(mach_thread);
  [_condition wait];
  [_condition unlock];

  NSLog(@"thread should have started");
}

- (void)stop
{
  if (!_thread) {
    return;
  }

  [self performSelector:@selector(_stop)
               onThread:_thread
             withObject:nil
          waitUntilDone:NO];
  pthread_join(_pthread, NULL);
  _thread = nil;

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

    // Obtain the current NSThread before signaling startup is complete.
    _thread = [NSThread currentThread];

    [_condition lock];
    [_condition signal];
    NSLog(@"thread has started");
    [_condition unlock];

    CFRunLoopRun();

    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    CFRelease(source);

    NSLog(@"thread about to exit");
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
