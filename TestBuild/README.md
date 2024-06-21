# Test build

## Notice:

**As of 14 June 2024, the TestBuilds only work proper on Apple Silicone**

Reason is that I rebuild the **ChordPro** core on my M1 mac so the core is *arm* only at the moment. That will be fixed for any official release in the future.

**As of 21 June 2024, the TestBuilds might not work at all because I'm battling code-signing**

You might get the application running by downloading, moving to `Applications`. NOT OPENING IT, go to terminal and enter:

    codesign --force --deep -s - /Applications/ChordPro.app 
    
Then open with the usual right-click... If working, you run a full Arm version

---

This is an unsigned, ~~intel only~~ test build for macOS 12 and later.

- Download the dmg and open it.
- Move the application to wherever you want it.

YOU CANNOT JUST OPEN THE APPLICATION!

- `right-click` the application and choose ‘open’
- You will get a warning that the application is not verified and you are suggested to move int to the bin. Press `cancel`
- `right-click` again and choose ‘open’ again.
- Now you can choose ‘open anyway’ and the application should start.

Next time you can just open it without any warnings.

I’ve tested this on a fresh created macOS account and it seems to work.

~~Even though the build is `Intel` only it will run on arm-macs as well. The reason I cannot make a universal binary is that an unsigned arm-version will simply refuse to open...~~
