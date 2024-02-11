#!/bin/bash

# Fix corrupt image URLs
for file in $(find ./site -name "*.html"); do
	echo Patching $file
	# sed -i "s?https://p-hu.de/https:/pixelfed.de?https://p-hu.de/assets/external/pixelfed.de?g" $file
	sed -i "s?/https:/pixelfed.de/?/assets/external/pixelfed.de/?g" $file
done

