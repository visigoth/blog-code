#import <Foundation/Foundation.h>

void testQueueSuspensionFromSelf()
{
  NSLog(@"== suspend from self ==");
  dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);

  dispatch_async(queue, ^{
      NSLog(@"suspending");
      dispatch_suspend(queue);
    });

  dispatch_async(queue, ^{
      NSLog(@"should have suspended");
    });

  sleep(5);
}

void testExternalQueueSuspensionWaitsForPendingBlocks()
{
  NSLog(@"== suspend externally ==");
  dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);

  __block BOOL cont = NO;

  dispatch_async(queue, ^{
      volatile BOOL *pc = &cont;
      NSLog(@"started");
      while (!(*pc)) {
        sleep(1);
      }
      NSLog(@"exiting");
    });

  // Allow it to start
  sleep(1);

  dispatch_async(queue, ^{
      NSLog(@"second block");
    });

  // Suspend the queue
  NSLog(@"suspending");
  dispatch_suspend(queue);

  // Allow it to continue.  If dispatch_suspend waits, the app should be hung.
  // If it does not, "exiting" will be printed.
  cont = YES;

  sleep(5);
}

void main(void)
{
  testQueueSuspensionFromSelf();
  testExternalQueueSuspensionWaitsForPendingBlocks();
}










