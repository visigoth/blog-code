#!/usr/bin/env bash

clang -framework Foundation -fobjc-arc -o nsthread_nscondition nsthread_nscondition.m
clang -framework Foundation -fno-objc-arc -o nsthread_nscondition nsthread_autorelease.m
clang -framework Foundation -fobjc-arc -o nsthread_notification nsthread_notification.m
clang -framework Foundation -fobjc-arc -o pthread pthread.m
