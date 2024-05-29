# Test build

This is an unsigned, intel only test build.

- Download the ZIP:

https://github.com/Desbeers/ChordProMac/raw/main/TestBuild/ChordProMac%202024-05-29%2011-49-32.zip

- Unzip it

YOU CANNOT JUST OPEN THE APPLICATION!

- `right-click` the application and choose ‘open’
- You will get a warning that the application is not verified and you are suggested to move int to the bin. Press `cancel`
- `right-click` again and choose ‘open’ again.
- Now you can choose ‘open anyway’ and the application should start.

Next time you can just open it without any warnings.

I’ve tested this on a fresh created macOS account and it seems to work.

Even though the build is `Intel` only it will run on arm-macs as well. The reason I cannot make a universal binary is that an unsigned arm-version will simply refuse to open...