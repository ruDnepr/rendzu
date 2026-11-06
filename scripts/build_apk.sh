#!/bin/bash
export PATH="/home/z/flutter/bin:$PATH"
export JAVA_HOME=/home/z/jdk-17.0.13+11
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME=/home/z/android-sdk
cd /home/z/my-project
flutter build apk --debug --target-platform android-arm64 2>&1
echo "EXIT_CODE=$?"
