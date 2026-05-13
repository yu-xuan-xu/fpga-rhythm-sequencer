
# Q1: Briefly summarize your work (what it is, how one uses it or interacts with it, etc.)

My project is a programmable rhythm sequencer inspired by my drumming practices. It runs on an iCE40 FPGA and uses a TM1638 I/O board for display and button input.

The rhythm sequencer allows user to choose between six tempos (60, 80, 100, 120, 140, 160 BPM) and three time signatures (2/4, 3/4, 4/4). The two leftmost buttons (key[7] and key[6]) allows users to increase or decrease the tempo as it is displayed on the leftmost three 7-segment digits. The next two buttons (key[5] and key[4]) allows users to cycle through time signatures, displayed as 0 (2/4), 1 (3/4), or 2 (4/4) on the fourth digit from the left.

When the start button (key[3]) is pressed, the rhythm sequencer plays the beats repeatedly according to the set tempo and time signature. The rightmost four digits show the current beat pattern. The active beat lights up with a dot (normal) or the number 8 (accent), while rest beats are blank.

The users, after the start button is pressed, can press the edit button (key[2]) to go into the edit mode to edit the feature of each beat. Each beat has three features, rest (no display), normal beat (dot lights up), and accent/louder beat (number 8 lights up). When the users are in the edit mode, they can press key[1] to move the cursor to the beat that they want to edit, and then they can use key[0] to change the beat to the desired feature. The features are represented 0 (rest), 1 (normal), and 2 (accent). Pressing Edit again resumes playback with the updated pattern. Pressing Start returns to idle and stops playback.

# Q2: How long did you spend on this?

I spent approximately 9 hours.

# Q3: What skills did this work help you develop or explore further?

One of the major skills that this work help me develop is always keeping the idea of modular design in mind. It trained me to break down a complex project into 6 independent modules that are easier to debug. Another important aspect is understanding when to use sequential logic and when to use combinational logic. I also got to think more about FSM designs and creating lookup tables for clock dividing and timing.

# Q4: Did you learn or discover anything new from this work that hadn't been covered earlier in the course?

This work helped me learn how to connect multiple modules together in a single top-level file, since in previous assignments, we mostly only had to modify single-module designs. Another very important thing is the power-on reset design. When the FPGA powers on, por_cnt is initialized to 0. Since bit 3 is 0, reset is initially asserted high. After 8 cycles, bit 3 becomes 1. This deasserts reset and allows the rest of the system to operate normally.

Additionally, in simulation, we can pass an entire array like display [7:0] as a single port, but yosys does not know how to turn this into real hardware. Therefore, we have to split it into 8 individual ports.

