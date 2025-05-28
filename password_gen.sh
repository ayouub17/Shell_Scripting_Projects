#!/bin/bash

# Simple Password Generator
echo "Welcome to the simple password generator!"
sleep 2

echo -n "Please enter the length of the password: "
read PASS_LENGTH

# Generate 7 passwords for variety
echo "Generating passwords..."
sleep 1

for p in $(seq 1 7); do
    openssl rand -base64 48 | cut -c1-"$PASS_LENGTH"
done