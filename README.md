# RC4 Cracking Circuit

This repository contains the design and implementation of an RC4 decryption and cracking circuit. This project is part of the CPEN 311 Digital Systems Design course at the University of British Columbia.

## Overview

In this project, we designed an RC4 decryption circuit, which is then extended to implement a brute-force RC4 cracking circuit. The primary goal is to gain experience in creating a design that utilizes multiple on-chip memories and finite state machines (FSMs).

## Project Structure

The project is divided into three main tasks:

1. **Task 1: Creating a Memory, Instantiating it, and Writing to it**
   - Create a RAM block using the Megafunction Wizard.
   - Fill the memory with sequential values and observe the contents using the In-System Memory Content Editor.

2. **Task 2: Building a Single Decryption Core**
   - Implement the RC4 decryption algorithm using a single decryption core.
   - Use a 24-bit secret key obtained from the board switches.
   - Decrypt a 32-byte encrypted message stored in ROM and store the result in RAM.
   - Verify the decryption using the In-System Memory Content Editor.

3. **Task 3: Cracking RC4**
   - Modify the design to implement a brute-force attack on RC4.
   - Cycle through all possible keys to find the correct decryption key.
   - Display the current key on the HEX displays and indicate the result using LEDs.


## Usage

### Task 1: Creating a Memory

1. Use the Megafunction Wizard to create a single-port RAM with 256 8-bit words.
2. Instantiate the memory in your design and fill it with values from 0 to 255.
3. Use the In-System Memory Content Editor to verify the memory contents.

### Task 2: Building a Single Decryption Core

1. Implement the RC4 KSA to shuffle the memory based on the secret key.
2. Implement the RC4 PRGA to decrypt the encrypted message stored in ROM.
3. Verify the decrypted message using the In-System Memory Content Editor.

### Task 3: Cracking RC4

1. Modify the design to perform a brute-force attack by cycling through all possible keys.
2. Display the current key on the HEX displays.
3. Indicate the result using LEDs: one for a successful decryption and another for an unsuccessful search.

### Running the Design

1. Compile the project using Quartus.
2. Program the FPGA with the generated bitstream.
3. Set the secret key using the slider switches.
4. Use the In-System Memory Content Editor to observe the decrypted message.

## Bonus Task: Multi-Core Cracking

Implement multiple decryption cores to search different portions of the keyspace simultaneously for faster cracking.

## Acknowledgments

This lab was originally written by Prof. Steve Wilton and adapted for the CPEN 311 course. Special thanks to the teaching assistants for their support and guidance.
